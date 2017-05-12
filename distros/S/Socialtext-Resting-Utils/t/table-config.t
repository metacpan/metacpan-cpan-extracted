#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 5;
use lib 'lib';

BEGIN {
    use_ok 'Socialtext::WikiObject::TableConfig';
    use_ok 'Socialtext::Resting::Mock';
}

my $rester = Socialtext::Resting::Mock->new;

sub new_wikiobject {
    Socialtext::WikiObject::TableConfig->new( rester => $rester, @_ );
}

Simple_table: {
    $rester->put_page('Foo', <<EOT);
| *Key* | *Value* |
| foo | bar |
| perl | python |
EOT

    my $wo = new_wikiobject(page => 'Foo');
    my $table = $wo->table;
    is ref($table), 'HASH';
    is $table->{foo}, 'bar';
    is $table->{perl}, 'python';
}

