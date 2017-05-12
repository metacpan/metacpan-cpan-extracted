# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use IO::CaptureOutput qw(capture);
use PYX::Hist;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = PYX::Hist->new;
my ($stdout, $stderr);
open my $fh, '<', $data_dir->file('ex1.pyx')->s;
capture sub {
	$obj->parse_handler($fh);
} => \$stdout, \$stderr;
is($stdout, <<'END', 'Stdout output.');
[ data ] 2
[ pyx  ] 1
END
close $fh;
is($stderr, '', 'Stderr output.');

# Test.
$obj = PYX::Hist->new;
open $fh, '<', $data_dir->file('ex2.pyx')->s;
eval {
	$obj->parse_handler($fh);
};
close $fh;
is($EVAL_ERROR, "Stack has some elements.\n", 'Stack has some elements.');
clean();

# Test.
$obj = PYX::Hist->new;
open $fh, '<', $data_dir->file('ex3.pyx')->s;
eval {
	$obj->parse_handler($fh);
};
close $fh;
is($EVAL_ERROR, "Bad end of element.\n", 'Bad end of element.');
clean();
