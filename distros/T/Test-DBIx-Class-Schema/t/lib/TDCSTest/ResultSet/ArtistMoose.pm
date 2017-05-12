package # hide from PAUSE
    TDCSTest::ResultSet::ArtistMoose;

# From https://metacpan.org/pod/DBIx::Class::ResultSet#CUSTOM-ResultSet-CLASSES-THAT-USE-Moose
use Moose;
use namespace::autoclean;
use MooseX::NonMoose;
extends 'DBIx::Class::ResultSet';

sub BUILDARGS { $_[2] }

sub artists { shift }

__PACKAGE__->meta->make_immutable;

1;
