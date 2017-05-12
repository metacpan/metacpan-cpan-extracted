#
#===============================================================================
#
#         FILE:  03-directi.t
#
#  DESCRIPTION:  DirectI test
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  17.07.2009 04:19:36 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3;                      # last test to print


my $m = 'POE::Component::Client::Whois::Smart::NetWhoisRaw';

use_ok( $m );

my $self = bless {
    params => {
	omit_msg => 2,
	referral => 0,
    },
    result => [],
}, $m;

my $response = {
    original_query  => 'reg.ru',
    whois	    => 'arbitrary whois text',
    host	    => 'whois.ripn.net',
    query_real	    => 'domain reg.ru',
    query	    => 'reg.ru',
};

$self->process_query(
    $response,
);

my $result = {
    query	=> 'reg.ru',
    server	=> 'whois.ripn.net',
    query_real	=> 'domain reg.ru',
    whois	=> 'arbitrary whois text'."\n",
    error	=> undef,
};

is_deeply( $self->{result}, [
	$result
    ],
    '->process_query');

$response->{host	} = 'whois.reg.ru';
$response->{query_real  } = 'secret reg.ru';

$self->process_query(
    $response,
);

is_deeply( $self->{result}, [
	{ %$result },
	{ %$result, server => 'whois.reg.ru', query_real => 'secret reg.ru' },
    ],
    '->process_query x 2');

