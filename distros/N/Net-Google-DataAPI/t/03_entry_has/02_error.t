use strict;
use warnings;
use Test::More;
use Test::Exception;

throws_ok {
    package MyaEntry;
    use Any::Moose;
    use Net::Google::DataAPI;

    entry_has 'foobar' => (
        is => 'rw',
        isa => 'Str',
    );
} qr{Net::Google::DataAPI::Role::Entry required to use entry_has};

done_testing;
