use warnings;
use strict;
use Test::More;
use Siebel::Lbconfig qw(get_daemon recover_info create_files);
use Siebel::Srvrmgr::Daemon::ActionStash 0.27;
use Digest::MD5 qw(md5_base64);
use File::Spec;
use Config;

my $module = 'Siebel::Lbconfig';
can_ok( $module, qw(get_daemon recover_info) );
my $stash = create_fixtures();
note(
'Testing creating lbconfig data using port 7001 for Siebel Connection Broker'
);
my $lbconfig_data = recover_info( $stash, 7001 );
is_deeply( $lbconfig_data, exp_lbdata(),
    'recover_info returns the expected data structure' )
  or diag( explain($lbconfig_data) );
note('Validating files creation');
create_files( File::Spec->catdir( 't', 'eapps' ), exp_lbdata() );
my ( $exp_digest1, $exp_digest2, $exp_digest3 );

if ( $Config{osname} eq 'MSWin32' ) {
    $exp_digest1 = '4wlJvgFCLdGld96RChK3+w';
    $exp_digest2 = 'B09RsSkcELHV0dDlLbCTNA';
    $exp_digest3 = '5+1RVlLC3BYs78hMJCPpoA';
}
else {
    $exp_digest1 = '4wlJvgFCLdGld96RChK3+w';
    $exp_digest2 = 'B09RsSkcELHV0dDlLbCTNA';
    $exp_digest3 = '5+1RVlLC3BYs78hMJCPpoA';
}

my $digest = md5_base64( read_file('lbconfig.txt') );
is( $digest, $exp_digest1, 'lbconfig.txt is created with expected content' );
$digest =
  md5_base64( read_file( File::Spec->catfile( 't', 'eapps', 'eapps.cfg' ) ) );
is( $digest, $exp_digest2, 'eapps.cfg.new is created with expected content' );
$digest =
  md5_base64(
    read_file( File::Spec->catfile( 't', 'eapps', 'eapps_sia.cfg' ) ) );
is( $digest, $exp_digest3,
    'eapps_sia.cfg.new is created with expected content' );
done_testing;

sub create_fixtures {
    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance;
    $stash->push_stash(
        {
            'EAIObjMgrXXXXX_enu' => [
                'sieb_serv057', 'sieb_serv049',
                'sieb_serv053', 'sieb_serv048',
                'sieb_serv058'
            ],
            'EAIObjMgr_enu' => [
                'sieb_serv045', 'sieb_serv052',
                'sieb_serv057', 'sieb_serv049',
                'sieb_serv053', 'sieb_serv048',
                'sieb_serv058'
            ],
            'SCCObjMgr_enu'      => [ 'sieb_serv053', 'sieb_serv048' ],
            'SCCObjMgr_esn'      => [ 'sieb_serv053', 'sieb_serv048' ],
            'SCCObjMgr_ptb'      => [ 'sieb_serv053', 'sieb_serv048' ],
            'SMObjMgr_enu'       => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMObjMgr_esn'       => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMObjMgr_ptb'       => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMSMLObjMgr_enu'    => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMSMLObjMgr_esn'    => [ 'sieb_serv056', 'sieb_serv050' ],
            'SMSMLObjMgr_ptb'    => [ 'sieb_serv056', 'sieb_serv050' ],
            'SServiceObjMgr_enu' => [ 'sieb_serv053', 'sieb_serv048' ],
            'SServiceObjMgr_esn' => [ 'sieb_serv053', 'sieb_serv048' ],
            'SServiceObjMgr_ptb' => [ 'sieb_serv053', 'sieb_serv048' ],
            'eMarketObjMgr_enu'  => [ 'sieb_serv047', 'sieb_serv046' ],
            'eMarketObjMgr_esn'  => [ 'sieb_serv047', 'sieb_serv046' ],
            'eMarketObjMgr_ptb'  => [ 'sieb_serv047', 'sieb_serv046' ],
            'eServiceObjMgr_enu' => [ 'sieb_serv053', 'sieb_serv048' ],
            'eServiceObjMgr_esn' => [ 'sieb_serv053', 'sieb_serv048' ],
            'eServiceObjMgr_ptb' => [ 'sieb_serv053', 'sieb_serv048' ],
            'loyaltyObjMgr_enu' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltyObjMgr_enu' => [
                'sieb_serv049', 'sieb_serv053', 'sieb_serv048', 'sieb_serv051'
            ],
            'loyaltyObjMgr_esn' => [
                'sieb_serv049', 'sieb_serv053', 'sieb_serv048', 'sieb_serv051'
            ],
            'loyaltyObjMgr_ptb' => [
                'sieb_serv049', 'sieb_serv053', 'sieb_serv048', 'sieb_serv051'
            ],
            'loyaltySMLObjMgr_enu' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltySMLObjMgr_esn' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltySMLObjMgr_ptb' =>
              [ 'sieb_serv049', 'sieb_serv053', 'sieb_serv048' ],
            'loyaltyscwObjMgr_enu' => [ 'sieb_serv047', 'sieb_serv046' ],
            'loyaltyscwObjMgr_esn' => [ 'sieb_serv047', 'sieb_serv046' ],
            'loyaltyscwObjMgr_ptb' => [ 'sieb_serv047', 'sieb_serv046' ]
        }
    );
    $stash->push_stash(
        {
            'sieb_serv045' => 3,
            'sieb_serv046' => 19,
            'sieb_serv047' => 21,
            'sieb_serv048' => 7,
            'sieb_serv049' => 9,
            'sieb_serv050' => 11,
            'sieb_serv051' => 23,
            'sieb_serv052' => 13,
            'sieb_serv053' => 15,
            'sieb_serv056' => 17,
            'sieb_serv057' => 1,
            'sieb_serv058' => 5
        }
    );
    return $stash;
}

sub exp_lbdata {
    return [
        {
            'comp_alias' => 'EAIObjMgrXXXXX_enu',
            'servers' =>
'1:sieb_serv057:7001;9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;5:sieb_serv058:7001;',
            'vs' => 'EAIXXXXXENU_VS'
        },
        {
            'comp_alias' => 'EAIObjMgr_enu',
            'servers' =>
'3:sieb_serv045:7001;13:sieb_serv052:7001;1:sieb_serv057:7001;9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;5:sieb_serv058:7001;',
            'vs' => 'EAIENU_VS'
        },
        {
            'comp_alias' => 'SCCObjMgr_enu',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'SCCENU_VS'
        },
        {
            'comp_alias' => 'SCCObjMgr_esn',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'SCCESN_VS'
        },
        {
            'comp_alias' => 'SCCObjMgr_ptb',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'SCCPTB_VS'
        },
        {
            'comp_alias' => 'SMObjMgr_enu',
            'servers'    => '17:sieb_serv056:7001;11:sieb_serv050:7001;',
            'vs'         => 'SMENU_VS'
        },
        {
            'comp_alias' => 'SMObjMgr_esn',
            'servers'    => '17:sieb_serv056:7001;11:sieb_serv050:7001;',
            'vs'         => 'SMESN_VS'
        },
        {
            'comp_alias' => 'SMObjMgr_ptb',
            'servers'    => '17:sieb_serv056:7001;11:sieb_serv050:7001;',
            'vs'         => 'SMPTB_VS'
        },
        {
            'comp_alias' => 'SMSMLObjMgr_enu',
            'servers'    => '17:sieb_serv056:7001;11:sieb_serv050:7001;',
            'vs'         => 'SMSMLENU_VS'
        },
        {
            'comp_alias' => 'SMSMLObjMgr_esn',
            'servers'    => '17:sieb_serv056:7001;11:sieb_serv050:7001;',
            'vs'         => 'SMSMLESN_VS'
        },
        {
            'comp_alias' => 'SMSMLObjMgr_ptb',
            'servers'    => '17:sieb_serv056:7001;11:sieb_serv050:7001;',
            'vs'         => 'SMSMLPTB_VS'
        },
        {
            'comp_alias' => 'SServiceObjMgr_enu',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'SServiceENU_VS'
        },
        {
            'comp_alias' => 'SServiceObjMgr_esn',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'SServiceESN_VS'
        },
        {
            'comp_alias' => 'SServiceObjMgr_ptb',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'SServicePTB_VS'
        },
        {
            'comp_alias' => 'eMarketObjMgr_enu',
            'servers'    => '21:sieb_serv047:7001;19:sieb_serv046:7001;',
            'vs'         => 'eMarketENU_VS'
        },
        {
            'comp_alias' => 'eMarketObjMgr_esn',
            'servers'    => '21:sieb_serv047:7001;19:sieb_serv046:7001;',
            'vs'         => 'eMarketESN_VS'
        },
        {
            'comp_alias' => 'eMarketObjMgr_ptb',
            'servers'    => '21:sieb_serv047:7001;19:sieb_serv046:7001;',
            'vs'         => 'eMarketPTB_VS'
        },
        {
            'comp_alias' => 'eServiceObjMgr_enu',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'eServiceENU_VS'
        },
        {
            'comp_alias' => 'eServiceObjMgr_esn',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'eServiceESN_VS'
        },
        {
            'comp_alias' => 'eServiceObjMgr_ptb',
            'servers'    => '15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs'         => 'eServicePTB_VS'
        },
        {
            'comp_alias' => 'loyaltyObjMgr_enu',
            'servers' =>
'9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;23:sieb_serv051:7001;',
            'vs' => 'loyaltyENU_VS'
        },
        {
            'comp_alias' => 'loyaltyObjMgr_esn',
            'servers' =>
'9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;23:sieb_serv051:7001;',
            'vs' => 'loyaltyESN_VS'
        },
        {
            'comp_alias' => 'loyaltyObjMgr_ptb',
            'servers' =>
'9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;23:sieb_serv051:7001;',
            'vs' => 'loyaltyPTB_VS'
        },
        {
            'comp_alias' => 'loyaltySMLObjMgr_enu',
            'servers' =>
              '9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs' => 'loyaltySMLENU_VS'
        },
        {
            'comp_alias' => 'loyaltySMLObjMgr_esn',
            'servers' =>
              '9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs' => 'loyaltySMLESN_VS'
        },
        {
            'comp_alias' => 'loyaltySMLObjMgr_ptb',
            'servers' =>
              '9:sieb_serv049:7001;15:sieb_serv053:7001;7:sieb_serv048:7001;',
            'vs' => 'loyaltySMLPTB_VS'
        },
        {
            'comp_alias' => 'loyaltyscwObjMgr_enu',
            'servers'    => '21:sieb_serv047:7001;19:sieb_serv046:7001;',
            'vs'         => 'loyaltyscwENU_VS'
        },
        {
            'comp_alias' => 'loyaltyscwObjMgr_esn',
            'servers'    => '21:sieb_serv047:7001;19:sieb_serv046:7001;',
            'vs'         => 'loyaltyscwESN_VS'
        },
        {
            'comp_alias' => 'loyaltyscwObjMgr_ptb',
            'servers'    => '21:sieb_serv047:7001;19:sieb_serv046:7001;',
            'vs'         => 'loyaltyscwPTB_VS'
        }
    ];
}

sub read_file {
    my ($file) = @_;
    local $/ = undef;
    open( my $in, '<', $file ) or die "Cannot read $file: $!";
    my $data = <$in>;
    close($in);
    return $data;
}

END {
    unlink 'lbconfig.txt';
}
