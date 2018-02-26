package Mojolicious::Plugin::Vparam::Object;
use Mojo::Base -strict;

# Get hash of keys/values and return object
sub parse_object($) {
    my $hash = shift;
    return undef unless $hash;

    my $result = undef;
    for my $key ( keys %$hash ) {
        my $value = $hash->{$key};
        my @path  = $key =~ m{\[([^\[\]]*?)\]}g;

        my $pointer = \ $result;
        for my $i ( 0 .. $#path ) {
            if( $path[$i] =~ m{^\d+$}) {
                $pointer //= [];
                $pointer = \$$pointer->[ $path[$i] ];
            } else {
                $pointer //= {};
                $pointer = \$$pointer->{ $path[$i] };
            }
        }
        $$pointer = $value;
    }

    return $result;
}

sub check_object($) {
    return 'Wrong format'           unless defined $_[0];
    return 0;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        object      =>
            pre     => sub { parse_object       $_[1] },
            valid   => sub { check_object       $_[1] },
    );

    return;
}

1;
