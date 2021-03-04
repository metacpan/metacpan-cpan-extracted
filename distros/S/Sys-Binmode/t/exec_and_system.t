#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Errno;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $e_down = "é";
utf8::downgrade($e_down);

my $e_up = $e_down;
utf8::upgrade($e_up);

my $e_dblenc = $e_down;
utf8::encode($e_dblenc);

{
    my $salt = substr( rand, 1 );

    my $pid = fork or do {
        use Sys::Binmode;

        exec { $^X } $^X, -e => "my \$fh; open \$fh, '>', '$dir/stdout$salt'; print \$fh \$ARGV[0]", '--', "$e_up";
        exit;
    };

    waitpid $pid, 0;

    open my $rfh, '<', "$dir/stdout$salt";
    my $got = do { local $/; <$rfh> };

    is($got, $e_down, 'upgraded sent to exec as expected');
}

# Here to bump up coverage:
{
    my $dir = File::Temp::tempdir( CLEANUP => 1 );

    open my $wfh, '>', "$dir/$e_dblenc";

    use Sys::Binmode;

    # We want this exec to fail, so ignore Perl’s warning about it:
    no warnings 'exec';

    if ( exec { "$dir/$e_up" } "$dir/$e_up" ) {
        fail 'exec should fail here!';
    }
    else {
        is( 0 + $!, Errno::ENOENT, 'exec looks for the right file' );
    }
}

die 'downgraded??' if !utf8::is_utf8($e_up);

{
    my $salt = substr( rand, 1 );

    {
        use Sys::Binmode;

        system { $^X } $^X, -e => "open STDOUT, '>', '$dir/stdout$salt'; print \$ARGV[0]", '--', "$e_up";
    }

    open my $rfh, '<', "$dir/stdout$salt";
    my $got = do { local $/; <$rfh> };

    is($got, $e_down, 'upgraded sent to system as expected');
}

done_testing;

1;
