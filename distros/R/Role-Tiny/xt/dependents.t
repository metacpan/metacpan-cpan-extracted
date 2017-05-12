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
) {
  my $name = $dist;
  $name =~ s{$ext$}{}
    if $name =~ m{/};
  my $pid = open3 $in, my $out, undef, $^X, '-MCPAN', '-e', 'test @ARGV', $dist;
  my $output = do { local $/; <$out> };
  close $out;
  waitpid $pid, 0;

  my $status = $?;

  if ($dist !~ m{/}) {
    $output =~ m{^Configuring (.)/(\1.)/(\2.*)$ext\s}m
      and $name = "$3 (latest)";
  }

  like $output, qr/--\s*OK\s*\z/,
    "$name passed tests";
}

done_testing;
