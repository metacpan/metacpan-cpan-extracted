package Parley::ResultSet::Terms;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::ResultSet';

sub latest_terms {
    my $resultset = shift;

    my $latest_rs = $resultset->search(
        {
        },
        {
            rows        => 1,
            order_by    => [\'created DESC'],
        }
    );

    if ($latest_rs->count()) {
        return $latest_rs->first();
    }

    return;
}

1;
