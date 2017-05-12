package Net::STF::Object;
use strict;
use URI;
use Class::Accessor::Lite
    new => 1,
    rw => [ qw(
        url
        content
    ) ]
;

sub bucket_name {
    my $self = shift;
    if (URI->new($self->url)->path =~ m{^/([^/]+)}) {
        return $1;
    }
    return ();
}

sub key {
    my $self = shift;
    if (URI->new($self->url)->path =~ m{^/[^/]+/(.*)$}) {
        return $1;
    }
    return ();
}

1;

__END__

=head1 NAME

Net::STF::Object - A STF Object

=head1 SYNOPSIS

    my $object = $client->get_object( ... );
    $object->bucket_name;
    $object->key;

=cut