use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Try::Tiny;
use Capture::Tiny ':all';

use File::Spec;
my $fileName = File::Spec->catfile('t','declare','10_help.t');

my $out = capture_stderr {
    try {
        @ARGV = qw(--help);
        foo();
    }
};

is $out, <<"EOS", 'help message';
Usage: $fileName

Options:
  -h, --help    Show help             
  -p, --pi, -q                        
  -r, --radius  Radius of circle      

EOS

done_testing;


sub foo {
    opts my $pi => { isa => 'Num', alias => 'q' },
         my $radius => { isa => 'Num', comment => 'radius of circle' };
    is $pi, 3.14;
}
