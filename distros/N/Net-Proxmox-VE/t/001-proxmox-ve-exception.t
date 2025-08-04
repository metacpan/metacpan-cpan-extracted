#!/usr/bin/perl
use strict;
use warnings;
use Test::More import =>
  [qw( done_testing is isa_ok like ok require_ok subtest )];
use Test::Exception;

require_ok('Net::Proxmox::VE::Exception')
  or die "# Net::Proxmox::VE::Exception not available\n";

my $file = $0;

# Test object creation
subtest 'Object creation' => sub {
    my $exception = Net::Proxmox::VE::Exception->_new(
        message => 'Test error',
        file    => 'test.pl',
        line    => 42
    );

    isa_ok( $exception, 'Net::Proxmox::VE::Exception',
        'Object is of correct class' );
    is( $exception->message, 'Test error', 'Message is set correctly' );
    is( $exception->file,    'test.pl',    'File is set correctly' );
    is( $exception->line,    42,           'Line is set correctly' );
};

# Test as_string method
subtest 'as_string method' => sub {
    my $exception = Net::Proxmox::VE::Exception->_new(
        message => 'Test error',
        file    => 'test.pl',
        line    => 42
    );

    is(
        $exception->as_string,
        'Test error at test.pl line 42.',
        'as_string formats correctly'
    );
};

# Test accessor methods
subtest 'Accessor methods' => sub {
    my $exception = Net::Proxmox::VE::Exception->_new(
        message => 'Test error',
        file    => 'test.pl',
        line    => 42
    );

    is( $exception->message, 'Test error', 'message accessor' );
    is( $exception->file,    'test.pl',    'file accessor' );
    is( $exception->line,    42,           'line accessor' );
};

# Test throw method with string argument
subtest 'Throw with string argument' => sub {
    dies_ok {
        Net::Proxmox::VE::Exception->throw('Test error')
    }
    'Throws exception with string argument';

    my $exception;
    throws_ok(
        sub {
            Net::Proxmox::VE::Exception->throw('Test error');
        },
        'Net::Proxmox::VE::Exception',
        'Thrown object is correct class'
    );
    $exception = $@;

    is( $exception->message, 'Test error', 'Message is set correctly' );
    like( $exception->file, qr/\.t$/, 'File is set from caller' );
    ok( $exception->line > 0, 'Line number is set' );
};

# Test throw method with hashref argument
subtest 'Throw with hashref argument' => sub {
    dies_ok {
        Net::Proxmox::VE::Exception->throw(
            {
                message => 'Test error',
            }
        )
    }
    'Throws exception with hashref argument';

    my $exception;
    throws_ok(
        sub {
            Net::Proxmox::VE::Exception->throw(
                {
                    message => 'Test error',
                }
            );
        },
        'Net::Proxmox::VE::Exception',
        'Thrown object is correct class'
    );
    $exception = $@;

    is( $exception->message, 'Test error', 'Message is set correctly' );
    is( $exception->file,    $file,        'File is set correctly' );
    is( $exception->line,    92,           'Line is set correctly' );
};

done_testing();
