use strict;
use warnings;
use Test::More
  !($ENV{EXTENDED_TESTING} || grep $_ eq '--doit', @ARGV)
    ? (skip_all => 'Set EXTENDED_TESTING to enable dependents testing')
    : ();
use IPC::Open3;
use File::Spec;
use Cwd qw(abs_path);
use Config;

# this won't run by default anyway, so just display the full content so Travis
# doesn't abort due to lack of output.
my $v = 1; # grep /\A(?:-v|--verbose)\z/, @ARGV;

delete $ENV{AUTHOR_TESTING};
delete $ENV{EXTENDED_TESTING};
delete $ENV{RELEASE_TESTING};
$ENV{NONINTERACTIVE_TESTING} = 1;
$ENV{PERL_MM_USE_DEFAULT} = 1;
delete $ENV{HARNESS_PERL_SWITCHES};

# tests in Moo-0.009002 are sensitive to hash key order.  force one that
# works, since we still want to run the rest of the tests.
$ENV{PERL_HASH_SEED} = 0;
$ENV{PERL_PERTURB_KEYS} = 0;

my @extra_libs = do {
  my @libs = `"$^X" -le"print for \@INC"`;
  chomp @libs;
  my %libs; @libs{@libs} = ();
  map { Cwd::abs_path($_) } grep { !exists $libs{$_} } @INC;
};
$ENV{PERL5LIB} = join($Config{path_sep}, @extra_libs, $ENV{PERL5LIB}||());

open my $in, '<', File::Spec->devnull
  or die "can't open devnull: $!";

my $ext = qr{\.(?:t(?:ar\.)?(?:bz2|xz|gz)|tar|zip)};
for my $dist (
  'MSTROUT/Moo-0.009002.tar.gz', # earliest working version
  'MSTROUT/Moo-1.000000.tar.gz',
  'MSTROUT/Moo-1.000008.tar.gz',
  'HAARG/Moo-1.007000.tar.gz',
  'HAARG/Moo-2.000000.tar.gz',
  'HAARG/Moo-2.001000.tar.gz',
  'Moo',
  'namespace::autoclean',
  'Dancer2',
) {
  note "Testing $dist ...";

  my $name = $dist;
  $name =~ s{$ext$}{}
    if $name =~ m{/};
  my $pid = open3 $in, my $out, undef, $^X, '-MCPAN', '-e', 'test @ARGV', $dist;
  my $output = '';
  while (my $line = <$out>) {
    $output .= $line;
    diag $line
      if $v;
  }
  close $out;
  waitpid $pid, 0;

  my $status = $?;

  if ($dist !~ m{/}) {
    $output =~ m{^Configuring (.)/(\1.)/(\2.*)$ext\s}m
      and $name = "$3 (latest)";
  }

  ok $output =~ /--\s*OK\s*\z/ && $output !~ /--\s*NOT\s+OK\s*\z/,
    "$name passed tests"
    or (!$v and diag $output);
}

done_testing;
