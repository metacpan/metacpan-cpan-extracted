use warnings;
use strict;
use Test::More;
use Siebel::Srvrmgr::Regexes qw(:all);

can_ok(
    'Siebel::Srvrmgr::Regexes',
    (
        qw(SRVRMGR_PROMPT LOAD_PREF_RESP LOAD_PREF_CMD CONN_GREET SIEBEL_ERROR ROWS_RETURNED SIEBEL_SERVER prompt_slices)
    )
);

# fixtures
my @cases = (
    [ 'srvrmgr>',                   undef,     undef ],
    [ 'srvrmgr:SUsrvr> ',           'SUsrvr',  undef ],
    [ 'srvrmgr> list comp',         undef,     'list comp' ],
    [ 'srvrmgr:foo_bar> list comp', 'foo_bar', 'list comp' ]
);

foreach my $case (@cases) {
    my $prompt = $case->[0];
    like( $prompt, SRVRMGR_PROMPT, "SRVRMGR_PROMPT matches '$prompt'" );
    my ( $server, $command ) = prompt_slices($prompt);
    is( $server, $case->[1],
        'prompt_slices returns the expected server name value' );
    is( $command, $case->[2],
        'prompt_slices returns the expected command value' );
}

my @pieces = ( 'srvrmgr:foo_bar> list comp' =~ SRVRMGR_PROMPT );
is( $pieces[0], ':foo_bar', 'matches the server name' )
  or diag( explain(@pieces) );
is( $pieces[1], ' list comp', 'matches the command' )
  or diag( explain(@pieces) );
my $load_pref_resp = 'File: C:\Siebel\8.0\web client\BIN\.Siebel_svrmgr.pref';
like( $load_pref_resp, LOAD_PREF_RESP,
    "LOAD_PREF_RESP matches '$load_pref_resp'" );
my $load_pref_cmd = 'srvrmgr:SUsrvr> load preferences';
like( $load_pref_cmd, LOAD_PREF_CMD, "LOAD_PREF_CMD matches '$load_pref_cmd'" );
my $hello =
'Siebel Enterprise Applications Siebel Server Manager, Version 8.0.0.7 [20426] LANG_INDEPENDENT';
like( $hello, CONN_GREET, "CONN_GREET matches '$hello'" );

foreach my $rows ( '1 row returned.', '12 rows returned.' ) {
    like( $rows, ROWS_RETURNED, "ROWS_RETURNED matches '$rows'" );
}

foreach my $error (qw(SBL-OMS-00203 SBL-SRQ-00103 SBL-EAI-04116 SBL-UIF-00227))
{
    like( $error, SIEBEL_ERROR, "SIEBEL_ERROR matches $error" );
}

note('SIEBEL_SERVER validations');
like( 'sieb_serv054', SIEBEL_SERVER, 'matches with all restrictions applied' );
unlike( '1ieb_serv054', SIEBEL_SERVER,
    'server name must start with a alphabetic character' );
unlike( 'sieb_serv0540', SIEBEL_SERVER, 'larger than 12 characters' );

done_testing;
