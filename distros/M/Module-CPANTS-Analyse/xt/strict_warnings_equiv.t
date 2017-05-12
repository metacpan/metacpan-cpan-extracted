use strict;
use warnings;
use FindBin;
use File::Path;
use Test::More;

BEGIN {
  plan skip_all => "This is an author test" unless $ENV{AUTHOR_TESTING};
  plan skip_all => "requires WorePAN" unless eval { require WorePAN; WorePAN->VERSION(0.04) };
  plan skip_all => "This doesn't run well under Windows" if $^O eq 'MSWin32';
}

use Module::CPANTS::Kwalitee::Uses;

my $pid = $$;
my $tempdir = "$FindBin::Bin/tmplib/";
mkpath $tempdir unless -d $tempdir;
END { rmtree $tempdir if $pid eq $$ && -d $tempdir };

my %map = (
  'Catmandu::Sane' => 'Catmandu',
  'Mojo::Base' => 'Mojolicious',
  'perl5i::1' => 'perl5i',
  'perl5i::2' => 'perl5i',
  'perl5i::latest' => 'perl5i',
);

my %flag_to_enable = (
  'Mojo::Base' => '-base',
  'Spiffy' => '-Base',
);

for my $module (@Module::CPANTS::Kwalitee::Uses::STRICT_EQUIV) {
  my $res = test($module);
  unless ($res) {
    note "SKIP $module";
    next;
  }

  ok $res->{strict}, "$module enforces strict";
  ok !$res->{warnings}, "$module does not enforce warnings";
  note;
}

for my $module (@Module::CPANTS::Kwalitee::Uses::WARNINGS_EQUIV) {
  next if $module eq 'warnings::compat';
  my $res = test($module);
  unless ($res) {
    note "SKIP $module";
    next;
  }

  ok !$res->{strict}, "$module does not enforce strict";
  ok $res->{warnings}, "$module enforces warnings";
  note;
}

for my $module (@Module::CPANTS::Kwalitee::Uses::STRICT_WARNINGS_EQUIV) {
  my $res = test($module);
  unless ($res) {
    note "SKIP $module";
    next;
  }

  ok $res->{strict}, "$module enforces strict";
  ok $res->{warnings}, "$module enforce warnings";
  note;
}

sub test {
  my $module = shift;
  my $dist = $map{$module} || $module;
  $dist =~ s|::|-|g;

  local $Parse::PMFile::ALLOW_DEV_VERSION = 1;
  my $worepan = WorePAN->new(
    root => "$FindBin::Bin/tmp/",
    dists => {$dist => 0},
    use_backpan => 0,
    no_network => 0,
    verbose => 0,
    cleanup => 1,
  );
  my ($version, $file) = $worepan->look_for($module);
  $file ||= $module;

  system("cpanm -nq -l $tempdir $file");

  my $res = {};

  {
    open my $fh, '>', 'strict_test.pl' or die $!;
    my $flag = $flag_to_enable{$module} || '';
    print $fh <<"TEST_END";
package #
  Test::CPANTS::StrictWarningsEquiv;
no warnings;
my \$default_warning_bits;
BEGIN { \$default_warning_bits = \${^WARNING_BITS}; }
use local::lib "$tempdir";
use $module $flag;
BEGIN {
print "module: $module\n";
print "strict: ", (\$^H & (0x00000002|0x00000200|0x00000400)) ? 1 : 0, "\n";
print "warnings: ", (\${^WARNING_BITS} ne \$default_warning_bits ? 1 : 0), "\n";
}
TEST_END
    close $fh;

    my $output = `$^X strict_test.pl`;
    return if $output =~ /Can't locate/;
    ($res->{strict}) = $output =~ /strict: ([01])/;
    ($res->{warnings}) = $output =~ /warnings: ([01])/;
  }
  $res;
}

done_testing;
