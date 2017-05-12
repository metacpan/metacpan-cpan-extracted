#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Test::Most tests => 30;
use Test::NoWarnings;

use t::Util;

local $ENV{ PATH } = "t/bin:$ENV{PATH}";  # run our test versions of commands

BEGIN { use_ok( 'OpenVZ::Vzctl', qw( execute vzctl known_commands ) ) }

my @expect_execute_ls = (
    q{OpenVZ
OpenVZ.pm},
    q{},
    0,
    ignore(),
);

my @expect_execute_false = ( q{}, q{}, 256, ignore(), );
my $expecting_ref_regex  = t::Util::expecting_ref();
my $mandatory_regex      = t::Util::mandatory();
my $odd_number_regex     = t::Util::odd_number();
my $did_not_pass_regex   = t::Util::did_not_pass();

my $object = OpenVZ::Vzctl->new;
isa_ok( $object, 'OpenVZ::Vzctl', 'object created' );

note( 'Exceptions' ); #############################################################################################################
throws_ok { execute() } $mandatory_regex, 'empty call to execute dies correctly (functional)';
throws_ok { execute( '' ) } $odd_number_regex, 'null call to execute dies correctly (functional)';
throws_ok { execute( [] ) } $odd_number_regex, 'empty arrayref call to execute dies correctly (functional)';
throws_ok { execute( {} ) } $mandatory_regex, 'empty hashref call to execute dies correctly (functional)';

throws_ok { $object->execute() } $mandatory_regex, 'empty call to execute dies correctly (oop)';
throws_ok { $object->execute( '' ) } $odd_number_regex, 'null call to execute dies correctly (oop)';
throws_ok { $object->execute( [] ) } $odd_number_regex, 'empty arrayref call to execute dies correctly (oop)';
throws_ok { $object->execute( {} ) } $mandatory_regex, 'empty hashref call to execute dies correctly (oop)';

throws_ok { vzctl() } $expecting_ref_regex, 'empty call to vzctl dies correctly (functional)';
throws_ok { vzctl( '' ) } $expecting_ref_regex, 'null call to vzctl dies correctly (functional)';
throws_ok { vzctl( [] ) } $mandatory_regex, 'empty arrayref call to vzctl dies correctly (functional)';
throws_ok { vzctl( {} ) } $mandatory_regex, 'empty hashref call to vzctl dies correctly (functional)';

throws_ok { $object->vzctl() } $expecting_ref_regex, 'empty call to vzctl dies correctly (functional)';
throws_ok { $object->vzctl( '' ) } $expecting_ref_regex, 'null call to vzctl dies correctly (functional)';
throws_ok { $object->vzctl( [] ) } $mandatory_regex, 'empty arrayref call to vzctl dies correctly (functional)';
throws_ok { $object->vzctl( {} ) } $mandatory_regex, 'empty hashref call to vzctl dies correctly (functional)';

throws_ok { vzctl( { subcommand => 'badsubcommand' } ) } $did_not_pass_regex, 'badsubcommand dies correctly (functional)';
throws_ok { $object->vzctl( { subcommand => 'badsubcommand' } ) } $did_not_pass_regex, 'badsubcommand dies correctly (oop)';

{
    no warnings 'once';
    throws_ok { execute( \*GLOB ) } $odd_number_regex, 'glob call to execute dies correctly (functional)';
    throws_ok { $object->execute( \*GLOB ) } $odd_number_regex, 'glob call to execute dies correctly (oop)';

    throws_ok { vzctl( \*GLOB ) } $expecting_ref_regex, 'glob call to vzctl dies correctly (functional)';
    throws_ok { $object->vzctl( \*GLOB ) } $expecting_ref_regex, 'glob call to vzctl dies correctly (functional)';
}

note( 'Valid' ); ##################################################################################################################
cmp_deeply( [ execute( { command => 'false' } ) ], \@expect_execute_false, 'execute false works (functional)' );
cmp_deeply( [ execute( { command => 'ls', params => ['lib'] } ) ], \@expect_execute_ls, 'execute ls worked (functional)' );

cmp_deeply( [ $object->execute( { command => 'false' } ) ], \@expect_execute_false, 'execute false works (oop)' );
cmp_deeply( [ $object->execute( { command => 'ls', params => ['lib'] } ) ], \@expect_execute_ls, 'execute ls worked (oop)' );

# Valid calls to vzctl are tested in the respective subcommand test files.

###################################################################################################################################
# Test known_commands

my @known_commands = sort( known_commands() );

cmp_bag(
    \@known_commands, [ qw(

            chkpnt create destroy enter exec exec2 mount quotainit quotaoff quotaon
            restart restore runscript set start status stop umount

            ),
    ],
    'got expected known commands',
);
