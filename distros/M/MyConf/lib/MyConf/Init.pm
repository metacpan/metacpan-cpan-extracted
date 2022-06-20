package MyConf::Init;
use utf8;
use v5.30;
use warnings;
use Config::Tiny;

our $VERSION = 'v1.0.0';

sub init_from_file {
	if ( -e './conf/local.conf' ) {
		my $config = Config::Tiny->read('conf/local.conf');
		for ( keys %{ $config->{_} } ) {
			$ENV{ sprintf( "MP_%s", uc ) } = $config->{_}->{$_};
		}
	}
	return;
}

1;
