#!/usr/bin/perl
#
#   Unit tests for ::Output.pm
#
#   infi/2008
#
# FIXME: The redirection doesn't seem to jive on perl 5.6.2
#   http://www.nntp.perl.org/group/perl.cpan.testers/2008/04/msg1317361.html

use strict;
use warnings;

use Test::More tests => 12;
use Data::Dumper;

BEGIN {
    # Test #1
    use_ok( 'POE::Component::Client::opentick::Output' );
}

my ($stdout,$stderr,$obj);

###################################################
# open()ing to a scalar ref appeared in 5.8.x
# it doesn't affect the software, only these
# tests, so forget it.
###################################################
SKIP: {
    eval { require 5.008_000 };

    skip "Scalar references only available in >= 5.8.0", 8 if $@;

# Test #2: O_DEBUG
ok(
    do {
        eval{
            close(STDERR);
            open(STDERR, '>', \$stderr);
            POE::Component::Client::opentick::Output->set_debug( 1 );
            O_DEBUG( "Happy Birthday, Dad" );
            $stderr eq "OT:DEBUG: Happy Birthday, Dad\n";
        };
    },
    'O_DEBUG correctness'
);

# Test #3: O_INFO
ok(
    do {
        eval{
            close(STDOUT);
            open(STDOUT, '>', \$stdout);
            O_INFO( "I'm in jail!" );
            $stdout eq "OT:INFO: I'm in jail!\n";
        };
    },
    'O_INFO correctness'
);

# Test #4: Dubious results confirmation
ok(
    do {
        eval{
            close(STDOUT);
            open(STDOUT, '>', \$stdout);
            O_INFO( "I'm in jail!" );
            $stdout eq "And now for something completely different!";
        };
    } != 1,
    'O_INFO no dubious results',
);

# Test #5: O_NOTICE
ok(
    do {
        eval{
            close(STDOUT);
            open(STDOUT, '>', \$stdout);
            O_NOTICE( "It's nice, I like it" );
            $stdout eq "OT:NOTICE: It's nice, I like it\n";
        };
    },
    'O_NOTICE correctness'
);

# Test #6: O_WARN
ok(
    do {
        eval{
            close(STDERR);
            open(STDERR, '>', \$stderr);
            O_WARN( "Say hi to Mom!" );
            $stderr eq "OT:WARN: Say hi to Mom!\n";
        };
    },
    'O_WARN correctness'
);

# Test #7: O_ERROR
ok(
    do {
        eval{
            close(STDERR);
            open(STDERR, '>', \$stderr);
            O_ERROR( "Throw away the key!" );
            $stderr eq "OT:ERROR: Throw away the key!\n";
        };
    },
    'O_ERROR correctness'
);

# Test #8: set_prefix correctness
ok(
    do {
        eval{
            close(STDERR);
            open(STDERR, '>', \$stderr);
            POE::Component::Client::opentick::Output->set_prefix( 0 );
            O_WARN( "Say hi to Mom!" );
            $stderr eq "Say hi to Mom!\n"
        };
    },
    'get_quiet() workiness'
);

# Test #9: set_quiet correctness
ok(
    do {
        eval{
            close(STDERR);
            open(STDERR, '>', \$stderr);
            POE::Component::Client::opentick::Output->set_quiet( 1 );
            O_WARN( "I'm going to stay!" );
            $stderr eq ''
        };
    },
    'set_quiet() workiness'
);

########################
} # END OF SKIP: BLOCK #
########################

# Test #10: Object creation type
ok(
    ref( $obj = O_ERROR( 'Checking the cell structah' ) ) eq
        'POE::Component::Client::opentick::Output',
    'Correct Output object creation type',
);

# Test #11: Object properties
ok(
    $obj->get_level() eq 'ERROR'      &&
    $obj->get_timestamp() > 0         &&
    $obj->get_message() eq 'Checking the cell structah',
    'Correct Output object properties',
);

#diag( $obj->stringify() );

# Test #12: Object stringification
ok(
    $obj->stringify() =~ m/^OT:ERROR:[\d\.]+:Checking the cell structah$/,
    'Correct Output object stringification',
);

__END__

