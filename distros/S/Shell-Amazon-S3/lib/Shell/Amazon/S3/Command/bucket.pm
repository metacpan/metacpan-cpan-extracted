package Shell::Amazon::S3::Command::bucket;
use Moose;

extends 'Shell::Amazon::S3::Command';

has "+desc" => ( default => 'bucket [bucketname]', );

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;

    if ( @{$tokens} != 1 ) {
        return ( 0, "error: bucket [bucketname]" );
    }
    return ( 1, "" );
};

sub parse_tokens {
    my ( $self, $token ) = @_;
    my $args = {};
    $args->{bucket} = $token->[0];
    return $args;
}

sub execute {
    my ( $self, $args ) = @_;
    $self->set_bucket_name( $args->{bucket} );
    return "--- bucket set to '" . $self->get_bucket_name . "' ---";
}

1;
