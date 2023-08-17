package Suck::Huggingface;

## ABSTRACT: Clone huggingface repos and then download their models

use strict;
use warnings;
use v5.10.0;  # provides "say" and "state"

use JSON::MaybeXS;
use File::Valet;
use Time::HiRes;
use Time::TAI::Simple;

our $VERSION = '1.00';

sub new {
    my ($class, %opt_hr) = @_;
    my $self = {
        opt_hr   => \%opt_hr,
        conf_hr  => {},
        ok       => 'OK',
        ex       => undef,  # stash caught exceptions here
        n_err    => 0,
        n_warn   => 0,
        err      => '',
        err_ar   => [],
        project_name => 'suck-huggingface',
        trace_ar     => [sprintf('SKH:%08X', int(rand() * 0xFFFFFFFF))],
        js_or    => JSON::MaybeXS->new(ascii => 1, allow_nonref => 1, space_after => 1)
    };
    bless ($self, $class);

    # convert keys of form "some-parameter" to "some_parameter":
    foreach my $k0 (keys %{$self->{opt_hr}}) {
        my $k1 = join('_', split(/-/, $k0));
        next if ($k0 eq $k1);
        $self->{opt_hr}->{$k1} = $self->{opt_hr}->{$k0};
        delete $self->{opt_hr}->{$k0};
    }

    my $home_dir = find_home() // '.';
    my $path_env = $self->opt('path_env', $ENV{PATH} // '$home_dir/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/sbin');
    $self->{path_ar} = [split(/:/, $path_env)];
    $self->{wget_bin} = $self->opt('wget') // find_bin('wget', @{$self->{path_ar}});
    die "cannot find wget executable! PATH=$path_env" unless (defined($self->{wget_bin}));

    return $self;
}

sub _dissect_repo_url {
    my ($self, $repo_url) = @_;
    $repo_url = $1 if ($repo_url =~ /(.+?)\.git$/);  # will use this much later for $dl_url
    $repo_url = $1 if ($repo_url =~ /(.+?)\/$/);

    return $self->err("skipping docs repo, unsupported", $repo_url) if ($repo_url =~ /^https:\/\/[^\/]+\/docs\//);

    # problem: datasets URLs are ambiguous!
    #   Valid repo: https://../datasets/username/reponame
    #   Also valid: https://../datasets/reponame
    # .. but not always.  Sometimes the username is *required!*
    # Will match the longer of the two cases, and trim it off if the last term
    # matches something unlikely to be a repo name (blob, tree, discussions).

    if ($repo_url =~ /^(https:\/\/[^\/]+\/datasets\/[^\/]+\/[^\/]+)/) {
      # longer case of dataset
      $repo_url = $1;
    } elsif ($repo_url =~ /^(https:\/\/[^\/]+\/datasets\/[^\/]+)/) {
      # shorter case of dataset
      $repo_url = $1;
    } elsif ($repo_url =~ /^(https:\/\/[^\/]+\/[^\/]+\/[^\/]+)/) {
      # expected case: model repo
      $repo_url = $1;
    }

    # above logic was optimistic; trim off non-repo parts:
    $repo_url = $1 if ($repo_url =~ /^(https:.+?)\/(blob|tree|discussions)$/);
    $repo_url = $1 if ($repo_url =~ /^(https:.+?)\/(blob|tree|discussions)\//);

    return $self->err("skipping unparseable repo_url", $repo_url) unless ($repo_url =~ /\/([^\/]+)$/);
    my $repo_dir = "$1.git";
    my $git_url = "$repo_url.git";

    return $self->ok($repo_url, $git_url, $repo_dir);
}

sub _clone_repo {
    my ($self, $git_url, $repo_dir) = @_;
    if (-e $repo_dir) {
      $self->dbg("already got repo, will not clone", $repo_dir, 4);
    } else {
      my $git_options = "";
      $git_options .= "-q " unless($self->opt('v'));
      $self->dbg("cloning repo", $git_url, $git_options, $repo_dir, 4);
      system("git clone $git_options '$git_url' '$repo_dir'") unless ($self->{testing});
      $self->dbg("cloned repo", $git_url, $repo_dir, 4);
    }
    return $self->err("unable to clone repo, skipping", $git_url, $repo_dir) unless (-e $repo_dir);
    return $self->ok();
}

sub _scan_for_external_downloads {
    my ($self, $git_url, $repo_dir) = @_;
    my $total_sz = 0;
    my @to_dl;
    $self->info("scanning for external downloads", $repo_dir);
    my $exclude_csv = $self->opt('exclude', '');  # comma-delimited list of filename substrings for files to exclude
    my @excludes;
    @excludes = split(/,/, $exclude_csv) if ($exclude_csv);
    my $sz_threshold = $self->opt('too_big', 300);  # external downloads are small, usually fewer than 200 bytes
    for my $gf (glob("$repo_dir/*")) {
      $self->dbg("found file", $gf, 7);
      next unless ($gf =~ /^$repo_dir\/(.+)/);
      my $f = $1;
      $self->dbg("reduced file", $f, 7);
      next if ($f =~ /^\./);
      $self->dbg("not a dot-file", $f, 7);
      next if (-d $gf);
      $self->dbg("not a directory", $f, 7);
      my $file_size = -s $gf;
      $self->dbg("file size", $f, $file_size // '<undef>', 7);
      next if (!$file_size || $file_size > $sz_threshold);
      my ($excl, $match) = $self->exclude_file($f, \@excludes);
      $self->dbg("checked exclusions for match", $f, $excl, $match, 5);
      next if ($excl);
      $self->dbg("squinting at small file", $repo_dir, $f, 5);
      my $x = File::Valet::rd_f($gf);
      unless (defined $x) {
        $self->err("failed to open small file, skipping", $f, $gf, $File::Valet::ERROR);
        next;
      }
      next unless ($x =~ /^\s*version\s+([^\s]+)\s*[\r\n]+\s*oid\s+(\w+):([^\s]+)\s*[\r\n]+\s*size\s+(\d+)/);
      my ($ver, $oid_alg, $oid_digest, $sz) = ($1, $2, $3, $4);
      $self->dbg("found external download", $repo_dir, $f, {ver => $ver, oid_alg => $oid_alg, oid_dig => $oid_digest, sz => $sz});
      $total_sz += $sz;
      push @to_dl, {f => $f, oid_alg => $oid_alg, oid_dig => $oid_digest, sz => $sz};
    }
    return $self->ok($total_sz, \@to_dl);
}

# ($excl, $match) = exclude_file($f, \@excludes);
sub exclude_file {
    my ($self, $f, $ex_ar) = @_;
    for my $x (@$ex_ar) {
      return (1, $x) if (index($f, $x) != -1);
    }
    return (0, '');
}


sub _download_files {
    my ($self, $repo_url, $git_url, $repo_dir, $to_dl_ar) = @_;
    my $dl_url = "$repo_url/resolve/main";

    my $wget_opts = "";
    my $rl = $self->opt('limit_rate') // $self->opt('rate_limit');
    my $un = $self->opt('user') // $self->opt('username');
    my $pw = $self->opt('pw') // $self->opt('password');
    $wget_opts .= "-q " unless ($self->opt('v', 0));
    $wget_opts .= "--limit-rate=$rl " if ($rl && $rl =~ /^[\d\.]+\w?$/);  # eg: "2.5m" or "500k"
    $wget_opts .= "--user=$un " if (defined $un);
    $wget_opts .= "--password=$pw " if (defined $pw);
    my $n_retries = $self->opt('retries', 1000);
    $n_retries = 1000 if ($n_retries < 1);
    $wget_opts .= "--tries=$n_retries ";

    my $mk_orig = 1;
    for my $f_hr (@$to_dl_ar) {
      my $f = $f_hr->{f};
      if ($f =~ /(.+?)\.orig$/) {
        # left over from a previous attempt to download from this repo.
        # if the target file already exists, skip.
        # otherwise, download it.
        my $tf = $1;
        if (-e "$repo_dir/$tf") {
          $self->info("file already local, skipping", {tf => $tf, f_hr => $f_hr});
          next;
        }
        $f = $tf;
      }
      rename("$repo_dir/$f", "$repo_dir/$f.orig") if ($mk_orig);  # chicken
      $self->info("downloading file", $f_hr);
      my $url = "$dl_url/$f";
      my $wget_bin = $self->{wget_bin} // "wget";
      my $cmd = "cd $repo_dir && $wget_bin $wget_opts '$url'";
      $self->dbg("wget cmd", $cmd, 6);
      my $tm0 = Time::HiRes::time();
      system($cmd) unless ($self->{testing});
      my $dur = Time::HiRes::time() - $tm0;
      my $kbps = int(($f_hr->{sz} // 0) / $dur + 0.5) / 1024;
      $kbps = $1 if ($kbps + 0.0005 =~ /^(\d+\.\d{3})/);
      $self->dbg("wget done", {duration => $dur, kbps => $kbps}, 6);;
      # zzapp -- TO-DO: check against digest and re-download on mismatch
    }
    return $self->ok();
}

sub suck {
    my ($self, $repo_url_p, $opt_hr) = @_;

    my($ok, @errs) = $self->_dissect_repo_url($repo_url_p);
    return ($ok, @errs) unless (is_ok($ok));
    my ($repo_url, $git_url, $repo_dir) = @errs;

    $self->info("contemplating repo", $git_url, $repo_dir);

    ($ok, @errs) = $self->_clone_repo($git_url, $repo_dir);
    return ($ok, @errs) unless (is_ok($ok));

    ($ok, @errs) = $self->_scan_for_external_downloads($git_url, $repo_dir);
    return ($ok, @errs) unless (is_ok($ok));
    my ($total_sz, $to_dl_ar) = @errs;

    my $n_dl = @$to_dl_ar;
    if (!$n_dl) {
      $self->dbg("found nothing to download", $repo_dir, 4);
      return $self->ok(0, 0);
    }
    $self->dbg("found stuff to download", {n_dl => $n_dl, total_sz => $total_sz}, 4);

    ($ok, @errs) = $self->_download_files($repo_url, $git_url, $repo_dir, $to_dl_ar);
    return ($ok, @errs) unless (is_ok($ok));
    $self->info("done downloading files for this repo", {n_downloaded => $n_dl, total_size_bytes => $total_sz});

    return $self->ok($n_dl, $total_sz);
}

sub safely_to_json {
    my ($self, $r) = @_;
    my $js = eval { $self->{js_or}->encode($r); };
    $self->{ex} = $@ unless(defined($js));
    return $js;
}

sub safely_from_json {
    my ($self, $js) = @_;
    my $r = eval { $self->{js_or}->decode($js); };
    $self->{ex} = $@ unless(defined($r));
    return $r;
}

sub most_similar {
  my ($self, $thing, $ar, $opt_hr) = @_;
  my $best_match = '';
  my $best_score = $self->opt('min_score', 0, $opt_hr);
  for my $x (@$ar) {
    my $score = similarity($thing, $x);
    next unless($score >= $best_score);
    $best_score = $score;
    $best_match = $x;
  }
  return ($best_match, $best_score) if ($self->opt('best_match_and_score', 0, $opt_hr)); # for testing, mostly
  return $best_match;
}

sub opt {
    my ($self, $name, $default_value, $alt_hr) = @_;
    $alt_hr //= {};
    return $self->{opt_hr}->{$name} // $self->{conf_hr}->{$name} // $alt_hr->{$name} // $default_value;
}

# approximates python's "in" operator, because ~~ is unsane:
sub in {
    my $v = shift @_;
    return 0 unless (@_ && defined($_[0]));
    if (ref($_[0]) eq 'ARRAY') {
        foreach my $x (@{$_[0]}) { return 1 if defined($x) && $x eq $v; }
    } else {
        foreach my $x (@_) { return 1 if defined($x) && $x eq $v; }
    }
    return 0;
}

sub stack_trace {
  my $self = shift;
  my $level = shift;
  $level //= 3;
  my @st;
  my $i=1;
  my ($package, $file, $line, $sub) = caller($i++);
  $sub = $1 if (defined $sub && $sub =~ /^main::(.+)/);
  while(defined $package) {
    push @st, [$file, $line, $sub] unless ($sub =~ /^(dbg|info|warn|err|crit)$/);
    ($package, $file, $line, $sub) = caller($i);
    $sub = $1 if (defined $sub && $sub =~ /^main::(.+)/);
    last if ($i > $level);
    $i++;
  }
  return \@st;
}

sub logger {
  my ($self, $mode, $lvl, @stuff) = @_;
  return ($mode, @stuff) if ($self->opt('no_log') || $self->opt('log',1) == 0);
  return ($mode, @stuff) if ($self->opt('log_level', 3) < $lvl);
  my $st_ar = $self->stack_trace(5);
  shift @$st_ar;
  my $tm = tai();  # will not reflect leapseconds
  my $lt = localtime();  # will reflect leapseconds and other artificial time skew
  my $log_ar = [$tm, $lt, $$, $mode, $lvl, $self->{trace_ar}, $st_ar, @stuff];
  my $log_rec = $self->safely_to_json($log_ar) // "ERROR: $self->{ex}";
  print STDERR $log_rec,"\n" if ($self->opt('show_log'));
  print STDOUT $log_rec,"\n" if ($self->opt('show_log_to_stdout'));
  my $log_dir  = $self->opt('log_dir',  "/var/tmp");
  my $log_file = $self->opt('logfile', "$log_dir/$self->{project_name}.log");
  File::Valet::ap_f($log_file, $log_rec."\n") unless($self->opt('no_logfile'));
  return ($mode, @stuff);
}

# Add a log trace id to the trace list.
# Returns the new trace list length, suitable for passing to trace_pop() or trace_set().
sub trace_push {
  my ($self, $trace_id) = @_;
  $trace_id //= sprintf('%08X', int(rand() * 0xFFFFFFFF));
  push @{$self->{trace_ar}}, $trace_id;
  return scalar @{$self->{trace_ar}};
}

# Truncate the log trace list to a specific length, defaulting to one less the current length.
# Returns the tuple of traces removed, if any.
sub trace_pop {
  my ($self, $to_level) = @_;
  my $cur_level = scalar(@{$self->{trace_ar}});
  return () unless ($cur_level > 1);  # don't let user empty trace list
  $to_level //= $cur_level - 1;  # default to popping most recent trace
  my @traces;
  # could just splice(), but this is more understandable:
  while (scalar(@{$self->{trace_ar}}) > $to_level) {
    push @traces, pop @{$self->{trace_ar}};
  }
  return @traces;
}

# Set the topmost log trace id,
# optionally truncating first to a given length.
# Returns nothing.
sub trace_set {
  my ($self, $trace_id, $to_level) = @_;
  my $cur_level = scalar(@{$self->{trace_ar}});
  $to_level //= $cur_level;
  return unless ($to_level > 1);  # don't let user overwrite trace[0]
  $trace_id //= sprintf('%08X', int(rand() * 0xFFFFFFFF));
  $self->trace_pop($to_level) if ($to_level < $cur_level);
  $self->{trace_ar}->[$to_level-1] = $trace_id;
  return;
}

sub dbg {
  my $self = shift;
  my $lvl = 4;
  if ($_[-1] =~ /^[0-9]$/) {
    $lvl = pop @_;
  }
  return $self->logger("DEBUG", $lvl, @_);
}

sub crit { my $self = shift; return $self->logger("CRITICAL", 0, @_); }
sub err  { my $self = shift; return $self->logger("ERROR",    1, @_); }
sub warn { my $self = shift; return $self->logger("WARNING",  2, @_); }
sub info { my $self = shift; return $self->logger("INFO",     3, @_); }
sub ok   { my $self = shift; return ("OK", @_); }

sub is_ok {
  my ($mode) = @_;
  return 1 if ($mode eq 'OK');
  return 1 if ($mode eq 'WARNING');
  return 1 if ($mode eq 'INFO');
  return 0;
}

sub xint {
  my ($x) = @_;
  return 0 unless (defined $x && $x =~ /(\-?\d+)/);
  return int($1);
}

sub xfloat {
  my ($x) = @_;
  return 0 unless (defined $x && $x =~ /(\-?\d*\.?\d*)/);
  my $v = $1;
  return 0 unless ($v =~ /\d/);
  return $v + 0.0;
}

# Loads any configuration files found in /etc, $HOME, or --conf=<FILENAME>, in that order.
# Thus parameters found in the $HOME config overrides parameters from the system config,
# and parameters found in --conf override both.
# Use --no-home-config to suppress looking in $HOME entirely.
sub load_config {
  my ($self, $name, $opt_hr) = @_;
  $self->{conf_hr} = {};
  $name //= $self->{project_name};
  my $home = $ENV{HOME} // '';
  my $home_config = ($home && !$self->opt('no_home_config')) ? "$home/.$name.conf" : "";
  my $user_config = $self->opt('config', '', $opt_hr);
  for my $f (grep {-e $_} ("/etc/$name.conf", $home_config, $user_config)) {
    my $hr = $self->safely_from_json(File::Valet::rd_f($f) // '{}');
    for my $k (keys %$hr) {
      $self->{conf_hr}->{$k} = $hr->{$k};
    }
  }
  return;
}

1;
