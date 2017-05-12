package Salvation::PluginCore;

use strict;
use warnings;

use base 'Salvation::PluginCore::Object';

use Module::Load 'load';
use Scalar::Util 'weaken';
use Salvation::TC ();
use String::CamelCase 'camelize';
use Salvation::Method::Signatures;

our $VERSION = 0.01;


method load_plugin( Str{1,} :infix!, Str{1,} :base_name! ) {

    $base_name = camelize( $base_name );

    foreach my $class ( @{ $self -> linearized_isa() } ) {

        my $base_class = "${class}::${infix}";
        my $plugin = "${base_class}::${base_name}";

        my $base_name = "${infix}::${base_name}";

        if( eval{ load $plugin; 1 } ) {

            weaken( my $weak = $self );

            $plugin = $plugin -> new( core => $weak, base_name => $base_name );
            Salvation::TC -> assert( $plugin, $base_class );

            return $plugin;
        } warn $@;
    }

    return undef;
}

method linearized_isa() {

    return $self -> lazy( 'linearized_isa' );
}

method build_linearized_isa() {

    my @out = ();
    my %seen = ();
    my @stack = ( ( ref( $self ) || $self ) );

    while( defined( my $class = shift( @stack ) ) ) {

        next if $seen{ $class } ++;

        push( @out, $class );

        my $isa = "${class}::ISA";

        no strict 'refs';

        push( @stack, @{ *$isa } );
    }

    return \@out;
}

1;

__END__
