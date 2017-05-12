package Shell::Amazon::S3::Command::createbucket;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

has '+desc' => (default => 'createbucket');

sub execute {
    my ($self, $args) = @_;
    my $bucket_name = $self->get_bucket_name;
    my $bucket = $self->api->add_bucket( { bucket => $bucket_name } );
 
    my $result ='';
    if ( $self->api->err ) {
        $result .= "--- could not create bucket '" . $bucket_name + "' ---\n";
        $result .= $self->api->err . ": " . $self->api->errstr;
    }
    else {
        $result .= "--- created bucket '" . $bucket_name . "' ---\n";
    }
    $result;
}

1;
