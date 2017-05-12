package Silki::Schema::UserImage;
{
  $Silki::Schema::UserImage::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Types qw( Str );

use Fey::ORM::Table;

with 'Silki::Role::Schema::URIMaker';

my $Schema = Silki::Schema->Schema();

has_policy 'Silki::Schema::Policy';

has_table( $Schema->table('UserImage') );

has_one( $Schema->table('User') );

has filename => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_filename',
);

with 'Silki::Role::Schema::File';

sub _base_uri_path {
    my $self = shift;

    return '/user_image/' . $self->user_id();
}

{
    my %ext = (
        'image/gif'  => '.gif',
        'image/jpeg' => '.jpg',
        'image/png'  => '.png',
    );

    sub _build_filename {
        my $self = shift;

        return 'user-image-' . $self->user_id() . $ext{ $self->mime_type() };
    }
}

__PACKAGE__->meta()->make_immutable;

1;
