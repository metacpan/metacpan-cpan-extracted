package Mirror::YAML::URI;

use 5.005;
use strict;
use URI          ();
use Params::Util qw{ _STRING _INSTANCE };
use LWP::Simple  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
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

sub yaml {
	$_[0]->{yaml};
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
	my $uri    = URI->new('mirror.yml')->abs( $self->uri );
	my $before = Time::HiRes::time();
	my $yaml   = LWP::Simple::get($uri);
	unless ( $yaml and $yaml =~ /^---/ ) {
		# Site does not exist, or is broken
		return $self->{live} = 0;
	}
	$self->{lag}  = Time::HiRes::time() - $before;
	$self->{yaml} = Mirror::YAML->read_string( $yaml );
	return $self->{live} = 1;
}

1;
