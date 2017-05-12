#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 8;

use File::Spec;
use File::Temp qw/ tempdir /;
use File::Find;
use Carp qw/ carp /;
use Config;

# TODO: maybe use Test::Script
# TODO more tests/examples


# Clean up the environment
my $old_path = $ENV{PATH};

$ENV{PATH} = '';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

my $test_name = __FILE__;

(my $dist_dir) = (File::Spec->rel2abs($test_name) =~ m{^(.+)$test_name$});

# $dest_dir may not have had the taint adequately scrubbed from it, so
# we'll check to see if it contains some of the files we expect it to

#my $test_libpath = File::Spec->catfile($dist_dir, 't', 'lib');
my $test_libpath = File::Spec->catfile($dist_dir, 'lib');
my $test_data    = File::Spec->catfile($dist_dir, 't', 'data');
my $test_self    = File::Spec->catfile($dist_dir, 'blib', 'script', 'perl-run-end');

ok( -f $test_self, 'perl-run-end file exists');
ok( -x $test_self, 'perl-run-end is executable');

# test bin without require arg
my $env = "PERL5LIB=\$PERL5LIB:$test_libpath";
#warn $env; #print system("$env $test_self 2>&1 >/dev/null");
my $help = qx[$env $test_self 2>&1 >/dev/null];
ok( $help =~ /Full Path to Module is required as an argument/ );
ok( $help =~ /perl-run-end \[options\]/ );

# test valid examples
my $test_mod = File::Spec->catfile($dist_dir, 't', 'data', 'MyModule.pm');
#warn $test_mod;
my $run_ok = qx[$env $test_self $test_mod];
ok('FOOfunction1 calledfunction2 called' eq $run_ok, 'Run MyModule as expected');

### perl -I /Users/dwright/perl/Perl-RunEND/lib  bin/perl-run-end -i /Users/dwright/perl/Perl-RunEND/t/data  /Users/dwright/perl/Perl-RunEND/t/data/My/MyModulePod.pm
$test_mod = File::Spec->catfile($dist_dir, 't', 'data', 'My', 'MyModulePod.pm');
# prove -i switch (passing @INC works)
$run_ok = qx[$env $test_self -i $test_data $test_mod];
my $exp = "test synopsis\nfunction1 called\ntest method definition\nfunction1 called\nfunction2 called\n";
ok( $exp eq $run_ok, 'Run MyModulePod as expected');

my $perldoc = $Config{perlpath};
$perldoc .= $Config{_exe} if $^O ne 'VMS' and $perldoc !~ /$Config{_exe}$/i;
$perldoc .= 'doc'; # warn $perldoc;
$run_ok = qx[$perldoc $test_mod 2>/dev/null]; #warn $run_ok;

# perldoc out format is slightly different on diff platforms, cant really cmp equal
#ok( $exp eq $run_ok, 'Run MyModulePod as expected');

my $not_exp ='# perdoc does not parse this code bu perl-run-end does execute it';
# just prove does not display our executable code
ok( $run_ok !~ /$not_exp/, 'Good, Perdoc not parsing not pod code');

$not_exp = 'test synopsis';
ok( $run_ok !~ /$not_exp/, 'Good, Perdoc not parsing not pod code');

# TODO more tests/examples

