package Module::Install::AggressiveInclude;

use warnings;
use strict;
use Module::Find ();

use base 'Module::Install::Base';

=head1 NAME

Module::Install::AggressiveInclude - A more aggressive include

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

At times L<Module::Install>'s include() function may not be enough for you.
In that case L<Module::Install::AggressiveInclude> may be what you need.

Often for local development I tend to shy away from installing packages I may
be working on so when working with packages that have multiple local
dependencies I find my self writing this Makefile.PL code a lot:

    # use lib for my local libraries somewhere around here
    # ...
    
    build_requires 'Module::Find';
    require Module::Find;
    
    include 'FooPackage';
    include $_ foreach Module::Find::findallmod 'FooPackage::*';
    
    # so on and so forth

Why? You may ask when L<Module::Install> has a support for glob matching of
packages. Well, because for my (and maybe yours) it is not powerful enough
when it comes to deep includes.

For example say we have a lot of modules we want to include from the same
namespace:

    FooPackage
    FooPackage::Alpha
    FooPackage::Alpha::I
    FooPackage::Alpha::II
    FooPackage::Beta
    FooPackage::Beta::I
    FooPackage::Beta::II
    FooPackage::Gamma
    FooPackage::Gamma::I
    FooPackage::Gamma::II
    
If we use L<Module::Install>'s include function like this:

    include 'FooPackage::*';

Only these packages will get included:

    FooPackage::Alpha
    FooPackage::Beta
    FooPackage::Gamma
    # Not even plain ol' FooPackage is included

In my opinion this lacks some DWIM functionality.
So instead we do:

    include_aggressive 'FooPackage';

And we will get the base package as well as every class under it's namespace.

=head1 METHODS

=head2 include_aggressive PACKAGE

Aggressively include PACKAGE and all the modules/packages that fall under it

=cut

sub include_aggressive {
    my $self = shift;
    my $package = shift;
    
    my @r = (
        $self->include($package),
        $self->include_findallmod($package)
    );
    
    return @r;
}

sub _include_mf_method {
    my ($self, $method) = (shift, shift);
    return map { Module::Find->can($method)->($_) } @_;
}

=head2 include_findallmod

Ties L<Module::Find>::findallmod to L<Module::Install>::include.

=cut

sub include_findallmod {
    my $self = shift;
    return map {
        $self->include($_);
    } $self->_include_mf_method( 'findallmod', @_ );
}

=head2 include_findsubmod

Ties L<Module::Find>::findsubmod to L<Module::Install>::include.

=cut

sub include_findsubmod {
    my $self = shift;
    
    return map {
        $self->include($_)
    } $self->_include_mf_method( 'findsubmod', @_);
}

=head2 include_followsymlinks

Interface with L<Module::Find>::followsymlinks.

=cut

sub include_followsymlinks {
    my $self = shift;
    return Module::Find::followsymlinks();
}

=head2 include_ignoresymlinks

Interface with L<Module::Find>::ignoresymlinks.

=cut

sub include_ignoresymlinks {
    my $self = shift;
    return Module::Find::ignoresymlinks();
}

=head1 AUTHOR

Jason M Mills, C<< <jmmills at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-install-aggressiveinclude at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-AggressiveInclude>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Install::AggressiveInclude


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Install-AggressiveInclude>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Install-AggressiveInclude>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Install-AggressiveInclude>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Install-AggressiveInclude/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jason M Mills.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Module::Install::AggressiveInclude
