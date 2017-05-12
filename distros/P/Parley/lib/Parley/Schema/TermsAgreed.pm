package Parley::Schema::TermsAgreed;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class';

__PACKAGE__->load_components('PK::Auto', 'Core');
__PACKAGE__->table('parley.terms_agreed');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'integer',
    },
    person_id => {
        data_type   => 'integer',
    },
    terms_id => {
        data_type   => 'integer',
    },
    accepted_on => {
        data_type   => 'timestamp with time zone',
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'person' => 'Person',
    { 'foreign.id' => 'self.person_id' }
);
__PACKAGE__->belongs_to(
    'terms' => 'Terms',
    { 'foreign.id' => 'self.terms_id' }
);

1;
