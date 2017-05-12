#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

no warnings 'once';

use Test::Most tests => 175;
use Test::NoWarnings;

use Carp;
use Params::Validate ':all';
use Regexp::Common qw( URI net );

use t::Util;

local $ENV{ PATH } = "t/bin:$ENV{PATH}";  # run our test versions of commands

###################################################################################################################################
# These are the only lines you should have to modify

my $subcommand;

BEGIN {

    $subcommand = 'exec';                 # <<<--- Change this to match the command you are testing against.

    use_ok( 'OpenVZ::Vzctl', qw( vzctl known_options subcommand_specs ), $subcommand );

}

my @parms = qw( command );                # <<<--- Change this to match the parameters you are expecting (checked against
                                          # known_options).

# If the code pointed to by coderefs are bad, later testing will catch it.  We'll ignore it for testing the structure of the hash.

my $expected_spec = {                     # <<<--- Change this to match expected hash from subcommand_specs

    command => { type => SCALAR | ARRAYREF, callbacks => { 'do not want empty values' => ignore() }, },
    ctid    => { type => SCALAR,            callbacks => { 'validate ctid'            => ignore() } },
    flag => { type => SCALAR, optional => 1, regex => qr{^quiet|verbose$}i },

};

#
###################################################################################################################################

# XXX: The rest of this should be moved to t::Util somehow ...

my %goodbad; @goodbad{ @parms } = t::Util::type( @parms );
my %invalid_regex   = %{ t::Util::invalid_regex() };
my $mandatory_regex = t::Util::mandatory();

note( 'Testing known_options' );
my @expected_parms = sort ( qw( flag ctid ), @parms );
my @known_options = sort @{ known_options( $subcommand ) };
cmp_deeply( \@known_options, \@expected_parms, "$subcommand known_options matches" );

note( 'Testing subcommand_specs' );
my $subcommand_spec = subcommand_specs( $subcommand );
cmp_deeply( $subcommand_spec, $expected_spec, "$subcommand subcommand spec matches" );

for my $parm ( undef, @parms ) {
    for my $flag ( t::Util::global_flags() ) {

        note(
            sprintf 'Testing %s %s%sbad ctids',
            $subcommand,
            ( $flag ne '' ? "--$flag " : '' ),
            ( defined $parm ? "$parm " : '' ) );

        for my $ctid ( t::Util::bad_ctids() ) {

            my %invalid_hash = ( ctid => $ctid );

            $invalid_hash{ flag } = $flag
                if $flag ne '';

            my $bad_ctids_info = sprintf '%s %s%s %s ... -- caught %s',
                $subcommand, ( $flag ? "--$flag " : '' ), $ctid, ( $parm ? "--$parm" : '' ), $ctid;

            my $bad_ctids_object = OpenVZ::Vzctl->new;
            isa_ok( $bad_ctids_object, 'OpenVZ::Vzctl', 'object created for bad ctids' );

            throws_ok { no strict 'refs'; $subcommand->( \%invalid_hash ) } $invalid_regex{ $ctid }, "$bad_ctids_info (functional)";
            throws_ok { $bad_ctids_object->$subcommand( \%invalid_hash ) } $invalid_regex{ $ctid }, "$bad_ctids_info (oop)";

        }

        my $ctid = int 100 + rand 100;

        if ( defined $parm && $parm ne '' ) {

            my $name = join '', map { chr( 97 + rand 26 ) } 0 .. ( int rand 20 ) + 1;
            my $test = "$ctid,$name";

            note(
                sprintf 'Testing %s %s%sbad values',
                $subcommand,
                ( $flag ne '' ? "--$flag " : '' ),
                ( defined $parm ? "$parm " : '' ) );

            my $bad_values = defined $parm ? $goodbad{ $parm }{ bad } : [];

            for ( my $ix = 0 ; $ix < @$bad_values ; $ix += 2 ) {

                my %bad_hash;
                $bad_hash{ ctid }  = $ctid;
                $bad_hash{ flag }  = $flag if $flag ne '';
                $bad_hash{ $parm } = $bad_values->[$ix];

                no warnings 'uninitialized';
                my $info = sprintf '%s %s%s --%s %s -- caught bad value',
                    $subcommand, ( $flag ? "$flag " : '' ), $ctid, $parm, $bad_values->[$ix];

                my $bad_values_object = OpenVZ::Vzctl->new;
                isa_ok( $bad_values_object, 'OpenVZ::Vzctl', 'object created for bad values' );
                throws_ok { $bad_values_object->$subcommand( \%bad_hash ) } $bad_values->[ $ix + 1 ], "$info (oop)";

                no strict 'refs';
                throws_ok { no strict 'refs'; $subcommand->( \%bad_hash ) } $bad_values->[ $ix + 1 ], "$info (functional)";

            }  # end for ( my $ix = 0; $ix < @$bad_values ; $ix += 2 )

            note(
                sprintf 'Testing %s %s%sgood values',
                $subcommand,
                ( $flag ne '' ? "--$flag " : '' ),
                ( defined $parm ? "$parm " : '' ) );

            my $good_values = defined $parm ? $goodbad{ $parm }{ good } : [];

            for ( my $ix = 0 ; $ix < @$good_values ; $ix++ ) {

                my $expected_parm;

                my $value_ref = ref $good_values->[$ix];

                if ( $value_ref eq 'ARRAY' ) {

                    if ( $parm =~ /^command|script$/ ) {

                        $expected_parm = join ' ', @{ $good_values->[$ix] };

                    } else {

                        $expected_parm = join ' ', map { "--$parm $_" } @{ $good_values->[$ix] };

                    }

                } elsif ( $value_ref eq '' ) {

                    if ( defined $good_values->[$ix] ) {

                        if ( $parm =~ /^command|script$/ ) {

                            $expected_parm = $good_values->[$ix];

                        } else {

                            $expected_parm = sprintf '--%s %s', $parm, $good_values->[$ix];

                        }

                    } else {

                        $expected_parm = "--$parm";

                    }

                } else {

                    carp "Expecting scalar or arrayref for good test values";

                }

                my $expected = sprintf 'vzctl %s%s %s %s', ( $flag ? "--$flag " : '' ), $subcommand, $ctid, $expected_parm;

                my %good_hash = ( ctid => $test, $parm => $good_values->[$ix] );
                $good_hash{ flag } = $flag if $flag ne '';

                my $good_values_object = OpenVZ::Vzctl->new;
                isa_ok( $good_values_object, 'OpenVZ::Vzctl', 'object created for bad values' );
                my @object_result = $good_values_object->$subcommand( \%good_hash );

                is( $object_result[0], $expected, "got $expected" );
                is( $object_result[1], '',        'got empty stderr' );
                is( $object_result[2], 0,         'syserr was 0' );
                like( $object_result[3], qr/^\d+(?:.\d+)?$/, 'time was reported' );

                my @result;
                { no strict 'refs'; @result = $subcommand->( \%good_hash ) }

                is( $result[0], $expected, "got $expected" );
                is( $result[1], '',        'got empty stderr' );
                is( $result[2], 0,         'syserr was 0' );
                like( $result[3], qr/^\d+(?:.\d+)?$/, 'time was reported' );

            } ## end for ( my $ix = 0 ;...)
        } else {

            my %empty_value_hash = ( ctid => $ctid );
            $empty_value_hash{ flag } = $flag if $flag ne '';

            my $empty_value_expected = sprintf 'vzctl %s%s %s', ( $flag ? "--$flag " : '' ), $subcommand, $ctid;

            my $empty_value_object = OpenVZ::Vzctl->new;
            isa_ok( $empty_value_object, 'OpenVZ::Vzctl', 'object created for bad values' );
            throws_ok { $empty_value_object->$subcommand( \%empty_value_hash ) } $mandatory_regex, 'command is required (oop)';
            throws_ok { no strict 'refs'; $subcommand->( \%empty_value_hash ) } $mandatory_regex,
                'command is required (functional)';

        }
    } ## end for my $flag ( t::Util::global_flags...)
} ## end for my $parm ( undef...)
