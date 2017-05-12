#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

no warnings 'once';

use Test::Most tests => 15721;
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

    $subcommand = 'set';                  # <<<--- Change this to match the command you are testing against.

    use_ok( 'OpenVZ::Vzctl', qw( vzctl known_options subcommand_specs capabilities iptables_modules features ), $subcommand );

}

my @parms = sort qw( applyconfig applyconfig_map avnumproc bootorder capability cpulimit cpumask cpus cpuunits dcachesize devices
    devnodes dgramrcvbuf disabled diskinodes diskspace features force hostname ioprio ipadd ipdel iptables kmemsize lockedpages name
    nameserver netif_add netif_del noatime numfile numflock numiptent numothersock numproc numpty numsiginfo numtcpsock onboot
    oomguarpages othersockbuf pci_add pci_del physpages privvmpages quotatime quotaugidlimit save searchdomain setmode shmpages
    swappages tcprcvbuf tcpsndbuf userpasswd vmguarpages );  # <<<--- Change this to match the parameters you are expecting (checked
                                                             # against known_options).

# If the code pointed to by coderefs are bad, later testing will catch it.  We'll ignore it for testing the structure of the hash.

my $expected_spec = {                                        # <<<--- Change this to match expected hash from subcommand_specs

    ctid => { type => SCALAR, callbacks => { 'validate ctid' => ignore() } },
    flag => { type => SCALAR, optional => 1, regex => qr{^quiet|verbose$}i },

    applyconfig => { type => SCALAR, optional => 1, callbacks => { 'do not want empty strings' => ignore(), }, },
    avnumproc   => { type => SCALAR, optional => 1, regex     => qr{^\d+[gmkp]?(?::\d+[gmkp]?)?$}i },
    bootorder   => { type => SCALAR, optional => 1, regex     => qr{^\d+$} },
    cpumask     => { type => SCALAR, optional => 1, regex     => qr{^\d+(?:[,-]\d+)*|all$}i },
    devices     => { type => SCALAR, optional => 1, regex     => qr{^(?:(?:[bc]:\d+:\d+)|all:(?:r?w?))|none$}i },
    devnodes    => { type => SCALAR, optional => 1, callbacks => { 'setting access to devnode' => ignore() }, },
    force       => { type => UNDEF,  optional => 1 },
    ioprio => { type => SCALAR, optional => 1, regex => qr{^[0-7]$} },
    ipadd      => { type => SCALAR | ARRAYREF, optional => 1, callbacks => { 'do these look like valid ip(s)?' => ignore() }, },
    ipdel      => { type => SCALAR | ARRAYREF, optional => 1, callbacks => { 'do these look like valid ip(s)?' => ignore() }, },
    nameserver => { type => SCALAR | ARRAYREF, optional => 1, callbacks => { 'do these look like valid ip(s)?' => ignore() }, },
    onboot     => { type => SCALAR,            optional => 1, regex     => qr{^yes|no$}i },
    save       => { type => UNDEF,             optional => 1 },
    setmode    => { type => SCALAR, optional => 1, regex => qr{^restart|ignore$}i },
    userpasswd => { type => SCALAR, optional => 1, regex => qr{^(?:\w+):(?:\w+)$} },

    iptables =>
        { type => SCALAR | ARRAYREF, optional => 1, callbacks => { 'see manpage for list of valid iptables names' => ignore() }, },
};

my %same = (
    applyconfig => [ qw(

            applyconfig_map hostname name netif_add netif_del pci_add pci_del searchdomain

            ),
    ],
    avnumproc => [ qw(

            dcachesize dgramrcvbuf diskinodes diskspace kmemsize lockedpages numfile numflock numiptent numothersock numproc numpty
            numsiginfo numtcpsock oomguarpages othersockbuf physpages privvmpages shmpages swappages tcprcvbuf tcpsndbuf vmguarpages

            ),
    ],
    bootorder => [qw( cpulimit cpus cpuunits quotatime quotaugidlimit )],
    onboot    => [qw( disabled noatime )],
);

for my $key ( keys %same ) {

    $expected_spec->{ $_ } = $expected_spec->{ $key } for @{ $same{ $key } };

}

my %goodbad; @goodbad{ @parms } = t::Util::type( @parms );

#########################################################################################
my @cap_names = capabilities();

cmp_bag(
    \@cap_names, [ qw(

            chown dac_override dac_read_search fowner fsetid ipc_lock ipc_owner kill lease linux_immutable mknod net_admin
            net_bind_service net_broadcast net_raw setgid setpcap setuid setveid sys_admin sys_boot sys_chroot sys_module sys_nice
            sys_pacct sys_ptrace sys_rawio sys_resource sys_time sys_tty_config ve_admin

            ),
    ],
    'got expected capablity names',
);

my @good_cap_names = map { ( "$_:on",  "$_:off" ) } @cap_names;
my @bad_cap_names  = map { ( "$_:bad", t::Util::did_not_pass() ) } @cap_names;
push @bad_cap_names, 'justallaroundbad', t::Util::did_not_pass();

my $capability_names = join q{|}, @cap_names;
$expected_spec->{ capability } = { type => SCALAR, optional => 1, regex => qr{^(?:$capability_names):(?:on|off)$}i };

$goodbad{ capability }{ good } = \@good_cap_names;
push @{ $goodbad{ capability }{ bad } }, @bad_cap_names;

#########################################################################################
my @features_names = features();

cmp_bag( \@features_names, [qw( sysfs nfs sit ipip ppp ipgre bridge nfsd)], 'got expected features names' );

my @good_features_names = map { ( "$_:on",  "$_:off" ) } @features_names;
my @bad_features_names  = map { ( "$_:bad", t::Util::did_not_pass() ) } @features_names;
push @bad_features_names, 'justallaroundbad', t::Util::did_not_pass();

my $features_names = join q{|}, @features_names;
$expected_spec->{ features } = { type => SCALAR, optional => 1, regex => qr{^(?:$features_names):(?:on|off)$}i };

$goodbad{ features }{ good } = \@good_features_names;
push @{ $goodbad{ features }{ bad } }, @bad_features_names;

#########################################################################################
my @iptables_modules = iptables_modules();

cmp_bag(
    \@iptables_modules, [ qw(

            ip_conntrack ip_conntrack_ftp ip_conntrack_irc ip_nat_ftp ip_nat_irc iptable_filter iptable_mangle iptable_nat
            ipt_conntrack ipt_helper ipt_length ipt_limit ipt_LOG ipt_multiport ipt_owner ipt_recent ipt_REDIRECT ipt_REJECT
            ipt_state ipt_tcpmss ipt_TCPMSS ipt_tos ipt_TOS ipt_ttl xt_mac

            ),
    ],
    'got expected iptables modules',
);

my @iptables_names = map { ( "$_:on", "$_:off" ) } @iptables_modules;
$goodbad{ iptables }{ good } = \@iptables_names;

#
###################################################################################################################################

# XXX: The rest of this should be moved to t::Util somehow ...

my %invalid_regex = %{ t::Util::invalid_regex() };

note( 'Testing known_options' );
my @expected_parms = sort ( qw( flag ctid ), ( map { "[$_]" } @parms ) );
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
            my @oop_result = $empty_value_object->$subcommand( \%empty_value_hash );

            is( $oop_result[0], $empty_value_expected, "got $empty_value_expected (oop)" );
            is( $oop_result[1], '',                    'got empty stderr (oop)' );
            is( $oop_result[2], 0,                     'syserr was 0 (oop)' );
            like( $oop_result[3], qr/^\d+(?:.\d+)?$/, 'time was reported (oop)' );

            my @func_result;
            { no strict 'refs'; @func_result = $subcommand->( \%empty_value_hash ) }

            is( $func_result[0], $empty_value_expected, "got $empty_value_expected (functional)" );
            is( $func_result[1], '',                    'got empty stderr (functional)' );
            is( $func_result[2], 0,                     'syserr was 0 (functional)' );
            like( $func_result[3], qr/^\d+(?:.\d+)?$/, 'time was reported (functional)' );

        } ## end else [ if ( defined $parm...)]
    } ## end for my $flag ( t::Util::global_flags...)
} ## end for my $parm ( undef...)
