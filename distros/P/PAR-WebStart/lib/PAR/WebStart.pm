package PAR::WebStart;
use strict;
use warnings;
use LWP::Simple qw(getstore is_success);
require File::Spec;
use File::Basename;
use Digest::MD5;
use File::Which;
use File::Temp qw(tempfile);
use PAR::WebStart::PNLP;
use PAR::WebStart::Util qw(verifyMD5);
use Config;
use constant WIN32 => PAR::WebStart::Util::WIN32;

our $VERSION = '0.20';

sub new {
  my ($class, %args) = @_;
  my $file = $args{file};
  die "Please supply the pnlp file" unless ($file and -e $file);
  my $obj = PAR::WebStart::PNLP->new(file => $file);
  my $cfg = $obj->parse();
  die "Error: $obj->{ERROR}" unless ($cfg);

  my $tmpdir = $ENV{PAR_TEMP} || 
    File::Spec->catdir(File::Spec->tmpdir(), 'par');
  unless (-d $tmpdir) {
    mkdir($tmpdir) or die qq{Failed to mkdir "$tmpdir": $!};
  }

  my $par_command = {};
  if (WIN32) {
    die qq{Could not find "par"}
      unless ($par_command->{par} = which('par'));
    ($par_command->{par_pl} = $par_command->{par}) =~ s/\.bat$/.pl/i;
    die qq{Could not find "par.pl"}
      unless (-f $par_command->{par_pl});
    if ($cfg->{wperl}->{seen}) {
      die qq{Could not find "wperl"} 
        unless ($par_command->{wperl} = which('wperl'));
    }
  }
  else {
    die qq{Could not find "par.pl"}
      unless ($par_command->{par_pl} = which('par.pl'));
  }

  my %config = (os => $Config{osname},
                arch => $Config{archname},
                version => $],
                perl_version => $Config{PERL_VERSION},
               );
  my $self = {pnlp => $file, cfg => $cfg, ERROR => '', %config,
              tmpdir => $tmpdir, pars => [], par_command => $par_command,
              cached_pars => {} };
  bless $self, $class;
}

sub fetch_pars {
  my $self = shift;
  my $cfg = $self->{cfg};

  if (my $version = $cfg->{perlws}->{version}) {
    if ($VERSION < $version) {
      $self->{ERROR} = qq{PAR::WebStart version '$version' required, but only '$VERSION' seen};
      return;
    }
  }

  my $prereqs = $cfg->{module};
  if ($prereqs and ref($prereqs) eq 'ARRAY' ) {
    return unless $self->check_prereqs($prereqs);
  }

  if (my $resources = $cfg->{resources}) {
    unless ($self->check_platform($resources)) {
      $self->{ERROR} = 'Resource specification not intended for this platform';
      return;
    }
  }
  my $par = $cfg->{par};
  unless ($par and ref($par) eq 'ARRAY') {
    $self->{ERROR} = 'No par archives specified';
    return;
  }
  my $par_files = [];
  foreach my $file(@$par) {
    next unless $self->check_platform($file);
    push @$par_files, $file->{href};
  }
  if (scalar(@$par_files) == 0) {
    $self->{ERROR} = 'No suitable par files found for this platform';
    return;
  }

  my $tmpdir = $self->{tmpdir};
  my $codebase = $cfg->{pnlp}->{codebase};
  $codebase =~ s{/$}{};

  foreach my $par (@$par_files) {
    my $md5 = $par . '.md5';
    my $remote_par = $codebase . '/' . $par;
    my $remote_md5 = $codebase . '/' . $md5;
    my $local_par = File::Spec->catfile($tmpdir, 
                                        basename($par, qr{\.par}));
    my $local_md5 = File::Spec->catfile($tmpdir, 
                                        basename($md5, qr{\.md5}));
    unless (is_success(getstore($remote_md5, $local_md5))) {
      $self->{ERROR} = qq{Failed to get "$remote_md5"};
      return;
    }
    if (-e $local_par) {
      my $status = verifyMD5(md5 => $local_md5, file => $local_par);
      if ($status and $status =~ /^1$/) {
        my $base = basename($local_par, qr{\.par});
        push @{$self->{pars}}, $base;
        $self->{cached_pars}->{$base}++;
        next;
      }
    }
    unless (is_success(getstore($remote_par, $local_par))) {
      $self->{ERROR} = qq{Failed to get "$remote_par"};
      return;
    }

    my $status = verifyMD5(md5 => $local_md5, file => $local_par);
    unless ($status and $status =~ /^1$/) {
      $self->{ERROR} = $status;
      return;
    }

    push @{$self->{pars}}, basename($local_par, qr{\.par});
  }

  if ($cfg->{icon}) {
    my $icon = $cfg->{icon}->{href};
    my $remote_icon = $codebase . '/' . $icon;
    my $local_icon = File::Spec->catfile($tmpdir, 
                                         basename($icon, qr{\..*}));
    unless (is_success(getstore($remote_icon, $local_icon))) {
      $self->{ERROR} = qq{Failed to get "$remote_icon"};
      return;
    }
  }

  unless ($cfg->{'allow-unsigned-pars'}->{seen}) {
    $self->verify_sig() or return;
  }
  return 1;
}

sub check_platform {
  my ($self, $hash) = @_;
  return if ($hash->{version} and $hash->{version} > $self->{version});
  foreach my $key(qw(os arch perl_version)) {
    return if ($hash->{$key} and $hash->{$key} ne $self->{$key});
  }
  return 1;
}

sub check_prereqs {
  my ($self, $prereqs) = @_;
  my @wanted = ();
  foreach my $ref(@{$prereqs}) {
    my $mod = $ref->{value};
    eval "require $mod";
    next unless $@;
    push @wanted, $mod;
  }
  if (@wanted) {
    my $needed = join ', ', @wanted;
    $self->{ERROR} = <<"END";
The following modules are needed but were not found:
   $needed
Please consider installing them first.
END
    return;
  }
  return 1;
}


sub verify_sig {
  my $self = shift;
  my $tmpdir = $self->{tmpdir};
  chdir($tmpdir) or do {
    $self->{ERROR} = qq{Cannot chdir to "$tmpdir": $!};
    return;
  };
  my @args = ();
  my $par_command = $self->{par_command};
  if (WIN32) {
    if ($par_command->{wperl}) {
      push @args, ($par_command->{wperl}, $par_command->{par_pl});
    }
    else {
      push @args, $par_command->{par};
    }
  }
  else {
    push @args, $par_command->{par_pl};
  }
  push @args, '-v';
  no warnings;
  my ($fh, $filename) = tempfile(UNLINK => 1);
  open my $oldout, ">&STDOUT" or die "Cannot dup STDOUT: $!";
  open OLDERR, ">&", \*STDERR or die "Cannot dup STDERR: $!";
  open STDOUT, '>', $filename or die "Cannot redirect STDOUT: $!";
  open STDERR, ">&STDOUT" or die "Cannot dup STDERR: $!";
  select STDERR; $| = 1;
  select STDOUT; $| = 1;

  my $pars = $self->{pars};
  my $cached_pars = $self->{cached_pars};
  foreach my $par(@$pars) {
    next if $cached_pars->{$par};
    system(@args, $par);
  }

  seek($fh, 0, 1);
  open STDOUT, ">&", $oldout or die "Cannot dup \$oldout: $!";
  open STDERR, ">&OLDERR" or die "Cannot dup OLDERR: $!";
  my $failure = 0;
  my $text = '';
  while (my $line = <$fh>) {
      $text .= $line;
      $failure++ if ($line =~ /Mismatched content between SIGNATURE/i);
  }
  if ($failure) {
      $self->{ERROR} = $text;
      return;
  }
  return 1;
}

sub run_command {
  my $self = shift;

  my @args = ();
  my $par_command = $self->{par_command};
  if (WIN32) {
    if ($par_command->{wperl}) {
      push @args, ($par_command->{wperl}, $par_command->{par_pl});
    }
    else {
      push @args, $par_command->{par};
    }
  }
  else {
    push @args, $par_command->{par_pl};
  }

  my $pars = $self->{pars};
  my $number_of_pars = scalar(@$pars);
  if ($number_of_pars == 1) {
    push @args, $pars->[0];
  }
  else {
    for my $i (1 .. $number_of_pars-1) {
      push @args, "-A$pars->[$i]";
    }
    push @args, $pars->[0];
  }

  my $cfg = $self->{cfg};
  my @extra_args = ();
  foreach my $arg(@{$cfg->{argument}}) {
    push @extra_args, $arg->{value};
  }
  push @args, @extra_args if @extra_args;

  return \@args;
}

1;

__END__

=head1 NAME

PAR::WebStart - Perl implementation of Java's WebStart

=head1 SYNOPSIS

  my $file = 'hello.pnlp';
  my $ws = PAR::WebStart->new(file => $file);
  $ws->fetch_pars() or die $ws->{ERROR};

  my $tmpdir = $ws->{tmpdir};
  chdir($tmpdir) or die qq{Cannot chdir to "$tmpdir": $!});

  my @args = @{$ws->run_command()};
  die qq{Failed to get WebStart args: $ws->{ERROR}}) unless (@args);
  system(@args) == 0 or die qq{Execution of system(@args) failed: $?};

=head1 DESCRIPTION

This a Perl version of Java's WebStart technology; see
L<http://java.sun.com/j2se/1.4.2/docs/guide/jws/developersguide/overview.html>
for details.

PAR-WebStart is a helper application associated
with a browser. When a user clicks on a link that points to a 
PNLP [PAR Network Launch Protocol] launch file (a special XML file), 
it causes the browser to launch PAR-WebStart, which then 
automatically downloads, caches, and runs the specified
PAR-based application. 

=head1 SEE ALSO

L<PAR::WebStart::PNLP>, for details of the C<PNLP> file.
Some utilities used here are described at
L<PAR::WebStart::Util>. Making a suitable C<par>
archive for use here is described in L<make_par>.
L<perlws> describes how to associate C<PNLP>
files with the appropriate application to use.

=head1 COPYRIGHT

Copyright, 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
This software is distributed under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 CURRENT MAINTAINER

Kenichi Ishigaki <ishigaki@cpan.org>

=cut



