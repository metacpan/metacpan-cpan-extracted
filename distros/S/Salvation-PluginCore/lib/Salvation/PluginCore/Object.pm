package Salvation::PluginCore::Object;

use strict;
use warnings;

use Salvation::Method::Signatures;

method new() {

    return bless( {}, ( ref( $self ) || $self ) );
}

method lazy( Str name ) {

    return $self -> { $name } if exists $self -> { $name };

    my $builder = "build_${name}";

    return $self -> { $name } = $self -> $builder();
}

1;

__END__
