package Module::Lazy;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.04';

=head1 NAME

Module::Lazy - postpone loading a module until it's actually used

=head1 SYNOPSIS

    use Module::Lazy "My::Module";
    # My::Module has not been loaded

    my $var = My::Module->new;
    # My::Module is loaded now, and new() method is called

    no Module::Lazy;
    # Force loading of all postponed modules

=head1 DESCRIPTION

In large projects loading all the dependencies may take a lot of time.
This module attempts to reduce the startup time by postponing initialization.
The improvement be significant for unit test scripts
and small command-line tools
which do not utilize all the functionality at once.

This comes at a cost of reduced stability,
as load-time errors are also postponed.
The C<no Module::Lazy> directive is provided to mitigate the risk
by forcing the pending modules to load.

=head1 EXPORTED FUNCTIONS

None.

=head1 METHODS

=cut

use Carp;
use constant DEBUG => !!$ENV{PERL_LAZYLOAD_DEBUG};

=head2 import

When C<use Module::Lazy "Some::Module";> is called,
the module in question is not loaded.
A stub package with the same name is created instead.

Should any method call be performed on the stub package,
it loads the original one and jumps to respective method.

In particular, C<can()> and C<isa()> are overloaded
and will trigger module loading.

Upon loading, C<import> is not called on the target package.
This MAY change in the future.

No extra options (except from target module name) are allowed.

=cut

my $dont = !!$ENV{PERL_LAZYLOAD_DISABLE};
my %seen;
my $inc_stub = "pending load by ".__PACKAGE__;

sub import {
    my ($class, $target, @rest) = @_;

    # bare use statement is ok
    return unless defined $target;

    croak "Usage: use Module::Lazy 'Module::Name'; extra options not supported"
        unless @rest == 0;

    # return ASAP if already loaded by us or Perl itself
    return if $seen{$target};
    my $mod = $target;
    $mod =~ s,::,/,g;
    $mod .= ".pm";

    return if $INC{$mod};

    carp __PACKAGE__.": request to load $target "
        .($seen{$target} ? '(seen)' : '(first time)')
            if DEBUG;
    return _load( $target, $mod )
        if $dont;

    croak "Bad module name '$target'"
        unless $target =~ /^[A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_0-9]+)*$/;

    $seen{$target} = $mod;

    # If $target is later require'd directly,
    # autoload and destroy will be overwritten and will cause a warning.
    # Preventing them from being loaded seems like a lesser evil.
    $INC{$mod} = $inc_stub;

    _set_symbol( $target, AUTOLOAD => sub {
        our $AUTOLOAD;
        $AUTOLOAD =~ s/.*:://;
        my $jump = _jump( $target, $AUTOLOAD );
        goto $jump;
    } );

    # Provide DESTROY just in case someone blesses an object directly
    #     without ever loading a module
    _set_symbol( $target, DESTROY => _jump( $target, DESTROY => "no_die" ) );

    # If somebody calls Module->can("foo"), we can't really tell
    # without loading, so override it
    foreach (qw( can isa )) {
        _set_symbol( $target, $_ => _jump( $target, $_ ) );
    };

    # Provide a fake version for `use My::Module 100.500`
    _set_symbol( $target, VERSION => 10**9 );
};

=head2 unimport

Calling C<no Module::Lazy;> or, alternatively, C<Module::Lazy-E<gt>unimport;>
will cause all postponed modules to be loaded immediately,
in alphabetical order.

This may be useful to avoid deferred errors and/or side effects
of module loading.

No extra options to unimport are supported.

=cut

sub unimport {
    my $class = shift;

    croak "usage: no Module::Lazy;"
        if @_;

    carp __PACKAGE__.": unimport called"
        if DEBUG;

    $dont++;
    # sort keys to ensure load order stability in case of bugs
    foreach (sort keys %seen) {
        # some modules may have been already loaded, skip if so
        _inflate($_) if $seen{$_};
    };
};

my %cleanup_symbol;
sub _inflate {
    my $target = shift;

    # TODO distinguish between "not seen" and "already loaded"
    my $mod = delete $seen{$target};
    croak "Module '$target' is unknown Module::Lazy, or already loaded. Please file a bug"
        unless $mod;

    carp "Module '$target' wasn't preloaded by Module::Lazy. Please file a bug"
        unless $INC{$mod};

    return carp "Module '$target' already loaded elsewhere from '$INC{$mod}'"
        unless $INC{$mod} eq $inc_stub;

    # reset stub methods prior to loading
    foreach (keys %{ $cleanup_symbol{$target} || {} }) {
        _unset_symbol( $target, $_ );
    };

    # reset fake $VERSION
    _set_symbol( $target, VERSION => undef );

    # make the module loadable again
    delete $INC{$mod};
    _load( $target, $mod );
};

sub _load {
    my ($target, $mod) = @_;

    carp __PACKAGE__.": loading $target from $mod"
        if DEBUG;

    package
        Module::Lazy::_::quarantine;

    local $Carp::Internal{ __PACKAGE__ } = 1;
    require $mod;
    # TODO maybe $target->import()
};

sub _jump {
    my ($target, $todo, $nodie) = @_;

    return sub {
        _inflate( $target );

        my $jump = $target->can($todo);
        goto $jump
            if $jump; # TODO should also check it's a CODEREF

        croak qq{Can't locate object method "$todo" via package "$target"}
            unless $nodie;
    };
};

sub _set_symbol {
    my ($target, $name, $ref) = @_;

    if (ref $ref) {
        # really update symbol table
        $cleanup_symbol{$target}{$name}++;
        no strict 'refs'; ## no critic
        *{ $target."::".$name } = $ref;
    } else {
        # just set scalar
        no strict 'refs'; ## no critic
        ${ $target.'::'.$name } = $ref;
    };
};

sub _unset_symbol {
    my ($target, $name) = @_;

    no strict 'refs'; ## no critic
    # because package scalars are _special_,
    # move SCALAR ref around the destruction
    # just in case someone referenced it before module was loaded
    my $save = \${ $target."::".$name };
    delete ${ $target."::" }{ $name };
    *{ $target.'::'.$name } = $save;
};

=head1 ENVIRONMENT

If C<PERL_LAZYLOAD_DEBUG> is set and true,
warns about module loading via Carp.

If C<PERL_LAZYLOAD_DISABLE> is set and true,
don't try to lazyload anything - just go straight to C<require>.

(That's roughly equivalent to C<perl -M-Module::Lazy> on command line).

=head1 CAVEATS

=over

=item * The following symbols are currently replaced by stubs
in the module to be loaded: C<AUTOLOAD>, C<DESTROY>, C<can>, C<isa>.

=item * If a module was ever lazyloaded, a normal C<require> would do nothing.
A method must be called to inflate the module.

This is done so because a normal require would partially overwrite
stub methods and potentially wreak havoc.

=item * A fake $VERSION = 10**9 is generated so that C<use Module x.yy>
doesn't die. This value is erased before actually loading the module.

=back



=head1 BUGS

=over

=item * C<use mro 'c3';> does not work with lazy-loaded parent classes.

=item * C<import()> is not called on the modules being loaded.
The decision is yet to be made whether it's good or bad.

=item * no way to preload prototyped exported functions
(that's what L<autouse> does),
but maybe there should be?

=item * certainly not enough interoperability tests.

=back

Please report bugs via github or RT:

=over

=item * L<https://github.com/dallaylaen/module-lazy-perl/issues>

=item * C<bug-module-lazy at rt.cpan.org>

=item * L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Lazy>

=back

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc Module::Lazy

You can also look for information at:

=over 4

=item * github: L<https://github.com/dallaylaen/module-lazy-perl>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Lazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Lazy>

=item * Search CPAN

L<http://metacpan.org/pod/Module::Lazy/>

=back

=head1 SEE ALSO

L<autouse> is another module with similar idea, however,
it does it for imported functions rather than methods.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Konstantin S. Uvarin, C<< <khedin@cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Module::Lazy
