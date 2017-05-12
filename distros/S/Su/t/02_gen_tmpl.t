use Test::More;

use lib qw(lib ../lib);

use Su::Process;

BEGIN {
  plan tests => 2;
}

#$Su::Template::DEBUG=1;

$Su::Process::PROCESS_BASE_DIR = "./t";
$Su::Process::PROCESS_DIR      = "test02";

my $fname =
    $Su::Process::PROCESS_BASE_DIR . "/"
  . $Su::Process::PROCESS_DIR . "/"
  . 'MyComp.pm';

unlink $fname if ( -f $fname );

my $ret = generate_proc('MyComp');
like( $ret, qr!/t/test02/MyComp\.pm! );

open my $f, '<',
    $Su::Process::PROCESS_BASE_DIR . "/"
  . $Su::Process::PROCESS_DIR . "/"
  . 'MyComp.pm'
  or die $!;

my $first_line = <$f>;
chomp $first_line;
is( $first_line, "package MyComp;" );

# Test from command line.

