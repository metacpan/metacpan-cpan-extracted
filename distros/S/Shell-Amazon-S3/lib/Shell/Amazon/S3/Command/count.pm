package Shell::Amazon::S3::Command::count;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

has '+desc' => (default => 'count [prefix]', );

sub execute {
    my ( $self, $args ) = @_;
    my $bucket   = $self->bucket;
    my $response = $bucket->list_all;

    my $result = '';
    if ( $bucket->err ) {
        $result .= $bucket->errstr;
    }
    else {
        $result .= scalar( @{ $response->{keys} } );
    }
};

1;
