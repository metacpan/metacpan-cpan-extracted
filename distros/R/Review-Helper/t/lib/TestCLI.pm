package TestCLI;
use v5.36;

use Exporter 'import';
our @EXPORT_OK = qw/cli/;

use Capture::Tiny qw/capture/;
use Cwd qw/getcwd/;
use Review::Helper::CLI;

# Run the CLI in $dir and return (exit, stdout, stderr).
sub cli($dir, @args) {
    my $orig = getcwd();
    chdir($dir) or die "chdir $dir: $!";

    my ($out, $err, $exit) = capture { Review::Helper::CLI->run(@args) };

    chdir($orig) or die "chdir $orig: $!";
    return ($exit, $out, $err);
}

1;
