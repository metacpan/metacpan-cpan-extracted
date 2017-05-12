use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

# first do a make distcheck
open(my $ph, '-|', 'make distcheck 2>&1') or die('make failed: '.$!);
while(<$ph>) {
    my $line = $_;
    chomp($line);

    if(   $line =~ m/\/bin\/perl/
       or $line =~ m/: Entering directory/
       or $line =~ m/: Leaving directory/
    ) {
      pass($line);
      next;
    }

    fail($line);
}
close($ph);
ok($? == 0, 'make exited with: '.$?);

# read our manifest file
my $manifest = {};
open(my $fh, '<', 'MANIFEST') or die('open MANIFEST failed: '.$!);
while(<$fh>) {
    my $line = $_;
    chomp($line);
    next if $line =~ m/^#/;
    $manifest->{$line} = 1;
}
close($fh);
ok(scalar keys %{$manifest} >  0, 'read entrys from MANIFEST: '.(scalar keys %{$manifest}));

done_testing();
