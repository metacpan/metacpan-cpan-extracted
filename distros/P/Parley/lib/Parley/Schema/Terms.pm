package Parley::Schema::Terms;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use base 'DBIx::Class';
use DateTime::Format::Pg;

use Parley::Version;  our $VERSION = $Parley::VERSION;

__PACKAGE__->load_components('PK::Auto', 'Core');
__PACKAGE__->table('parley.terms');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'integer',
    },
    created => {
        data_type   => 'timestamp with time zone',
    },
    content => {
        data_type   => 'text',
    },
    change_summary => {
        data_type   => 'text',
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->resultset_class('Parley::ResultSet::Terms');


sub user_accepted_latest_terms {
    my ($record, $user) = @_;
    my $schema = $record->result_source()->schema();

    my $matches = $schema->resultset('TermsAgreed')->count(
        {
            terms_id    => $record->id(),
            person_id   => $user->id(),
        }
    );

    return $matches;
};

foreach my $datecol (qw/created/) {
    __PACKAGE__->inflate_column($datecol, {
        inflate => sub { DateTime::Format::Pg->parse_datetime(shift); },
        deflate => sub { DateTime::Format::Pg->format_datetime(shift); },
    });
}

1;
