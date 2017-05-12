use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd;
my $cwd = getcwd;
use File::Temp qw/ tempdir /;

my $d = tempdir(UNLINK => 1);
chdir($d) or die;
open(my $mfh, ">", "Makefile.PL") or die;
mkdir "lib" or die;
open(my $modfh, ">", File::Spec->catfile("lib", "TestModule.pm")) or die;

print $mfh q{
#!/usr/bin/env perl
use inc::Module::Install;
all_from 'lib/TestModule.pm';
authority 'BOBTFISH';
WriteAll();
};

print $modfh q{
package TestModule;
use strict;
use warnings;

$VERSION = "0.1";

sub foo { "bar" }

1;

};

close($mfh) or die;
close($modfh) or die;

chmod 0755, "Makefile.PL" or die;
system("PERL5LIB=$cwd/lib:\$PERL5LIB /usr/bin/env perl Makefile.PL") and die;

use YAML;
my $data = YAML::LoadFile("META.yml");
is $data->{x_authority}, 'BOBTFISH';

done_testing;

