package Shell::Amazon::S3::Command::put;
use Moose;

extends 'Shell::Amazon::S3::CommandWithBucket';

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( !@{$tokens} == 2 ) {
        return ( 0, "put <id> <data>" );
    }
    return ( 1, '' );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    my $args = {};
    $args->{key}  = $tokens->[0];
    $args->{data} = $tokens->[1];
    $args;
};

sub execute {
    my ( $self, $args ) = @_;
    my $bucket = $self->bucket;
    my $key    = $args->{key};
    my $data   = $args->{data};
    my $status = $bucket->add_key( $key, $data );

    # TODO
    my $result = '';
    $result .= "Uploaded: $key\n";
}

1;
