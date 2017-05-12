#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Test::Most tests => 29;
use Test::NoWarnings;

use t::Util;

local $ENV{ PATH } = "t/bin:$ENV{PATH}";  # run our test versions of commands

BEGIN { use_ok( 'OpenVZ::Vzlist', qw( execute known_options known_fields vzlist ) ) }

my $expecting_ref_regex = t::Util::expecting_ref();
my $mandatory_regex     = t::Util::mandatory();
my $odd_number_regex    = t::Util::odd_number();
my $did_not_pass_regex  = t::Util::did_not_pass();
my $not_listed_regex    = t::Util::not_listed();

###################################################################################################################################
# Test known_options

my @known_options = sort( known_options() );

cmp_bag(
    \@known_options,
    [ map { "[$_]" } sort qw( all description output sort list name no-header stopped hostname name_filter ) ],
    'known_options matches'
);

###################################################################################################################################
# Test known_fields

my @known_fields = sort( known_fields() );

my @expected_fields = sort( qw(

        bootorder cpulimit cpuunits ctid dcachesize dcachesize.b dcachesize.f dcachesize.l dcachesize.m description dgramrcvbuf
        dgramrcvbuf.b dgramrcvbuf.f dgramrcvbuf.l dgramrcvbuf.m diskinodes diskinodes.h diskinodes.s diskspace diskspace.h diskspace.s
        hostname ioprio ip kmemsize kmemsize.b kmemsize.f kmemsize.l kmemsize.m laverage lockedpages lockedpages.b lockedpages.f
        lockedpages.l lockedpages.m name numfile numfile.b numfile.f numfile.l numfile.m numflock numflock.b numflock.f numflock.l
        numflock.m numiptent numiptent.b numiptent.f numiptent.l numiptent.m numothersock numothersock.b numothersock.f numothersock.l
        numothersock.m numproc numproc.b numproc.f numproc.l numproc.m numpty numpty.b numpty.f numpty.l numpty.m numsiginfo
        numsiginfo.b numsiginfo.f numsiginfo.l numsiginfo.m numtcpsock numtcpsock.b numtcpsock.f numtcpsock.l numtcpsock.m onboot
        oomguarpages oomguarpages.b oomguarpages.f oomguarpages.l oomguarpages.m ostemplate othersockbuf othersockbuf.b othersockbuf.f
        othersockbuf.l othersockbuf.m physpages physpages.b physpages.f physpages.l physpages.m privvmpages privvmpages.b privvmpages.f
        privvmpages.l privvmpages.m shmpages shmpages.b shmpages.f shmpages.l shmpages.m status swappages swappages.b swappages.f
        swappages.l swappages.m tcprcvbuf tcprcvbuf.b tcprcvbuf.f tcprcvbuf.l tcprcvbuf.m tcpsndbuf tcpsndbuf.b tcpsndbuf.f tcpsndbuf.l
        tcpsndbuf.m uptime vmguarpages vmguarpages.b vmguarpages.f vmguarpages.l vmguarpages.m

        ) );

cmp_bag( \@known_fields, \@expected_fields, 'known_fields matches' );

###################################################################################################################################

my $object = OpenVZ::Vzlist->new;
isa_ok( $object, 'OpenVZ::Vzlist', 'object created' );

note( 'Exceptions' ); #############################################################################################################
throws_ok { execute() } $mandatory_regex, 'empty call to execute dies correctly (functional)';
throws_ok { execute( '' ) } $odd_number_regex, 'null call to execute dies correctly (functional)';
throws_ok { execute( [] ) } $odd_number_regex, 'empty arrayref call to execute dies correctly (functional)';
throws_ok { execute( {} ) } $mandatory_regex, 'empty hashref call to execute dies correctly (functional)';

throws_ok { $object->execute() } $mandatory_regex, 'empty call to execute dies correctly (oop)';
throws_ok { $object->execute( '' ) } $odd_number_regex, 'null call to execute dies correctly (oop)';
throws_ok { $object->execute( [] ) } $odd_number_regex, 'empty arrayref call to execute dies correctly (oop)';
throws_ok { $object->execute( {} ) } $mandatory_regex, 'empty hashref call to execute dies correctly (oop)';

throws_ok { vzlist( '' ) } $odd_number_regex, 'null call to vzlist dies correctly (functional)';
throws_ok { vzlist( [] ) } $odd_number_regex, 'empty arrayref call to vzlist dies correctly (functional)';

throws_ok { $object->vzlist( '' ) } $odd_number_regex, 'null call to vzlist dies correctly (functional)';
throws_ok { $object->vzlist( [] ) } $odd_number_regex, 'empty arrayref call to vzlist dies correctly (functional)';

throws_ok { vzlist( { badoption => 'badoption' } ) } $not_listed_regex, 'badoption dies correctly (functional)';
throws_ok { $object->vzlist( { badoption => 'badoption' } ) } $not_listed_regex, 'badoption dies correctly (functional)';

{
    no warnings 'once';
    throws_ok { execute( \*GLOB ) } $odd_number_regex, 'glob call to execute dies correctly (functional)';
    throws_ok { $object->execute( \*GLOB ) } $odd_number_regex, 'glob call to execute dies correctly (oop)';

    throws_ok { vzlist( \*GLOB ) } $odd_number_regex, 'glob call to vzlist dies correctly (functional)';
    throws_ok { $object->vzlist( \*GLOB ) } $odd_number_regex, 'glob call to vzlist dies correctly (functional)';
}

note( 'Valid' ); ##################################################################################################################

my @expect_execute_false = ( q{}, q{}, 256, ignore(), );

my @expect_execute_ls = (
    q{OpenVZ
OpenVZ.pm},
    q{},
    0,
    ignore(),
);

my @expect_vzlist_empty = ( q{t/bin/vzlist}, q{}, 0, ignore() );

cmp_deeply( [ execute( { command => 'false' } ) ], \@expect_execute_false, 'execute false works (functional)' );
cmp_deeply( [ execute( { command => 'ls', params => ['lib'] } ) ], \@expect_execute_ls, 'execute ls worked (functional)' );

cmp_deeply( [ $object->execute( { command => 'false' } ) ], \@expect_execute_false, 'execute false works (oop)' );
cmp_deeply( [ $object->execute( { command => 'ls', params => ['lib'] } ) ], \@expect_execute_ls, 'execute ls worked (oop)' );

# vzlist should be ok with these
#throws_ok { vzlist( {} ) } $mandatory_regex, 'empty hashref call to vzlist dies correctly (functional)';
#throws_ok { $object->vzlist( {} ) } $mandatory_regex, 'empty hashref call to vzlist dies correctly (functional)';

cmp_deeply( [ vzlist() ],          \@expect_vzlist_empty, 'empty call to vzlist worked (functional)' );
cmp_deeply( [ $object->vzlist() ], \@expect_vzlist_empty, 'empty call to vzlist worked (oop)' );
