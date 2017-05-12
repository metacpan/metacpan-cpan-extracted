package PPM::Make::Config;
use strict;
use warnings;
use base qw(Exporter);
use File::HomeDir;
require File::Spec;
use Config;
use Config::IniFiles;

our ($ERROR);
our $VERSION = '0.9904';

=head1 NAME

  PPM::Make::Config - Utility functions configuring PPM::Make

=head1 SYNOPSIS

  use PPM::Make::Config qw(:all);

=head1 DESCRIPTION

This module contains a number of utility functions used by PPM::Make.

=over 2

=item WIN32

Constant which is true if the platform matches C<MSWin32>.

=cut

use constant WIN32 => $^O eq 'MSWin32';

use constant ACTIVEPERL => eval { require ActivePerl::Config; 1 };

my @path_ext = ();
path_ext() if WIN32;

sub has_cpan {
  my $has_config = 0;
  require File::Spec;
  my $home = File::HomeDir->my_home;
  if ($home) {
    eval 
      {require File::Spec->catfile($home, '.cpan', 
                                   'CPAN', 'MyConfig.pm');};
    $has_config = 1 unless $@;
  }
  unless ($has_config) {
    eval {local $^W = 0; require CPAN::HandleConfig;};
    eval {local $^W = 0; require CPAN::Config;};
    my $dir;
    unless (WIN32) {
        $dir = $INC{'CPAN/Config.pm'};
    }
    $has_config = 1 unless ($@ or ($dir and not -w $dir));
  }
  require CPAN if $has_config;
  return $has_config;
}

=item HAS_CPAN

Constant which is true if the C<CPAN.pm> module is configured and
available.

=cut

use constant HAS_CPAN => has_cpan();

sub has_ppm {
  my $has_ppm = 0;
  my $ppm = File::Spec->catfile($Config{bin}, 'ppm.bat');
  return unless -f $ppm;
  my $version;

 VERSION: {
    (eval {require PPM;}) and do {
      unless ($@) {
        $version = 2;
        last VERSION;
      }
    };
    (eval {require PPM::Config;}) and do {
      unless ($@) {
        $version = 3;
        last VERSION;
      }
    };
    (eval {require ActivePerl::PPM;}) and do {
      unless ($@) {
        $version = 4;
        last VERSION;
      }
    };
    $version = 'unknown';
  }
  return $version;
}

=item HAS_PPM

Constant which is true if the C<PPM> module is available.
Will be set equal to the major version of ppm (2, 3 or 4), if found.

=cut

use constant HAS_PPM => has_ppm();

sub has_mb {
  my $has_mb = 0;
  eval {require Module::Build;};
  $has_mb = 1 unless $@;
  return $has_mb;
}

=item HAS_MB

Constant which is true if the C<Module::Build> module is available.

=cut

use constant HAS_MB => has_mb();

require Win32 if WIN32;

our (@EXPORT_OK, %EXPORT_TAGS);
my @exports = qw(check_opts arch_and_os get_cfg_file read_cfg merge_opts
                 what_have_you which $ERROR
                 WIN32 HAS_CPAN HAS_PPM HAS_MB ACTIVEPERL);
%EXPORT_TAGS = (all => [@exports]);
@EXPORT_OK = (@exports);

sub check_opts {
  my %opts = @_;
  my %legal = 
    map {$_ => 1} qw(force ignore binary zip_archive remove program cpan
                     dist script exec os arch arch_sub add no_as vs upload
                     no_case no_cfg vsr vsp zipdist no_ppm4 no_html
                     reps no_upload skip cpan_meta no_remote_lookup);
  foreach (keys %opts) {
    next if $legal{$_};
    warn "Unknown option '$_'\n";
    return;
  }

  if (defined $opts{add}) {
    unless (ref($opts{add}) eq 'ARRAY') {
      warn "Please supply an ARRAY reference to 'add'";
      return;
    }
  }

  if (defined $opts{program} and my $progs = $opts{program}) {
    unless (ref($progs) eq 'HASH') {
      warn "Please supply a HASH reference to 'program'";
      return;
    }
    my %ok = map {$_ => 1} qw(zip unzip tar gzip make);
    foreach (keys %{$progs}) {
      next if $ok{$_};
      warn "Unknown program option '$_'\n";
      return;
    }
  }
  
  if (defined $opts{upload} and my $upload = $opts{upload}) {
    unless (ref($upload) eq 'HASH') {
      warn "Please supply an HASH reference to 'upload'";
      return;
    }
    my %ok = map {$_ => 1} qw(ppd ar host user passwd zip bundle);
    foreach (keys %{$upload}) {
      next if $ok{$_};
      warn "Unknown upload option '$_'\n";
      return;
    }
  }
  return 1;
}

sub arch_and_os {
  my ($opt_arch, $opt_os, $opt_noas) = @_;

  my ($arch, $os);
  if (defined $opt_arch) {
    $arch = ($opt_arch eq "") ? undef : $opt_arch;
  }
  else {
    $arch = $Config{archname};
    unless ($opt_noas) {
      if ($] >= 5.008) {
        my $vstring = sprintf "%vd", $^V;
        $vstring =~ s/\.\d+$//;
        $arch .= "-$vstring";
      }
    }
  }
  if (defined $opt_os) {
    $os = ($opt_os eq "") ? undef : $opt_os;
  }
  else {
    $os = $Config{osname};
  }
  return ($arch, $os);
}

sub get_cfg_file {
  if (defined $ENV{PPM_CFG} and my $env = $ENV{PPM_CFG}) {
    if (-e $env) {
      return $env;
    }
    else {
      warn qq{Cannot find '$env' from \$ENV{PPM_CFG}};
      return;
    }
  }
  if (my $home = File::HomeDir->my_home) {
    my $candidate = File::Spec->catfile($home, '.ppmcfg');
    return $candidate if (-e $candidate);
  }
  if (WIN32) {
    my $candidate = '/.ppmcfg';
    return $candidate if (-e $candidate);
  }
  return;
}

sub read_cfg {
  my ($file, $arch) = @_;
  my $default = 'default';
  my $cfg = Config::IniFiles->new(-file => $file, -default => $default);
  my @p;
  push @p, $cfg->Parameters($default) if ($cfg->SectionExists($default));
  push @p, $cfg->Parameters($arch) if ($cfg->SectionExists($arch));
  unless (@p > 1) {
    warn "No default or section for $arch found";
    return;
  }

  my $on = qr!^(on|yes)$!;
  my $off = qr!^(off|no)$!;
  my %legal_progs = map {$_ => 1} qw(tar gzip make perl);
  my %legal_upload = map {$_ => 1} qw(ppd ar host user passwd zip bundle);
  my (%cfg, %programs, %upload);
  foreach my $p (@p) {
    my ($val, @vals);
    if ($p eq 'add' or $p eq 'reps') {
      @vals = $cfg->val($arch, $p);
      $cfg{$p} = \@vals;
      next;
    }
    else {
      $val = $cfg->val($arch, $p);
    }
    $val = 1 if ($val =~ /$on/i);
    if ($val =~ /$off/i) {
      delete $cfg{$p};
      next;
    }
    if ($legal_progs{$p}) {
      $programs{$p} = $val;
    }
    elsif ($legal_upload{$p}) {
      $upload{$p} = $val;
    }
    else {
      $cfg{$p} = $val;
    }
  }
  $cfg{program} = \%programs if %programs;
  $cfg{upload} = \%upload if %upload;
  return check_opts(%cfg) ? %cfg : undef;
}

# merge two hashes, assuming the second one takes precedence 
# over the first in the case of duplicate keys
sub merge_opts {
  my ($h1, $h2) = @_;
  my %opts = (%{$h1}, %{$h2});
  foreach my $opt(qw(add reps)) {
    if (defined $h1->{$opt} or defined $h2->{$opt}) {
      my @a = ();
      push @a, @{$h1->{$opt}} if $h1->{$opt};
      push @a, @{$h2->{$opt}} if $h2->{$opt};
      my %hash = map {$_ => 1} @a;
      $opts{$opt} = [keys %hash];
    }
  }
  for (qw(program upload)) {
    next unless (defined $h1->{$_} or defined $h2->{$_});
    my %h = ();
    if (defined $h1->{$_}) {
      if (defined $h2->{$_}) {
        %h = (%{$h1->{$_}}, %{$h2->{$_}});
      }
      else {
        %h = %{$h1->{$_}};
      }
    }
    else {
      %h = %{$h2->{$_}};     
    }
    $opts{$_} = \%h;
  }
  return \%opts;
}

sub what_have_you {
  my ($progs, $arch, $os) = @_;
  my %has;
  if (defined $progs->{tar} and defined $progs->{gzip}) {
    $has{tar} = $progs->{tar};
    $has{gzip} = $progs->{gzip};
  }
  elsif (not WIN32) {
    $has{tar} = 
      $Config{tar} || which('tar') || $CPAN::Config->{tar};
    $has{gzip} =
      $Config{gzip} || which('gzip') || $CPAN::Config->{gzip};
  }
  else {
    eval{require Archive::Tar; require Compress::Zlib};
    if ($@) {
      $has{tar} = 
        $Config{tar} || which('tar') || $CPAN::Config->{tar};
      $has{gzip} =
        $Config{gzip} || which('gzip') || $CPAN::Config->{gzip};
    }
    else {
      my $atv = mod_version('Archive::Tar');
      if (not WIN32 or (WIN32 and $atv >= 1.08)) {
        $has{tar} = 'Archive::Tar';
        $has{gzip} = 'Compress::Zlib';
      }
      else {
         $has{tar} = 
            $Config{tar} || which('tar') || $CPAN::Config->{tar};
          $has{gzip} =
            $Config{gzip} || which('gzip') || $CPAN::Config->{gzip};
      }
    }
  }

  if (defined $progs->{zip} and defined $progs->{unzip}) {
    $has{zip} = $progs->{zip};
    $has{unzip} = $progs->{unzip};
  }
  else {
    eval{require Archive::Zip; };
    if ($@) {
      $has{zip} = 
        $Config{zip} || which('zip') || $CPAN::Config->{zip};
      $has{unzip} =
        $Config{unzip} || which('unzip') || $CPAN::Config->{unzip};
    }
    else {
      my $zipv = mod_version('Archive::Zip');
      if ($zipv >= 1.02) {
        require Archive::Zip; import Archive::Zip qw(:ERROR_CODES);
        $has{zip} = 'Archive::Zip';
        $has{unzip} = 'Archive::Zip';
      }
      else {
        $has{zip} =
          $Config{zip} || which('zip') || $CPAN::Config->{zip};
        $has{unzip} =
          $Config{unzip} || which('unzip') || $CPAN::Config->{unzip};
      }
    }
  }
  
  my $make = WIN32 ? 'nmake' : 'make';
  $has{make} = $progs->{make} ||
    $Config{make} || which($make) || $CPAN::Config->{make};

  $has{perl} = 
    $^X || which('perl');
  
  foreach (qw(tar gzip make perl)) {
    unless ($has{$_}) {
      $ERROR = "Cannot find a '$_' program";
      return;
    }
    print "Using $has{$_} ....\n";
  }

  return \%has;
}

sub mod_version {
  my $mod = shift;
  eval "require $mod";
  return if $@;
  my $mv = eval "$mod->VERSION";
  return 0 if $@;
  $mv =~ s/_.*$//x;
  $mv += 0;
  return $mv;
}

sub path_ext {
  if ($ENV{PATHEXT}) {
    push @path_ext, split ';', $ENV{PATHEXT};
    for my $extention (@path_ext) {
      $extention =~ s/^\.*(.+)$/$1/;
    }
  }
  else {
    #Win9X: doesn't have PATHEXT
    push @path_ext, qw(com exe bat);
  }
}

=item which

Find the full path to a program, if available.

  my $perl = which('perl');

=cut

sub which {
  my $program = shift;
  return undef unless $program;
  my @results = ();
  my $home = File::HomeDir->my_home;
  for my $base (map { File::Spec->catfile($_, $program) } File::Spec->path()) {
    if ($home and not WIN32) {
      # only works on Unix, but that's normal:
      # on Win32 the shell doesn't have special treatment of '~'
      $base =~ s/~/$home/o;
    }
    return $base if -x $base;
    
    if (WIN32) {
      for my $extention (@path_ext) {
        return "$base.$extention" if -x "$base.$extention";
      }
    }
  }
}

1;

__END__

=back

=head1 COPYRIGHT

This program is copyright, 2006 by 
Randy Kobes <r.kobes@uwinnipeg.ca>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM::Make>.

=cut

