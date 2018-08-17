use strict;
use warnings;
use Test::More;
BEGIN { delete $ENV{PKG_CONFIG_PATH} }
use PkgConfig;
use Config;
use File::Temp qw( tempdir );


plan skip_all => "Test only for MSWin32" unless $^O eq 'MSWin32';
plan skip_all => "Test only for strawberry MSWin32" unless $Config{myuname} =~ /strawberry-perl/;
plan skip_all => "Test needs pp utility to be installed" unless eval { require pp };

plan tests => 3;

my $dir = tempdir( CLEANUP => 1);
my $exe_file = "$dir/a.exe";
my $test_text = "executable worked";

#  avoid shell quoting issues
$exe_file =~ s|\\|/|g;


$ENV{PP_OPTS} = qq{-e "use PkgConfig; print qq|$test_text|" -o $exe_file};

ok (pp->go(), 'ran the pp call');

ok (-x $exe_file, "generated executable file $exe_file");

my $result = `$exe_file`;

is ($result, $test_text, "PAR packed executable includes functional PkgConfig");

