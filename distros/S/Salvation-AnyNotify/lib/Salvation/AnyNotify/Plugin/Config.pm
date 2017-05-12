package Salvation::AnyNotify::Plugin::Config;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use YAML 'Load';
use File::Spec ();
use File::Slurp 'read_file';
use File::HomeDir ();
use Salvation::TC ();
use Salvation::Method::Signatures;

method get( Str{1,} key ) {

    my $cached_key = "cacheddata:${key}";

    return $self -> { $cached_key } if exists $self -> { $cached_key };

    my $data = $self -> data();

    foreach my $part ( split( /\./, $key ) ) {

        if( Salvation::TC -> is( $data, 'HashRef' ) && exists $data -> { $part } ) {

            $data = $data -> { $part };

        } else {

            return $self -> { $cached_key } = undef;
        }
    }

    return $self -> { $cached_key } = $data;
}

method data() {

    return $self -> lazy( 'data' );
}

method config_path() {

    return $self -> lazy( 'config_path' );
}

method build_data() {

    if( defined( my $path = $self -> config_path() ) ) {

        my $config = Load( scalar read_file( $path ) );

        Salvation::TC -> assert( $config, 'HashRef' );

        return $config;
    }

    return {};
}

sub build_config_path {

    if( defined( my $home = File::HomeDir -> my_home() ) ) {

        my $user_cfg = File::Spec -> catfile(
            $home,
            '.anynotify.yaml',
        );

        if( -e $user_cfg ) {

            return $user_cfg;
        }
    }

    my $global_cfg = File::Spec -> catfile(
        File::Spec -> rootdir(),
        'etc',
        'anynotify.yaml',
    );

    if( -e $global_cfg ) {

        return $global_cfg;
    }

    return undef;
}

1;

__END__
