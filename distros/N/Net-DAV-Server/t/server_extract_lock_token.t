#!/usr/bin/perl

use Test::More tests => 15;
use Carp;

use strict;
use warnings;

use Net::DAV::Server ();

{
    package Mock::Request;

    sub new {
        my ($class, $if) = @_;
        return bless \$if;
    }
    sub header {
        my ($self) = @_;
        return $$self;
    }
}

my @tests = (
    {
        label => 'Empty header',
        input => '',
        expected => undef,
    },
    {
        label => 'No-tag: single token',
        input => '(<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210>)',
        expected => 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210',
    },
    {
        label => 'No-tag: multiple tokens in a single list',
        input => '(<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> <opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'No-tag: single tokens in multiple lists',
        input => '(<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210>) (<opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'No-tag: single tokens in multiple lists, ignoring ETags',
        input => '(<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> ["ETag 2"]) ([W/"ETag 1"] <opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'No-tag: single tokens in multiple lists, ignoring Not',
        input => '(Not <opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> ["ETag 2"]) ([W/"ETag 1"] <opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'No-tag: multiple tokens in multiple lists',
        input =>
            '(<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> <opaquelocktoken:87654321-dead-beef-0bad-0123456789ab>)
             (<opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc> <opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210',
                      'opaquelocktoken:87654321-dead-beef-0bad-0123456789ab',
                      'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc',
                      'opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc',
                    ],
    },
    {
        label => 'Tagged: single token',
        input => '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210>)',
        expected => 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210',
    },
    {
        label => 'Tagged: multiple tokens in a single list',
        input => '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> <opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'Tagged: single tokens in multiple lists',
        input => '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210>) (<opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'Tagged: single tokens in multiple lists, ignoring ETags',
        input => '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> ["ETag 2"]) ([W/"ETag 1"] <opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'Tagged: single tokens in multiple lists, ignoring Not',
        input => '</resource> (Not <opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> ["ETag 2"]) ([W/"ETag 1"] <opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210', 'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc' ],
    },
    {
        label => 'Tagged: multiple tokens in multiple lists',
        input =>
            '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> <opaquelocktoken:87654321-dead-beef-0bad-0123456789ab>)
             (<opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc> <opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210',
                      'opaquelocktoken:87654321-dead-beef-0bad-0123456789ab',
                      'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc',
                      'opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc',
                    ],
    },
    {
        label => 'Tagged: multiple tokens resource lists',
        input =>
            '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210> <opaquelocktoken:87654321-dead-beef-0bad-0123456789ab>)
             </resource2> (<opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc> <opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210',
                      'opaquelocktoken:87654321-dead-beef-0bad-0123456789ab',
                      'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc',
                      'opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc',
                    ],
    },
    {
        label => 'Tagged: single tokens resource lists',
        input =>
            '</resource> (<opaquelocktoken:12345678-dead-beef-0bad-ba9876543210>)
             </res1> (<opaquelocktoken:87654321-dead-beef-0bad-0123456789ab>)
             </resource2> (<opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc>)
             </file> (<opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc>)',
        expected => [ 'opaquelocktoken:12345678-dead-beef-0bad-ba9876543210',
                      'opaquelocktoken:87654321-dead-beef-0bad-0123456789ab',
                      'opaquelocktoken:abcdef01-beef-bad0-dead-123456789abc',
                      'opaquelocktoken:abcdef01-feeb-0dab-daed-123456789abc',
                    ],
    },
);

foreach my $t ( @tests ) {
    my $token = Net::DAV::Server::_extract_lock_token( Mock::Request->new( $t->{'input'} ) );
    is_deeply( $token, $t->{'expected'}, $t->{'label'} );
}
