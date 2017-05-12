package P50Tools::RandonDoors;

use common::sense;
use IO::Socket::INET;
use Moose;

{
    no strict "vars";
    $VERSION = '0.2';
}

has 'target' => (is => 'rw', isa => 'Str');
has 'ini' => (is => 'rw', isa => 'Str', default => 1);
has 'end' => (is => 'rw', isa => 'Str', default => 65000);
has 'timeout' => (is => 'rw', isa => 'Str', default => 20);


sub scan{
	my $self = shift;
	my $target = $self->target;
	my $p1 = $self->ini;
	my $p2 = $self->end;
	
	my $out;
	for ($p1..$p2){
		
		my $t = $target . ":" . $_;
		my $sock = IO::Socket::INET->new(PeerAddr => $target,
										PeerPort => $_,
										Proto    => 'tcp',
										Timeout => $self->timeout,);
		if ($sock){
			$out .= $_ . ' ';
			print $_, " open\n";
		}
		else{
			print $_, " close\n";
		}
	}
	#print $_ foreach (@self);
	return $out;
}

no Moose;

1;
	
__END__
=head1 
For more information go to L<P50Tools>.
=cut
