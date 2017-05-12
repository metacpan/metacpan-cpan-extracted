#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use POE::Test::Helpers;
my $class   = 'POE::Test::Helpers';
my $new     = sub { return POE::Test::Helpers->new(@_) };
my $new_run = sub { return $new->( run => sub {}, @_ )          };

throws_ok { $new->() }
    qr/^Missing tests data in new/, 'tests and run required';

throws_ok { $new->( tests => {} ) }
    qr/^Missing run method in new/, 'run required';

throws_ok { $new->( run => sub {1} ) }
    qr/^Missing tests data in new/, 'tests required';

throws_ok { $new->( run => {}, tests => {} ) }
    qr/^Run method should be a coderef in new/, 'run should be coderef';

throws_ok { $new->( tests => [] ) }
    qr/Tests data should be a hashref in new/, 'tests should be hashref';

# checking errors

# got non-digit count
throws_ok { $new_run->( tests => { a => { count => 'z' } } ) }
    qr/^Bad event count in new/, 'Non-digit count';
throws_ok { $new_run->( tests => { a => { count => ''  } } ) }
    qr/^Bad event count in new/, 'Empty count';

# got non-digit order
throws_ok { $new_run->( tests => { a => { order => 'z' } } ) }
    qr/^Bad event order in new/, 'Non-digit order';
throws_ok { $new_run->( tests => { a => { order => ''  } } ) }
    qr/^Bad event order in new/, 'Empty order';

# got non-arrayref params
throws_ok { $new_run->( tests => { a => { params => {} } } ) }
    qr/^Bad event params in new/, 'Odd params';
throws_ok { $new_run->( tests => { a => { params => '' } } ) }
    qr/^Bad event params in new/, 'Empty params';

# got non-arrayref deps
throws_ok { $new_run->( tests => { a => { deps => {} } } ) }
    qr/^Bad event deps in new/, 'Odd deps';
throws_ok { $new_run->( tests => { a => { deps => '' } } ) }
    qr/^Bad event deps in new/, 'Empty deps';

# typical syntax
isa_ok(
    $new_run->(
        tests => {
            '_start' => {
                count  => 0,
                params => [ 'hello', 'world' ],
            },
        },
    ),
    $class,
);

# explicitly no parameters, don't check count
isa_ok(
    $new_run->(
        tests => {
            'next' => {
                params => [],
            },
        },
    ),
    $class,
);

# don't check parameters
isa_ok(
    $new_run->(
        tests => {
            '_stop' => {
                count => 1,
            },
        },
    ),
    $class,
);

