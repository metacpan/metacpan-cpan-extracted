package Module::Replace;

use warnings;
use strict;

#use 5.010;

=head1 NAME

Module::Replace - Replace functionality in other modules

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Module::Replace 'Other::Module' => qw(new);

=head1 DESCRIPTION

The purpose of this module is to allow you to override functions in one
module with the same-named functions in another.

This can be a global change, or a temporary change.

The reasons why you may want to do this include:

=over 4

=item *

Changing the behaviour of code you don't own by changing what it calls.

For example, if you're using the popular Foo::Framework class, and you want
to change what object it retrieves when it calls Foo::Object->new, you can
simply replace Foo::Object::new with your own new which would then create
your object, presumably derived from Foo::Object.

=item *

Building a general framework that doesn't rely on the user specifying what
objects to create.  Here you merely tell the user to:

    use Module::Replace 'YourFramework::Type', qw(new);

in their derived package and this will allow your framework to stay
blissfully unaware of who is deriving from you in the current application.

Note that this doesn't help when you want multiple derivations from the
same type.  A real factory is still required at that point.

=back

=head1 USAGE

There are two types of usage: global and local replacement.

=over 4

=item Global replacement

This is primarily targetted at frameworks.  Here you call:

    use Module::Replace 'YourFramework::Type', qw(new);

from within the derived object.  This will both call C<use base 'YourFramework::Type'>
and override new with your own.  Note that access to the original new method
is still available via SUPER_new, e.g.:

    sub new {
        my $class = shift;
        # allow re-derivations
        $class = __PACKAGE__ if $class eq 'YourFramework::Type';
        my $self = bless $class->SUPER_new(), $class;
        # ...
    }

=item Local replacement

Sometimes you only want to replace a function for a little while.  For
example, changing the way that File::Spec::catdir works only when calling
another function.  Here you call the replace and restore functions directly.

    use Module::Replace;
    Module::Replace::replace('File::Spec', \'File::Spec::UNIX', qw(catdir));
    Some::Other::function();
    Module::Replace::restore('File::Spec', \'File::Spec::UNIX');

Note that if you leave off the reference to the source package, it will assume
the caller package.

This will cause catdir to work UNIX-like on all platforms for the duration
of C<Some::Other::function()>.

It is up to you to ensure that exceptions are handled so that the methods
are restored at the proper time.

=back

=head1 FUNCTIONS

=over 4

=cut

sub import
{
    my $self  = shift;
    my $class = shift;
    my ($caller) = caller(0);

    return 1 unless $class;

    # first, load the module, and make the caller derived from it.
    # 'base' does a lot of work - let's abuse that.
    eval qq[
        package $caller;
        use base '$class';
        ];
    die $@ if $@;
    replace($class, \$caller, @_) if @_;
    1;
}

=item replace

Input:

=over 4

=item 1

Package to replace.

=item 2

Reference to package that contains the wanted function (optional - defaults
to caller's package)

=item 3

List of functions to replace.  Each function will be renamed to SUPER_$func
so that the overridden function will work

=back

=cut

my %overrides;
sub replace
{
    my $class = shift;
    my ($caller) = ref $_[0] && ref $_[0] eq 'SCALAR' ? ${shift()} : caller(0);

    # now, replace desired methods.
    for my $func (@_)
    {
        no strict 'refs';
        no warnings;
        local ($^W) = 0; # in case "-w" is used
        *{"${class}::SUPER_$func"} = \&{"${class}::$func"} if ${"${class}::"}{$func};
        *{"${class}::$func"} = \&{"${caller}::$func"};
        # keep track of what was overridden for reversals.
        $overrides{$caller}{$class}{$func}++;
    }
}

=item restore

Input:

=over 4

=item 1

Package that is overridden

=item 2

Reference to package that contains the wanted function (optional - defaults
to caller's package)

=back

=cut

sub restore
{
    my $class = shift;
    my ($caller) = ref $_[0] && ref $_[0] eq 'SCALAR' ? ${shift()} : caller(0);

    for my $func (keys %{$overrides{$caller}{$class}})
    {
        no strict 'refs';
        no warnings;
        local ($^W) = 0; # in case "-w" is used
        if (exists ${"${class}::"}{"SUPER_$func"})
        {
            *{"${class}::$func"} = \&{"${class}::SUPER_$func"};
            delete ${"${class}::"}{"SUPER_$func"};
        }
        else
        {
            delete ${"${class}::"}{$func};
        }
    }
}

=back

=head1 AUTHOR

Darin McBride, C<< <dmcbride at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-replace at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Replace>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Replace


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Replace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Replace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Replace>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Replace>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Darin McBride, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Module::Replace
