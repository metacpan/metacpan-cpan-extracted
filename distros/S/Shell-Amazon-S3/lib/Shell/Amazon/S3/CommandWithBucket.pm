package Shell::Amazon::S3::CommandWithBucket;

use Moose;
extends 'Shell::Amazon::S3::Command';

override 'check_pre_condition', sub {
    my ( $self, $tokens ) = @_;
    unless ( $self->is_bucket_set ) {
        return ( 0, "[error] bucket isn't set" );
    }
    return ( 1, "" );
};

override 'validate_tokens', sub {
    my ( $self, $tokens ) = @_;
    if ( @{$tokens} != 0 ) {
        return ( 0, "error: this command doesn't need arguments" );
    }
    return ( 1, "" );
};

override 'parse_tokens', sub {
    my ( $self, $tokens ) = @_;
    return $tokens;
};

sub is_bucket_set {
    my $self = shift;
    if($self->get_bucket_name) {
        return 1;
    }
    0;
}

1;
