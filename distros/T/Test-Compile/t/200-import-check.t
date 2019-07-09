#!perl -w
use strict;
use warnings;
use Test::More;
use Test::Compile;

plan skip_all => "Test::Exception required for checking exceptions"
    unless eval "use Test::Exception; 1";

my @EXPORTED = qw(
    pm_file_ok
    pl_file_ok

    all_pm_files_ok
    all_pl_files_ok

    all_pm_files
    all_pl_files
);
my @NOTEXPORTED = qw(
    all_files_ok
);

# try to use the methods, despite not exporting them
for my $m (@NOTEXPORTED) {
    is(__PACKAGE__->can($m), undef, "$m not auto-imported");
} 

# now run (inherited) import by hand with specified method
Test::Compile->import('pl_file_ok');

lives_ok ( sub {
    pl_file_ok('t/scripts/subdir/success.pl', 'success.pl compiles');
}, 'pl_file_ok imported correctly');

# finally use the "all" tag to import all methods and check if it worked
Test::Compile->import(':all');
can_ok(__PACKAGE__, @EXPORTED,@NOTEXPORTED);
done_testing();
