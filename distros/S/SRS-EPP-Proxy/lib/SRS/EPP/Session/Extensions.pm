# Keeps track of which extensions are enabled for a session

package SRS::EPP::Session::Extensions;
{
  $SRS::EPP::Session::Extensions::VERSION = '0.22';
}

use Moose;
use XML::EPP;

has 'enabled' =>
	is => "rw",
	isa => "HashRef",
	default => sub { {} },
	;

sub set {
	my $self = shift;
	my @extensions = @_;
	
	foreach my $ext_uri (@extensions) {
		my $alias = $XML::EPP::ext_with_aliases{$ext_uri};
		
		$self->enabled->{$alias} = 1;
	}
}

__PACKAGE__->meta->make_immutable;

1;