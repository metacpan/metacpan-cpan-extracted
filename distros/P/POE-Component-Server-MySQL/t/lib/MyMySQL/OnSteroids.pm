package MyMySQL::OnSteroids;

use MooseX::MethodAttributes::Role;

sub fortune : Regexp('qr{fortune}io') {
   my ($self) = @_;
   
	my $fortune = `fortune`;
	chomp($fortune);

   $self->send_results(['fortune'],[[$fortune]]);

}


sub hello_world : Regexp('qr{hello world}io') {
   my ($self) = @_;
   
	
   $self->send_results(['Hello'],[['World']]);

}


1;
