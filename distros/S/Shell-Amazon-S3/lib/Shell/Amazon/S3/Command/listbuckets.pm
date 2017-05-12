package Shell::Amazon::S3::Command::listbuckets;
use Moose;

extends 'Shell::Amazon::S3::Command';

has '+desc' => ( default => 'listbuckets' );

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;

    # TODO
    if ( @{$tokens} != 0 ) {
        return ( 0, "error: This command doesn't need arguments" );
    }
    return ( 1, "" );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    return $tokens;
};

sub execute {
    my ( $self, $args ) = @_;
    my $response = $self->api->buckets;
    my $result   = '';
    foreach my $bucket ( @{ $response->{buckets} } ) {
        $result .= $bucket->bucket . "\n";
    }
    return $result;
}

1;
