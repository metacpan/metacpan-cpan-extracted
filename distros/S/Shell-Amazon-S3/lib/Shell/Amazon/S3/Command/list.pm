package Shell::Amazon::S3::Command::list;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;

    my $response = $bucket->list_all
        or die $bucket->err . ": " . $bucket->errstr;
    my $result = '';
    foreach my $key ( @{ $response->{keys} } ) {
        my $key_name  = $key->{key};
        my $key_size  = $key->{size};
        my $key_owner = $key->{owner};
        $result .= "key='$key_name', size=$key_size\n";
    }
    $result;
}

1;
