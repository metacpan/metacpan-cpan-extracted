package Shell::Amazon::S3::Command::deleteall;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

has '+desc' => ( default => 'deleteall [prefix]');

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;

    my $response = $bucket->list_all
        or die $bucket->err . ": " . $bucket->errstr;
    my $result = '';
    foreach my $key ( @{ $response->{keys} } ) {
        my $key_name   = $key->{key};
        my $is_success = $bucket->delete_key($key_name);
        if ($is_success) {
            $result
                .= "--- deleted item '"
                . $self->get_bucket_name . "/"
                . $key_name
                . "' ---\n";
        }
        else {
            $result
                .= "--- could not delete item '"
                . $self->get_bucket_name . "/"
                . $key_name
                . "' ---\n";
            $result .= $bucket->errstr . '\n' if $bucket->err;
        }
    }
}

1;
