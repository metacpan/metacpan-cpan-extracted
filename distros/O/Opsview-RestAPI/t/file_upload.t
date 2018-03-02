use 5.12.1;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp;
use File::Basename;
use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);
use ORA_Test;

SKIP: {
    my $ora_test = ORA_Test->new();
    skip $@ if $@;

    my $rest = $ora_test->login();

    my $fh = File::Temp->new(
        TEMPLATE => 'check_XXXXXX',
        TMP_DIR  => 1,
        UNLINK   => 0
    );
    print {$fh} <<'EOF';
#!/usr/bin/env perl
print "Fake check for Opsview::RestAPI file_upload test; always returns ok\n";
exit 0;
EOF

    # close the temp file to allow for uploading to Opsview
    # Need to remove it later
    $fh->close;

    does_plugin_exist( $rest,  0, $fh->filename );

    note( 'Uploading plugin "' . $fh->filename . '" to Opsview' );
    my $result = trap {
        $rest->file_upload(
            api         => 'config/plugin/upload',
            local_file  => $fh->filename,
            remote_file => basename( $fh->filename ),
        );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    is($result->{return_code}, 0, "Uploaded plugin successfully");

    note( "result from upload: ", pp($result) );

    does_plugin_exist( $rest,  0, $fh->filename );

    # Now, import it
    $result = trap {
        $rest->post(
            api => "config/plugin/import",
            params => {
                filename => $fh->filename,
                overwrite  => 1,
            },
        );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    is($result->{success}, 1, "Imported plugin successfully");
    note("result from import: ", pp($result));

    does_plugin_exist( $rest,  1, $fh->filename );

    # Remove the plugin from Opsview
    $result = trap {
        $rest->delete( api => 'config/plugin/' . $fh->filename );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    is($result->{success}, 1, "Deleted plugin successfully");
    note("result from delete ", pp($result));

    # and make sure it has gone
    does_plugin_exist( $rest,  0, $fh->filename );

    # remove the temp file
    unlink( $fh->filename );
}

sub does_plugin_exist {
    my ( $rest, $expected_exists, $plugin_name ) = @_;

    my $message = $expected_exists ? "exists" : "does not exist";
    note( 'Checking plugin "' . $plugin_name . '" '.$message.' in Opsview' );

    my $result = trap {
        $rest->get(
            api    => 'config/plugin',
            params => { 's.name' => $plugin_name, },
        );
    };

    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");

    is( $result->{summary}->{rows},
        $expected_exists,
        'random plugin name "' . $plugin_name . '" '. $message );

    return;
}

done_testing();
