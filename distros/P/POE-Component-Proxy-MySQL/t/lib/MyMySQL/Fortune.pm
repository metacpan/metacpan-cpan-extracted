package MyMySQL::Fortune;

use POE;
use MooseX::MethodAttributes::Role;

sub fortune : Regexp('qr{fortune}io') {
   my ($self) = $_[OBJECT];
   
   my $fortune = `fortune`;
   chomp($fortune);
   
   $self->client_send_results(
      ['fortune'],
      [[$fortune]]
   );

}



1;
