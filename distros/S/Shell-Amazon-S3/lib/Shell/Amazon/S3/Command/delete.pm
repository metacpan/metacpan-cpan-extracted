package Shell::Amazon::S3::Command::delete;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

has '+desc' => ( default => 'delete <id>' );

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( !@{$tokens} == 1 ) {
        return ( 0, "error: delete <id>" );

    }
    return ( 1, '' );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{key} = $tokens->[0];
    $args;
};

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;
    my $key    = $args->{key};

    my $is_success = $bucket->delete_key($key);
    my $result     = '';
    if ($is_success) {
        $result
            .= "--- deleted item '"
            . $self->get_bucket_name . "/"
            . $key
            . "' ---\n";
    }
    else {
        $result
            .= "--- could not delete item '"
            . $self->get_bucket_name . "/"
            . $key
            . "' --\n";
        $result .= $bucket->errstr . "\n" if $bucket->err;
    }

}

1;
