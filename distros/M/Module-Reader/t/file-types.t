use strict;
use warnings;

use Test::More 0.88;
use Module::Reader;
use File::Temp;
use File::Spec;
use Cwd;

my $dir = File::Temp->newdir('module-reader-XXXXXX', TMPDIR => 1);

my @inc;

my %types = (
  file => sub {
    open my $fh, '>', "$_[0]"
      or die "can't create file $_[0]: $!";
    print { $fh } "1;";
    close $fh;
  },
  dir => sub {
    mkdir $_[0];
  },
);

if (eval { symlink 'target', "$dir/link-test" }) {
  $types{link} = sub {
    my ($fh, $file) = File::Temp::tempfile('linked-file-XXXXXX', DIR => $dir, UNLINK => 0);
    print { $fh } "1;";
    close $fh;
    symlink $file, $_[0];
  };
  $types{badlink} = sub {
    symlink "nonexistant", $_[0];
  };
}

# root will bypass permissions, but double check that our chmod is working
if ($> != 0) {
  my $unreadable = sub {
    $types{file}->($_[0]);
    chmod 0000, $_[0];
  };

  $unreadable->("$dir/unreadable-file");
  if (!open my $fh, '<', "$dir/unreadable-file") {
    $types{unreadable} = $unreadable;
  }
}

my %type_act = (
  file        => 'pass',
  dir         => 'skip',
  link        => 'pass',
  badlink     => 'skip',
  unreadable  => 'error',
);

my $fallback = sub {
  my $once;
  sub {
    return 0 if $once++;
    $_ .= '1;';
    return 1;
  };
};

for my $type (keys %types) {
  mkdir "$dir/$type";
  $types{$type}->("$dir/$type/TestModule.pm");
  $types{file}->("$dir/$type/TestModule.pmc");
}

for my $type_1 (sort keys %types) {
  my $inc_1 = "$dir/$type_1";
  for my $type_2 (sort keys %types) {
    my $inc_2 = "$dir/$type_2";

    my $reader = Module::Reader->new(inc => [$inc_1, $inc_2, $fallback], pmc => 0, abort_on_eacces => 1);
    my $found = eval { $reader->module('TestModule') };

    my ($want)
      = map +($type_act{$_} eq 'pass' ? $_ : $type_act{$_}),
      grep $type_act{$_} ne 'skip',
      $type_1, $type_2;
    $want ||= 'none';

    my $got
      = !defined $found       ? 'error'
      : ref $found->inc_entry ? 'none'
      : $found->disk_file =~ m{^\Q$dir\E/(.*)/TestModule\.pm(c?)$} ? ($1.($2?' pmc':''))
      : 'unknown';

    is $got, $want, "search of $type_1, $type_2 found $want";
  }
}

my $cwd = Cwd::cwd;
END { chdir $cwd }
for my $type (sort keys %types) {
  for my $pmc_type (sort keys %types) {
    my $inc = "$dir/$type/$pmc_type";
    mkdir $inc;
    chdir $inc;
    $types{$type}->("$inc/TestModule.pm");
    $types{$pmc_type}->("$inc/TestModule.pmc");

    my $want
      = $type_act{$pmc_type} eq 'pass' ? 'pmc'
      : $type_act{$type}     eq 'skip' ? 'none'
      : $type_act{$type}     eq 'pass' ? 'pm'
                                       : 'error';

    for my $read_opts (
      ['normal', {
        inc => [$inc, $fallback],
        pmc => 1,
        abort_on_eacces => 1,
      }, 'TestModule.pm'],
      ['found', {
        found => { 'TestModule.pm' => "$inc/TestModule.pm" },
        inc => [$fallback],
        pmc => 1,
        abort_on_eacces => 1,
      }, 'TestModule.pm'],
      ['relative', {
        inc => [$fallback],
        pmc => 1,
        abort_on_eacces => 1,
      }, './TestModule.pm', $inc],
    ) {
      my ($name, $opts, $file, $chdir) = @$read_opts;
      chdir $chdir
        if defined $chdir;
      my $reader = Module::Reader->new(%$opts);
      my $found = eval { $reader->file($file) };
      my $error = $@;
      my $want = $want eq 'none' && $file =~ /^\./ ? 'error' : $want;

      my $got
        = !defined $found       ? 'error'
        : ref $found->inc_entry ? 'none'
        : $found->is_pmc        ? 'pmc'
                                : 'pm';

      my $ok = is $got, $want, "$name search of $type with $pmc_type pmc found $want";
      if ($got eq 'error') {
        if ($ok) {
          note "Got error: ".$error;
        }
        else {
          diag "Got error: ".$error;
        }
      }
      chdir $cwd;
    }
  }
}

done_testing;
