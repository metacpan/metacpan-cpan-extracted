use strict;
use warnings;
use Test::More tests => 2;
use File::Spec;
use IPC::Open2;

my $json_file = File::Spec->catfile( 't', 'data', 'metadata.json' );
open( my $in, '<', $json_file ) or die "Cannot read JSON file $json_file: $!\n";
my $json_data;
my $expected;

{
    local $/ = undef;
    $expected  = <DATA>;
    $json_data = <$in>;
}

close($in);
close(DATA);

my $exp = q{$..run_requires.[1]};
my ( $chld_out, $chld_in );
my @cmd = ( File::Spec->catfile( '.', 'bin', 'psonpath' ), '-exp', $exp );
note( 'Program and parameters: ' . join( ' ', @cmd ) );
my $pid = open2( $chld_out, $chld_in, @cmd );
print $chld_in $json_data;
close($chld_in);

my $result;

{
    local $/ = undef;
    $result = <$chld_out>;
}
close($chld_out);

waitpid( $pid, 0 );
my $exit = $? >> 8;
is( $exit,   0,         "child exit code is OK" );
is( $result, $expected, 'psonpath generates the expected output' );

__DATA__;
{
    requires   [
        [0] "botocore==1.12.191",
        [1] "colorama>=0.2.5,<=0.3.9",
        [2] "docutils>=0.10",
        [3] "rsa>=3.1.2,<=3.5.0",
        [4] "s3transfer>=0.2.0,<0.3.0"
    ]
}
