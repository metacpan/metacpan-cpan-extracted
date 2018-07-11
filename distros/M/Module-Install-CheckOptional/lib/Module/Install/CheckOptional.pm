package Module::Install::CheckOptional;

use strict;
use 5.005;

use Carp;
# For module install and version checks
use Module::AutoInstall;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base Module::AutoInstall );

$VERSION = sprintf "%d.%02d%02d", q/0.11.4/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub check_optional {
  my ($self, $module, $version, $message) = @_;

  # Tell Module::Install to include this, since we use it.
  $self->perl_version('5.005');
  $self->include('Module::AutoInstall', 0);

  croak "check_optional requires a dependency and version such as \"Carp => 1.03\""
    unless defined $module and defined $version;

	return if Module::AutoInstall::_version_cmp(
	  Module::AutoInstall::_load($module), $version ) >= 0;

	print<<EOF;
*************************************************************************** 
NOTE: The optional module $module (version $version) is not installed.
EOF

	print "\n$message" if defined $message;
}

1;

# ---------------------------------------------------------------------------

=head1 NAME

Module::Install::CheckOptional - A Module::Install extension that checks to see if an optional dependency is satisfied


=head1 SYNOPSIS

  In Makefile.PL:
    use inc::Module::Install;
    ...
    check_optional( Carp => 1.02,
      "This module will perform better error reporting with Carp installed.");


=head1 DESCRIPTION

This is a Module::Install extension that checks that a suitable version of a module is installed, printing a message if it is not.


=head1 METHODS

=over 4

=item check_optional( E<lt>MODULE NAMEE<gt> => E<lt>0|VERSIONE<gt>, [MESSAGE] )

Checks whether a module is installed or not and that it has the correct
version. Prints a note similar to the following if the module with a version
greater than or equal to the specified version cannot be found:

	*************************************************************************** 
	NOTE: The optional module Carp (version 1.03) is not installed. 

In addition, the optional MESSAGE argument will be appended to the notice.

=back




=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.

=head1 AUTHOR

David Coppit E<lt>david@coppit.orgE<gt>

=head1 SEE ALSO

L<Module::Install>

=cut
