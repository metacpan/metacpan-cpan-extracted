package Module::Install::CustomInstallationPath;

use strict;
use 5.005;
use File::HomeDir;
use Config;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.10.48/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub check_custom_installation
{
  my $self = shift;

  $self->include_deps('File::HomeDir',0);

  return if (grep {/^PREFIX=/} @ARGV) || (grep {/^INSTALLDIRS=/} @ARGV);

  my $install_location = $self->prompt(
    "Would you like to install this package into a location other than the\n" .
    "default Perl location (i.e. change the PREFIX)?" => 'n');

  if ($install_location eq 'y')
  {
    my $home = home();

    die "Your home directory could not be determined. Aborting."
      unless defined $home;

    print "\n","-"x78,"\n\n";

    my $prefix = $self->prompt(
      "What PREFIX should I use?\n=>" => $home);

    push @ARGV,"PREFIX=$prefix";
  }
}

1;

# ---------------------------------------------------------------------------

=head1 NAME

Module::Install::CustomInstallationPath - A Module::Install extension that allows the user to interactively specify custom installation directories


=head1 SYNOPSIS

  In Makefile.PL:
    use inc::Module::Install;
    ...
    check_custom_installation();


=head1 DESCRIPTION

This is a Module::Install extension that helps users who do not have root
access to install modules. It first prompts the user for a normal installation
into the default Perl paths, or a custom installation. If the user selects a
custom installation, it prompts the user for the value for PREFIX. This value
is then used to add PREFIX=value to @ARGV.

If the user specifies PREFIX or INSTALLDIRS as arguments to Makefile.PL, then
the prompts are skipped and a normal installation is done.


=head1 COMPATIBILITY NOTE

Consider carefully whether you want to use this module. In my experience, many
people don't want an interactive installation. For example, CPAN users have
likely already thought about custom installation paths. Debian package
maintainers also want non-interactive installs.

=head1 METHODS

=over 4

=item check_custom_installation()

Imported into Makefile.PL by Module::Install when invoked. This causes the
prompts to be displayed and @ARGV to be updated (if necessary).

=back




=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.

=head1 AUTHOR

David Coppit E<lt>david@coppit.orgE<gt>

=head1 SEE ALSO

L<Module::Install>

=cut
