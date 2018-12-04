package My::Test;

use Exporter 'import';

sub name {
    my ( $map, $class, $desc ) = @_;

    my $re = join( '|', reverse sort { length $a <=> length $b } keys %$map );

    1 while( $desc =~ s/($re)(?!\()/"$1($map->{$1})"/ge );

    $map->{$class} = $desc;

    return "$class($desc)";
}

1;

