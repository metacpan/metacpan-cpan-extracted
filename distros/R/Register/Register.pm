package Register;
require Exporter;

@ISA = qw (Exporter);
use vars qw($VERSION);

$Register::VERSION="0.0.2";

sub checkDef
{
   my ($type, $name, $value, $def)      = @_;

   if (!defined $value)
   {
      return ($def);
   }
   else
   {
      return ($value);
   }
}

sub checkReq
{
   my ($type, $name, $value)    = @_;

   if (! defined $value)
   {
      printf "ERROR:\n";
      printf "LOCATION: \<$type\>\n";
      printf "CAUSE: parameter \<$name\> required !!!\n";
      exit (1);
   } else {
      return ($value);
   }
}

use Register::System;
use Register::Generic;
1;
__END__

=head1 NAME 

Register - simple implementation of the Win32 registry in Unix

=head1 SYNOPSIS

	use Register;

=head1 DESCRIPTION

Register is simply the main package to run registry option you
can see :

	* Register::System

=head1 AUTHOR

	Vecchio Fabrizio <jacote@tiscalinet.in>

=head1 SEE ALSO

L<Register::System>,L<DBD::CSV>,L<DBI>

=cut
