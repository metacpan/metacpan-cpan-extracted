package Mirror::JSON::URI;

use 5.005;
use strict;
use URI          ();
use Params::Util qw{ _STRING _INSTANCE };
use LWP::Simple  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	unless ( _INSTANCE($self->uri, 'URI') ) {
		return undef;
	}
	return $self;
}

sub uri {
	$_[0]->{uri};
}

sub json {
	$_[0]->{json};
}

sub live {
	!! $_[0]->{live};
}

sub lag {
	$_[0]->{lag};
}





#####################################################################
# Main Methods

sub get {
	my $self   = shift;
	my $uri    = URI->new('mirror.json')->abs( $self->uri );
	my $before = Time::HiRes::time();
	my $json   = LWP::Simple::get($uri);
	unless ( $json and $json =~ /^---/ ) {
		# Site does not exist, or is broken
		return $self->{live} = 0;
	}
	$self->{lag}  = Time::HiRes::time() - $before;
	$self->{json} = Mirror::JSON->read_string( $json );
	return $self->{live} = 1;
}

1;
