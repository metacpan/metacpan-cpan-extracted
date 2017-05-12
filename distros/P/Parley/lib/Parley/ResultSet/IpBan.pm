package Parley::ResultSet::IpBan;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::ResultSet';

use Net::IP::Match::Regexp qw( create_iprange_regexp match_ip );

sub is_X_banned {
    my $resultsource = shift;
    my $ban_type     = shift;
    my $ip_address   = shift;
    my ($rs);

    # get the record for $ban_type ip bans
    $rs = $resultsource->search(
        {
            'ban_type.name' => $ban_type
        },
        {
            'join' => [qw/ban_type/],
        },
    );

    # no record? no bans
    return 0 # not banned
        if (0 == $rs->count);

    # we're only expecting one row, but this way we won't be bitten on the ass
    # if we change our mind in the future
    while (my $record = $rs->next) {
        # build the regexp to check against
        my $regexp = create_iprange_regexp(
            split(m{\s+}, $record->ip_range) # we pass an array of
                                             # "stuff" to the function
        );

        # see if it's banned
        if (match_ip($ip_address, $regexp)) {
            # ip in one of the banned ranges
            return 1;
        }
    }

    # if we don't know any better give the benefit of the doubt
    return 0; # not banned
}

sub is_access_banned {
    my $resultsource = shift;
    my $ip_address   = shift;

    return $resultsource->is_X_banned('access', $ip_address);
}

sub is_login_banned {
    my $resultsource = shift;
    my $ip_address   = shift;

    return $resultsource->is_X_banned('login', $ip_address);
}

sub is_posting_banned {
    my $resultsource = shift;
    my $ip_address   = shift;

    return $resultsource->is_X_banned('posting', $ip_address);
}

sub is_signup_banned {
    my $resultsource = shift;
    my $ip_address   = shift;

    return $resultsource->is_X_banned('signup', $ip_address);
}

1;
