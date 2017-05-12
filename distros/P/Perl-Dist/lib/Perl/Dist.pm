package Perl::Dist;

use 5.006;
use strict;
use Perl::Dist::Inno ();

use vars qw{$VERSION @ISA};
BEGIN {
        $VERSION = '1.16';
	@ISA     = 'Perl::Dist::Inno';
}

1;

=pod

=head1 NAME

Perl::Dist - Perl Distribution Creation Toolkit

=head1 DESCRIPTION

The Perl::Dist namespace encompasses creation of pre-packaged, binary
distributions of Perl, primarily as executable installers for Win32.

Packages in this namespace include both "builders" and "distributions".

Builder packages automate the generation of distributions.

Distribution packages contain configuration files for a particular builder,
extra files to be bundled with the pre-packaged binary, and documentation.

Distribution namespaces are also recommended to consolidate bug reporting
using http://rt.cpan.org/.

I<Distribution packages should not contain the pre-packaged install files
themselves.>

=head2 BUILDERS

At the present time the primarily builder module is L<Perl::Dist::Inno>.

=head2 DISTRIBUTIONS

Currently available distributions include:

=over

=item *

L<Perl::Dist::Vanilla> -- An experimental "core Perl" distribution intended
for distribution developers.

=item *

L<Perl::Dist::Strawberry> -- A practical Win32 Perl release for
experienced Perl developers familiar with Perl on Unix environments
with full CPAN capabilities.

Strawberry Perl is considered stable, and can be downloaded from the
Strawberry Perl website at L<http://strawberryperl.com/>.

=item *

L<Perl::Dist::Chocolate> -- A concept distribution that bundled a large
"standard library" collection of CPAN modules, and provides a variety of
WxWindows-based GUI tools.

=item *

L<Perl::Dist::Bootstrap> -- Bootstrap Perl is a Perl 5.8.8 distribution
designed for people that are themselves creating Perl distributions.

It installs to a disk location out of the way and not used by any "end-user"
distributions, and comes with Perl::Dist and support modules pre-bundled.

=back

=head1 ROADMAP

L<Perl::Dist::Inno>, based on Inno Setup, is working well, but has a
limited lifespace, as it is not capable of produces Windows native
.msi installer files.

Ultimately this means that Perl::Dist will see the additional of an
alternative module based on Nullsoft or Wix that allows the creation
of .msi files (a major feature for corporate users).

Various other features are able to be implemented within the Inno Setup
feature set, and include:

=over

=item *

Bug-squashing Win32 compatibility problems in popular modules

=item *

Customisable installation path.

=item *

Support installation paths with spaces and other weird characters.

=item *

Restore support for .exe installation instead of .zip.

=item *

Better uninstall support and upgradability.

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

=head1 AUTHORS

Adam Kennedy <adamk@cpan.org>

David A. Golden <dagolden@cpan.org>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

Copyright 2006 David A. Golden.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Vanilla>,
L<Perl::Dist::Strawberry>, L<http://win32.perl.org/>,
L<http://vanillaperl.com/>, L<irc://irc.perl.org/#win32>,
L<http://ali.as/>, L<http://dagolden.com/>

=cut
