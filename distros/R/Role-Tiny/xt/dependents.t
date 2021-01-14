use strict;
use warnings;

use Test::More;
use IPC::Open3;
use File::Spec;
use Cwd qw(abs_path);
use Config ();
use File::Temp;
use Cwd ();
use File::Basename ();
use Data::Dumper ();
use Getopt::Long qw(:config gnu_getopt);

my $v = 0;
sub cpan {
  my $cmd = shift;
  open my $in, '<', File::Spec->devnull
    or die "can't open devnull: $!";
  my $pid = open3 $in, my $out, undef, $^X, '-MCPAN', '-e', "$cmd(\@ARGV)", @_;
  my $output = '';
  while (my $line = <$out>) {
    $output .= $line;
    if ($v || $line =~ /^Running / || $line =~ / --( NOT)? OK$/) {
      diag $line;
    }
  }
  close $out;
  waitpid $pid, 0;
  my $status = $?;
  return wantarray ? ($output, $status) : $output;
}

my $prefs = do {
  my $xt = sub {
    my ($dist, $extra) = @_;
    my $config = {
      %$extra,
      match => {
        distribution => $dist,
        env => { MOO_XT => 1 },
      },
      test => {
        args => [ 'TEST_FILES=t/*.t xt/*.t' ],
      },
    };
    return $config;
  };
  {
    'Moo' => [
      {
        match => { distribution => '\\bMoo-0\\.009001\\b' },
        patches => [
          'Moo-isa-assign.patch',
          'Moo-sort-sub-quote.patch'
        ],
      },
      {
        match => { distribution => '\\bMoo-0\\.00900[2-7]\\b' },
        patches => [
          'Moo-sort-sub-quote.patch'
        ],
      },
      {
        match => { distribution => '\\bMoo-0\\.009_?(00[8-9]|01[0-4])\\b' },
      },
      $xt->('\\bMoo-0\\.(009_?01[5-9]|091_?00[012])', {
        depends => {
          requires => {
            'MooX::Types::MooseLike::Base' => 0,
            'MooX::Types::MooseLike::Numeric' => 0,
            'Moose' => 0,
            'MooseX::Types::Common::Numeric' => 0
          }
        },
      }),
      $xt->('\\bMoo-0\\.091003', {
        depends => {
          requires => {
            'MooX::Types::MooseLike::Base' => 0,
            'MooX::Types::MooseLike::Numeric' => 0,
            'Moose' => 0,
            'MooseX::Types::Common::Numeric' => 0,
            'namespace::autoclean' => 0
          }
        },
      }),
      $xt->('\\bMoo-(0\\.091_?(00[4-9]|01[0-4])|1.00[012]|1.003000)', {
        depends => {
          requires => {
            'MooX::Types::MooseLike::Base' => 0,
            'MooX::Types::MooseLike::Numeric' => 0,
            'Moose' => 0,
            'MooseX::Types::Common::Numeric' => 0,
            'namespace::autoclean' => 0,
            'namespace::clean' => 0
          }
        },
      }),
      $xt->('\\bMoo-1.0', {
        depends => {
          requires => {
            'Moose' => 0,
            'MooseX::Types::Common::Numeric' => 0,
            'Mouse' => 0,
            'namespace::autoclean' => 0,
            'namespace::clean' => 0
          }
        },
      }),
      $xt->('\\bMoo-(1|2.00[0-3])', {
        depends => {
          requires => {
            'Class::Tiny' => 0,
            'Moose' => 0,
            'MooseX::Types::Common::Numeric' => 0,
            'Mouse' => 0,
            'Type::Tiny' => 0,
            'namespace::autoclean' => 0,
            'namespace::clean' => 0
          }
        },
      }),
      $xt->('\\bMoo-v?[0-9]', {
        pl => {
          env => { EXTENDED_TESTING => 1 },
        },
      }),
    ],
    'Role-Tiny' => [
      {
        match => { distribution => "\\bRole-Tiny-\\b" },
        install => { commandline => 'echo "skipped"' },
      },
    ],
  };
};

GetOptions(
  'verbose|v' => sub { $v++ },
  'quiet|q'   => sub { $v-- },
  'doit'      => \(my $doit = $ENV{EXTENDED_TESTING}),
) or die 'Bad parameters!';

$v = 0
  if $v < 0;

my @dists = @ARGV;
if (!@dists && $doit) {
  @dists = qw(
    MSTROUT/Moo-0.009001.tar.gz
    MSTROUT/Moo-0.091011.tar.gz
    MSTROUT/Moo-1.000000.tar.gz
    MSTROUT/Moo-1.000008.tar.gz
    HAARG/Moo-1.007000.tar.gz
    HAARG/Moo-2.000000.tar.gz
    HAARG/Moo-2.001000.tar.gz
    Moo
    namespace::autoclean
    Dancer2
    MooX::Options
    MooX::ClassAttribute
  );
}

plan skip_all => 'Set EXTENDED_TESTING to enable dependents testing'
  if !@dists;

plan tests => scalar @dists;

my $path_sep = $Config::Config{path_sep};
my $archname = $Config::Config{archname};
my $version = $Config::Config{version};

my $temp_home = File::Temp::tempdir('Role-Tiny-XXXXXX', TMPDIR => 1, CLEANUP => 1);

my $local_lib = "$temp_home/perl5";
mkdir "$local_lib";
mkdir "$local_lib/bin";
mkdir "$local_lib/lib";
mkdir "$local_lib/lib/perl5";
mkdir "$local_lib/lib/perl5/$version";
mkdir "$local_lib/lib/perl5/$version/$archname";
mkdir "$local_lib/lib/perl5/$archname";
mkdir "$local_lib/man";
mkdir "$local_lib/man1";
mkdir "$local_lib/man3";

my @extra_libs = do {
  my @libs = `"$^X" -le"print for \@INC"`;
  chomp @libs;
  my %libs; @libs{@libs} = ();
  map { Cwd::abs_path($_) } grep { !exists $libs{$_} } @INC;
};

my $cpan_home = "$temp_home/.cpan";
mkdir $cpan_home;
mkdir "$cpan_home/CPAN";
my $prefs_dir = "$cpan_home/prefs";
mkdir $prefs_dir;

my $patch_dir = Cwd::realpath(File::Basename::dirname(__FILE__) . '/dependents');

delete $ENV{HARNESS_PERL_SWITCHES};
delete $ENV{AUTHOR_TESTING};
delete $ENV{EXTENDED_TESTING};
delete $ENV{RELEASE_TESTING};
$ENV{NONINTERACTIVE_TESTING}  = 1;
$ENV{PERL_MM_USE_DEFAULT}     = 1;
$ENV{HOME}                    = $temp_home;
$ENV{PERL5LIB}                = join $path_sep, "$local_lib/lib/perl5", @extra_libs, $ENV{PERL5LIB}||();
$ENV{PERL_MM_OPT}             = qq{INSTALL_BASE="$local_lib"};
$ENV{PERL_MB_OPT}             = qq{--install_base "$local_lib"};
$ENV{PERL_LOCAL_LIB_ROOT}     = join $path_sep, $local_lib, $ENV{PERL_LOCAL_LIB_ROOT}||();

my $config_file = "$cpan_home/CPAN/MyConfig.pm";
{
  open my $fh, '>', $config_file
    or die;

  my $config = do {
    local $Data::Dumper::Terse = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    Data::Dumper->Dump([{
      allow_installing_module_downgrades  => 'yes',
      allow_installing_outdated_dists     => 'yes',
      auto_commit                         => 0,
      build_requires_install_policy       => 'yes',
      connect_to_internet_ok              => 1,
      cpan_home                           => $cpan_home,
      inhibit_startup_message             => 1,
      prefs_dir                           => $prefs_dir,
      patches_dir                         => $patch_dir,
      prerequisites_policy                => 'follow',
      recommends_policy                   => 0,
      suggests_policy                     => 0,
      urllist                             => [ 'http://cpan.metacpan.org/' ],
      use_sqlite                          => 0,
    }], ['$CPAN::Config']);
  };
  print { $fh } $config . "1;\n__END__\n";
  close $fh;
}

cpan('CPAN::Shell->o', 'conf');

{

  local $CPAN::Config;
  require $config_file;

  my $yaml = $CPAN::Config->{yaml_module};
  if ($yaml) {
    (my $mod = "$yaml.pm") =~ s{::}{/}g;
    eval { require $mod }
      or undef $yaml;
  }

  for my $dist (keys %$prefs) {
    my $prefs = $prefs->{$dist};

    if ($yaml) {
      open my $fh, '>', "$prefs_dir/$dist.yml";
      print { $fh } $yaml->can('Dump')->(@$prefs);
      close $fh;
    }

    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    open my $fh, '>', "$prefs_dir/$dist.dd";
    print { $fh } Data::Dumper::Dumper(@$prefs);
    close $fh;
  }
}

my $ext = qr{\.(?:t(?:ar\.)?(?:bz2|xz|gz)|tar|zip)};
for my $dist (@dists) {
  my $name = $dist;
  $name =~ s{$ext$}{}
    if $name =~ m{/};

  note "Testing $dist ...";

  local $ENV{MOO_XT} = $dist =~ /\bMoo\b/ ? '1' : '0';

  my $prereq_output = cpan('notest', 'install', $dist);

  # in case Role::Tiny got installed somehow
  unlink "$local_lib/lib/perl5/Role/Tiny.pm";
  unlink "$local_lib/lib/perl5/Role/Tiny/With.pm";

  my $test_output = cpan('test', $dist);

  if ($dist !~ m{/}) {
    $test_output =~ m{^Configuring (.)/(\1.)/(\2.*)$ext\s}m
      and $name = "$3 (latest)";
  }

  my $passed = $test_output =~ /--\s*OK\s*\z/ && $test_output !~ /--\s*NOT\s+OK\s*\z/;
  ok $passed, "$name passed tests";
  diag "$prereq_output$test_output"
    if !$passed && !$v;
}

done_testing;

__DATA__
