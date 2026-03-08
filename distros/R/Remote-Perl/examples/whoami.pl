# Run with: remperl HOST examples/whoami.pl
# Prints identity, working directory, Perl version, and @INC on the remote side.
use v5.36;
use Cwd qw(getcwd);

my $uid  = $<;
my $user = getpwuid($uid) // '(unknown)';
my $cwd  = getcwd();
my $home = (getpwuid($uid))[7] // $ENV{HOME} // '(unknown)';

my $perl_ver  = sprintf('%vd', $^V);
my $perl_path = $^X;

print "uid   $uid\n";
print "user  $user\n";
print "cwd   $cwd\n";
print "home  $home\n";
print "perl  $perl_ver\n";
print "perl  $perl_path\n";
print "INC   $_\n" for @INC;
