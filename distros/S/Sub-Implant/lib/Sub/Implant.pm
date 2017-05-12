package Sub::Implant;

use 5.010;
use strict;
use warnings;

=head1 NAME

Sub::Implant - Make a named sub out of a subref

=head1 VERSION

Version 2.02

=cut (remainder of POD after __END__)

our $VERSION = '2.02';

use Carp;

sub import {
    my $class = shift;
    $class->_import_into(scalar caller, @_);
}

sub _import_into {
    my $class = shift;
    my ($client, @arg) = @_;
    unshift @arg, qw(implant) unless @arg; # default export
    my %export = (
        implant => \ &implant,
        infuse  => \ &infuse,
    );

    while ( @arg ) {
        my $export = shift @arg;
        my $code = $export{$export} or croak(
            "$export is not exported by the $class module"
        );
        my %opt  = %{ shift @arg } if ref $arg[0] eq 'HASH';
        my $name = $opt{as} // $export;
        implant($client, $name, $code);
    }
}

sub infuse {
    my ($package, $what, %opt) = @_;
    for my $name ( keys %$what ) {
        my $code = $what->{$name};
        implant($package, $name, $code, %opt)
    }
}

sub implant {
    my ($name, $sub, %opt) = _get_args(scalar caller, @_);
    _do_define($name, $sub, %opt);
    _do_name($name, $sub, %opt) if $opt{name};
    $sub
}

use Scalar::Util qw(reftype);

sub _get_args {
    # pick up caller
    my $caller = shift;

    # unwrap original arguments
    croak "Name and subref must be given" if @_ < 2;
    $_ //= '' for @_;
    
    if ( (reftype $_[1] // '') eq 'CODE' ) {
        unshift @_, ''; # dummy package
    } elsif ( (reftype $_[2] // '') ne 'CODE' ) {
        croak "No subref given";
    }
    my ($package, $name, $sub, %opt) = @_;
    $opt{redef} //= 0;
    $opt{name} //= 1;

    # build full name
    if ( $name =~ /::/ ) {
        croak "Can't specify package and qualified name" if $package;
    } else {
        $package ||= $caller;
        $name = join '::', $package, $name;
    }

# all checked and set
    ($name, $sub, %opt)
}

sub _do_define {
    my ($name, $sub, %opt) = @_;
    if ( defined &$name ) {
        carp "Subroutine $name redefined" unless $opt{redef};
    }
    no warnings 'redefine';
    no strict 'refs';
    *$name = $sub;
}

sub _do_name_off {
    my ($name, $sub, %opt) = @_;
    my $old_name = _get_subname($sub);
    return if $old_name;
    _check_match($name, $sub, $old_name) unless $opt{lie}; # option 'lie' unused
    _subname($name, $sub);
    return;
}

use Sub::Identify qw(sub_name);
use Sub::Name qw(subname);

sub _do_name {
    my ($name, $sub, %opt) = @_;
    my $old_name = sub_name($sub);
    return if $old_name ne '__ANON__';
    _check_match($name, $sub, $old_name) unless $opt{lie}; # option 'lie' unused
    subname($name, $sub);
    return;
}

sub _check_match {
    # see if a name points to a given subref
    my ($name, $sub, $old_name) = @_;
    my $reached = do {
        no strict 'refs';
        *$name{CODE}
    };
    croak(
        "Won't rename $old_name to undefined $name'"
    ) unless $reached;
    croak(
        "Won't rename $old_name to non-matching $name"
    ) unless $reached == $sub;
}

1 # End of Sub::Implant
__END__

=head1 SYNOPSIS

    use Sub::Implant;

    sub original { (caller 0)[3] }
    say original(); # 'main::original'
    implant 'Some::Package', 'implanted', \ &original;
    say Some::Package::implanted(); # still 'main::original';

    my $anon_orig = sub { (caller 0)[3] };
    say $anon_orig->(); # 'main::__ANON__';
    implant 'Some::Package::also_implanted', $anon_orig;
    say Some::Package::also_implanted(); # now 'Some::Package::also_implanted'

=head1 EXPORT

The function C<implant> is exported by default.  It can be imported under
a different name by specifying

    use Sub::Implant implant => {as => 'other_name'};

=head1 SUBROUTINES

C<Sub::Implant> puts the mechanics of inserting a subref in a symbol table
and the action of assigning its internal name together under the convenient
interface of C<implant(...)>.  See also L</ACKNOWLEDGEMENTS> below.

C<infuse(...)> does the same, but for many functions at once.

=over

=item C<implant $qualified_name, $subref, %opt>

Makes the subroutine $subref available under the name $qualified_name.
If $qualified_name doesn't contain a C<::> (that is, it isn't really
qualified), it will be qualified with the name of the calling package.

=item C<implant $package, $name, $subref, %opt>

Makes the subroutine $subref available under the name C<"${package}::$name">.
In this form $name can't also be qualified, it is a fatal error if it
contains C<'::'>

=item C<infuse $package, {$name => $subref, ...}, %opt>

Calls C<implant $package, $name, $subref, %opt> for all
name/subref pairs in the hashref. Accordingly the subrefs are per
default installed into $package, but a full qualified $name overrides
that.

=back

If $subref is anonymous, C<implant> will set its internal name (the one
seen by C<caller>) to the new name.  If $subref already has a name
(originally or by an earlier call to C<implant>) that name will remain
unchanged.

If the target of C<implant> is already defined, it emits a warning when
it is overwritten.  Specifying C<< redef => 1 >> in C<%opt> suppresses the
warning.

If an implanted subref should remain anonymous for some reason, you
can switch off the naming mechanism with C<< name => 0 >> in %opt.

=head1 EXAMPLE

C<Sub::Implant> is its own first customer in that it uses C<implant> to
export itself to client modules. Here is how:

    # Basing ->import on ->import_into has nothing to do with
    # Sub::Implant, it's considered good style by some, yours
    # truly included

    sub import {
        my $class = shift;
        $class->_import_into(scalar caller, @_);
    }

    sub _import_into {
        my $class = shift;
        my ($client, @arg) = @_;
        unshift @arg, qw(implant) unless @arg; # default export
        my %export = (                         # provided exports
            implant => \ &implant,
            infuse  => \ &infuse,
        );

        while ( @arg ) {
            my $export = shift @arg;
            my $code = $export{$export} or croak(
                "$export is not exported by the $class module"
            );
            # accept export options if given
            my %opt  = %{ shift @arg } if ref $arg[0] eq 'HASH';
            # we only understand the 'as' option
            my $name = $opt{as} // $export;
            implant($client, $name, $code);
        }
    }

=head1 AUTHOR

Anno Siegel, C<< <anno5 at mac.com> >>

=head1 BUGS

There is no way to remove an implanted sub from a package.

If you find bugs or have feature requests, please report them to
C<bug-sub-implant at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Implant>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Implant

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Implant>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Implant>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-Implant>

=item * Search CPAN

L<http://search.cpan.org/dist/Sub-Implant/>

=back

=head1 ACKNOWLEDGEMENTS

I have to thank Matthijs van Duin for the C<Sub::Name> module.  Without
his prior work the setting of the internal name by C<implant> wouldn't
exist.  C<Sub::Implant> comes with a slightly modified version of C<Sub::Name>
of its own, so C<Sub::Name> doesn't appear among the prerequisites of C<Sub::Implant>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Anno Siegel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
