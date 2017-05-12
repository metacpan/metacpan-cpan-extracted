package SOOT::App;
use 5.008001;
use strict;
use warnings;
use Getopt::Long ();
use File::Spec;
use threads;
use Capture::Tiny qw/capture/;
use Time::HiRes 'usleep';
use vars '%SIG';

our $VERSION = '0.04';
our $AppThread;

sub usage {
  print <<'HERE';
Usage: soot [options]

  -n   Do not execute logon macros
HERE
  exit(1);
}

sub run {
  my $class = shift;

  my %opts = @_;
  my $argv = $opts{argv}||[];

  my $nologon = 0;
  Getopt::Long::GetOptionsFromArray(
    $argv,
    'h|help' => \&usage,
    'n' => \$nologon,
  );

  my @files_to_open = @$argv;
  require Devel::REPL;
  require SOOT;
  require Devel::REPL::Plugin::CompletionDriver::SOOT;

  my $repl = Devel::REPL->new;
  foreach (qw(FindVariable History LexEnv Packages SOOT)) {
    $repl->load_plugin($_)
  }
  foreach (qw(Colors CompletionDriver::SOOT Completion DDS Interrupt
              MultiLine::PPI OutputCache PPI)) {
    my @discard = capture {
      eval {
        $repl->load_plugin($_);
        1;
      } or die $@;
    };
  }
  create_app_thread();
  package main;
  SOOT->import(':all');
  # FIXME: mst will likely kill me for this
  $repl->formatted_eval("package main;");
  $repl->formatted_eval("no strict 'vars'");
  $repl->formatted_eval("use SOOT qw/:all/");
  $repl->formatted_eval("use Data::Dumper;");
  SOOT::Init($nologon ? 0 : 1);

  $class->_open_root_files(\@files_to_open);

  return $repl->run();
}

sub _open_root_files {
  my $class = shift;
  my $files = shift;

  no strict 'vars';
  package main;
  foreach my $file (map {glob $_} @$files) {
    my $f = TFile->new($file, 'READ');
    push @files, $f;
    print "Attached file '$file' as \$main::files[" . $#main::files . "]...\n";
  }
  return();
}

sub create_app_thread {
  if (not $AppThread) {
    $SOOT::gApplication->SetReturnFromRun(1);
    $AppThread = threads->new(\&apploop);
    usleep(5000); # FIXME find better way to fix this
    $SOOT::gApplication->SetReturnFromRun(1);
  }
}

sub apploop {
  $SOOT::gApplication->SetReturnFromRun(1);
  $SOOT::gApplication->Run();
}

sub kill_app_thread {
  return if !$AppThread;
  $SOOT::gApplication->Terminate();
  $AppThread->kill('TERM')->kill('KILL')->detach;
  $AppThread = undef;
}

END {
  kill_app_thread();
}

SCOPE: {
  my %sig;
  sub init_signal_handlers {
    if (not keys %sig) {
      %sig = %SIG;
      $SIG{TERM} = sub { kill_app_thread(); return $sig{TERM}->() if ref($SIG{TERM}) eq 'CODE' };
      $SIG{INT}  = sub { kill_app_thread(); return $sig{INT}->() if ref($SIG{INT}) eq 'CODE' };
    }
  }
}

1;
__END__

=head1 NAME

SOOT::App - A Perl REPL using SOOT (ROOT)

=head1 SYNOPSIS

  use SOOT::App;
  SOOT::App->run();

=head1 DESCRIPTION

SOOT is a Perl extension for using the ROOT library. It is very similar
to the Ruby-ROOT or PyROOT extensions for their respective languages.
Specifically, SOOT was implemented after the model of Ruby-ROOT.

SOOT::App implements the equivalent of the ROOT/CInt shell for Perl
using L<Devel::REPL>.

=head1 SEE ALSO

L<http://root.cern.ch>

L<SOOT>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

SOOT, the Perl-ROOT wrapper, is free software; you can redistribute it and/or modify
it under the same terms as ROOT itself, that is, the GNU Lesser General Public License.
A copy of the full license text is available from the distribution as the F<LICENSE> file.

=cut

