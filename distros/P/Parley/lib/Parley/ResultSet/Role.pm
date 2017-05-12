package Parley::ResultSet::Role;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::ResultSet';

sub role_list {
    my $resultsource = shift;
    my ($rs);

    $rs = $resultsource->search(
        {
        },
        {
            'order_by' => [ \'idx ASC', \'description ASC' ],
        },
    );

    return $rs;
}

1;
