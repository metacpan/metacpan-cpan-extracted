package Net::STF::Bucket;
use strict;
use Class::Accessor::Lite
    new => 1,
    rw => [ qw(
        client
        name
    ) ]
;

sub delete {
    my ($self, $recursive) = @_;
    $self->client->delete_bucket( $self->name, $recursive );
}

sub get_object {
    my ($self, $key, $opts) = @_;

    $self->client->get_object( 
        join( "/", $self->name, $key ),
        $opts
    );
}

sub put_object {
    my ($self, $key, $content, $opts) = @_;

    $self->client->put_object( 
        join( "/", $self->name, $key ),
        $content,
        $opts
    );
}

sub delete_object {
    my ($self, $key, $opts) = @_;

    $self->client->delete_object( 
        join( "/", $self->name, $key ),
        $opts
    );
}

1;

__END__

=head1 NAME

Net::STF::Bucket - A STF Bucket

=head1 SYNOPSIS

    my $client = Net::STF::Client->new( ... );
    my $bucket = Net::STF::Bucket->new(
        client => $client,
        name   => "mybucket"
    );

    $object = $bucket->put_object( $object_name, $content, \%opts );
    $object = $bucket->get_object( $object_name, \%opts );
    $bool   = $bucket->delete_object( $object_name, \%opts );
    $bool   = $bucket->delete;

=head1 DESCRIPTION

Net::STF::Bucket allows you to work with a bucket object to manipulate objects.
Note that you DO NOT need to use this object if you are directly using the Net::STF::Client interface.

=cut