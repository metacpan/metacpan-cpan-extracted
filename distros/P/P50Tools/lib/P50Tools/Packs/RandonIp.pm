package P50Tools::Packs::RandonIp;

use common::sense;

{
    no strict "vars";
    $VERSION = '0.1';
}

#create random ip
sub new {
	my $ip = join (".", map int rand (256), 1..4);
	return $ip; 
}

1;

=head1 
For more information go to L<P50Tools>.
=cut
