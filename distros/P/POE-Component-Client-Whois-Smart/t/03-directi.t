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

use Test::More tests => 2;                      # last test to print


my $m = 'POE::Component::Client::Whois::Smart::DirectI';

use_ok( $m );

my $self = bless {}, $m;

$self->_response(
    {
	domains => [ 'reg.com' ],
	data => {
	    'reg.com' => {
		status => 'regthroughothers',
	    },
	},
    },
);

is_deeply( $self->{result}, {
	'directi:reg.com' => [
	    {
		query => 'reg.com',
		whois => 'regthroughothers',
		server => 'directi',
		error => undef,
	    }
	],
    },
    '->_response call');
