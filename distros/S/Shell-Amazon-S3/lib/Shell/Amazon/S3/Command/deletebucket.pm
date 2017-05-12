package Shell::Amazon::S3::Command::deletebucket;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;

    $bucket->delete_bucket;
    my $result = '';
    if ( $bucket->err ) {
        $result .= "--- could not delete bucket '"
            . $self->get_bucket_name + "' ---\n";
        $result .= $bucket->err . ": " . $bucket->errstr . "\n";
    }
    else {
        $result .= "--- deleted bucket '" . $self->get_bucket_name . "' ---";
        $self->set_bucket_name(undef);
    }
    $result;
}

1;
