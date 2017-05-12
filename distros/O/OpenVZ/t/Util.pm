package t::Util;

use strict;
use warnings;

use Test::Most;

my @bad_ctids        = qw( invalid_ctid invalid_name );
my $did_not_pass     = qr/did not pass/;
my $expecting_ref    = qr/Expecting array or hash reference in/;
my @global_flags     = ( '', 'quiet', 'verbose' );
my $mandatory        = qr/Mandatory parameters? '.*?' missing in call/;
my $not_allowed_type = qr/not one of the allowed types/;
my $not_listed       = qr/was not listed in the validation options/;
my $odd_number       = qr/Odd number of parameters/;

my %check = do {

    # Basic types to check for:

    my $scalar   = 'scalar';
    my $arrayref = [qw( bad1 bad2 )];
    my $hashref  = { bad3 => 4, bad5 => 6 };
    my $coderef  = sub { };
    my $glob     = do { local *GLOB }; ## no critic qw( Variables::ProhibitLocalVars Variables::RequireInitializationForLocalVars )
    my $globref  = \*GLOB;

    my %hash = (

        applyconfig => {
            good => [$scalar],
            bad  => [
                undef,     $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $arrayref, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,     $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        avnumproc => {
            good => [ 100, '101g', '102m', '103k', '104p', '105:106', '107g:108m', '109k:110p' ],
            bad  => [
                undef,     $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $arrayref, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,     $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        bootorder => {
            good => [1],
            bad  => [
                undef,     $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $arrayref, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,     $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        capability => {
            good => [],
            bad  => [
                undef,     $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $arrayref, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,     $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        command => {
            good => [ 'good', [qw( one two )] ],
            bad => [
                undef, $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                [],    $did_not_pass,     $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob, $not_allowed_type, $globref, $not_allowed_type,
            ],
            bare => 1,  # --command should not appear in the actual command
        },

        cpumask => {
            good => [ 1, '2:3', 'all' ],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $hashref, $not_allowed_type, $coderef, $not_allowed_type, $glob,    $not_allowed_type,
                $globref, $not_allowed_type,
            ],
        },

        devices => {
            good => [ 'none', 'all:r', 'all:w', 'all:rw', 'b:1:2', 'c:3:4' ],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $hashref, $not_allowed_type, $coderef, $not_allowed_type, $glob,    $not_allowed_type,
                $globref, $not_allowed_type, 'all',    $did_not_pass,
            ],
        },

        features => {
            good => [],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $hashref, $not_allowed_type, $coderef, $not_allowed_type, $glob,    $not_allowed_type,
                $globref, $not_allowed_type,
            ],
        },

        force => {
            good => [undef],
            bad  => [
                $scalar,  $not_allowed_type, \$scalar, $not_allowed_type, $hashref, $not_allowed_type,
                $coderef, $not_allowed_type, $glob,    $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        ioprio => {
            good => [ 0 .. 7 ],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $hashref, $not_allowed_type, $coderef, $not_allowed_type, $glob,    $not_allowed_type,
                $globref, $not_allowed_type, 8,        $did_not_pass,
            ],
        },

        onboot => {
            good => [qw( yes no )],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     $scalar,  $did_not_pass,
                \$scalar, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,    $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        setmode => {
            good => [qw( restart ignore )],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     $scalar,  $did_not_pass,
                \$scalar, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,    $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        #    userpasswd  => { regex     => qr/^(?:\w+):(?:\w+)$/ },
        userpasswd => {
            good => ['joeuser:seekrit'],
            bad  => [
                undef,    $not_allowed_type, '',       $did_not_pass,     $scalar,  $did_not_pass,
                \$scalar, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,    $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        ipadd => {
            good => [ '1.2.3.4', [qw( 1.2.3.4 2.3.4.5 )] ],
            bad => [
                undef,    $not_allowed_type, '',          $did_not_pass,
                $scalar,  $did_not_pass,     \$scalar,    $not_allowed_type,
                [],       $did_not_pass,     $hashref,    $not_allowed_type,
                $coderef, $not_allowed_type, $glob,       $not_allowed_type,
                $globref, $not_allowed_type, '300.1.2.3', $did_not_pass,
                [qw( 1.2.3.4 300.1.2.3 )], $did_not_pass, [ qw( 1.2.3.4 2.3.4.5 ), '' ], $did_not_pass,
            ],
        },

        ipdel => {
            good => [ 'all', '1.2.3.4', [qw( 1.2.3.4 2.3.4.5 )] ],
            bad => [
                undef,    $not_allowed_type, '',          $did_not_pass,
                $scalar,  $did_not_pass,     \$scalar,    $not_allowed_type,
                [],       $did_not_pass,     $hashref,    $not_allowed_type,
                $coderef, $not_allowed_type, $glob,       $not_allowed_type,
                $globref, $not_allowed_type, '300.1.2.3', $did_not_pass,
                [qw( 1.2.3.4 300.1.2.3 )], $did_not_pass, [ qw( 1.2.3.4 2.3.4.5 ), '' ], $did_not_pass,
            ],
        },

        iptables => {
            good => [],
            bad  => [
                undef, $not_allowed_type, '', $did_not_pass, $scalar, $did_not_pass,
                \$scalar, $not_allowed_type, [], $did_not_pass, $arrayref, $did_not_pass,
                $hashref, $not_allowed_type, $coderef, $not_allowed_type, $glob, $not_allowed_type,
                $globref, $not_allowed_type,
            ],
        },

        create_dumpfile => {
            good => ['/tmp/testfile'],
            bad  => [
                undef,     $not_allowed_type, '',       $did_not_pass,     \$scalar, $not_allowed_type,
                $arrayref, $not_allowed_type, $hashref, $not_allowed_type, $coderef, $not_allowed_type,
                $glob,     $not_allowed_type, $globref, $not_allowed_type,
            ],
        },

        restore_dumpfile => {
            good => ['/dev/urandom'],
            bad  => [
                undef,                                          $not_allowed_type,
                '',                                             $did_not_pass,
                \$scalar,                                       $not_allowed_type,
                $arrayref,                                      $not_allowed_type,
                $hashref,                                       $not_allowed_type,
                $coderef,                                       $not_allowed_type,
                $glob,                                          $not_allowed_type,
                $globref,                                       $not_allowed_type,
                '/why/do/you/have/a/path/that/looks/like/this', $did_not_pass,
            ],
        },

        #    devnodes => { callbacks => { 'setting access to devnode' => sub {
        devnodes => {
            good => [qw( none urandom:r urandom:w urandom:q urandom:rw urandom:rq urandom:wq )],
            bad  => [
                undef,    $not_allowed_type, '',        $did_not_pass,     $scalar,  $did_not_pass,
                \$scalar, $not_allowed_type, $arrayref, $not_allowed_type, $hashref, $not_allowed_type,
                $coderef, $not_allowed_type, $glob,     $not_allowed_type, $globref, $not_allowed_type,
            ],
        },
    );

    my %same = (

        # SCALAR checks
        applyconfig => [ qw(

                applyconfig_map config hostname name netif_add netif_del ostemplate
                pci_add pci_del private root searchdomain

                ),
        ],

        # SCALAR | ARRAYREF checks
        command => [qw( exec script )],

        # UNDEF checks
        force => [qw( save wait )],

        # INT checks
        bootorder => [qw( cpulimit cpus cpuunits quotatime quotaugidlimit )],

        # yes or no checks
        onboot => [qw( disabled noatime )],

        # ip checks
        ipadd => [qw( nameserver )],

        # hard|soft limits
        avnumproc => [ qw(

                dcachesize dgramrcvbuf diskinodes diskspace kmemsize lockedpages numfile
                numflock numiptent numothersock numproc numpty numsiginfo numtcpsock
                oomguarpages othersockbuf physpages privvmpages shmpages swappages
                tcprcvbuf tcpsndbuf vmguarpages

                ),
        ],
    );

    for my $key ( keys %same ) {

        $hash{ $_ } = $hash{ $key } for @{ $same{ $key } };

    }

    %hash;

};

my %invalid_regex = (

    ## no critic qw( RegularExpressions::ProhibitComplexRegexes )
    invalid_ctid => qr/\QInvalid or unknown container (invalid_ctid): Container(s) not found/,
    invalid_name => qr/\QInvalid or unknown container (invalid_name): CT ID invalid_name is invalid./,
    ## use critic

);

sub bad_ctids        { @bad_ctids }
sub did_not_pass     { $did_not_pass }
sub expecting_ref    { $expecting_ref }
sub global_flags     { @global_flags }
sub invalid_regex    { \%invalid_regex }
sub mandatory        { $mandatory }
sub not_allowed_type { $not_allowed_type }
sub not_listed       { $not_listed }
sub odd_number       { $odd_number }
sub type             { @check{ @_ } }

1;
