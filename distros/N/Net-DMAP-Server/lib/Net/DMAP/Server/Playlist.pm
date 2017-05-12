package Net::DMAP::Server::Playlist;
use strict;
use base qw( Class::Accessor );
__PACKAGE__->mk_accessors(qw( dmap_itemid dmap_itemname dmap_persistentid items ));

sub new {
    my $self = shift;
    $self->SUPER::new({
        items => [],
    });
}

1;
