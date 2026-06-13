package TestCapture;

use v5.40.0;
use common::sense;
use feature 'signatures';

use Exporter qw(import);
our @EXPORT_OK = qw(run_cmd);

use File::Temp qw(tempfile);


sub run_cmd ( %args ) {
  my $env = $args{env} // {};
  my $argv  = $args{argv} // die "run_cmd requires 'argv'";
  my $stdin = defined $args{stdin} ? $args{stdin} : '';
  my $cwd   = $args{cwd};

  ref $argv eq 'ARRAY' or die "'argv' must be an array reference";
  @$argv               or die "'argv' must not be empty";

  my ( $in_fh,  $in_path )  = tempfile();
  my ( $out_fh, $out_path ) = tempfile();
  my ( $err_fh, $err_path ) = tempfile();

  print {$in_fh} $stdin or die "write stdin temp file failed: $!";
  close $in_fh          or die "close stdin temp file failed: $!";
  close $out_fh         or die "close stdout temp file failed: $!";
  close $err_fh         or die "close stderr temp file failed: $!";

  my $pid = fork();
  defined $pid or die "fork failed: $!";

  if ( $pid == 0 ) {
    chdir $cwd or die "chdir '$cwd' failed: $!"
        if defined $cwd && length $cwd;

    open STDIN,  '<', $in_path  or die "open STDIN failed: $!";
    open STDOUT, '>', $out_path or die "open STDOUT failed: $!";
    open STDERR, '>', $err_path or die "open STDERR failed: $!";

    for my $k ( keys %$env ) {
  if ( defined $env->{$k} ) {
    $ENV{$k} = $env->{$k};
  }
  else {
    delete $ENV{$k};
  }
}

    exec {$argv->[0]} @$argv or die "exec failed: $!";
  }

  waitpid( $pid, 0 );
  my $exit = $? >> 8;

  my $stdout = _slurp( $out_path );
  my $stderr = _slurp( $err_path );

  return {
          stdout => $stdout,
          stderr => $stderr,
          exit   => $exit,};
}

sub _slurp ( $path ) {
  open my $fh, '<', $path or die "Cannot open '$path' for reading: $!";
  local $/;
  my $content = <$fh>;
  close $fh;
  return defined $content ? $content : '';
}

1;

__END__

=head1 TEST HELPER: TestCapture

=head2 NAME

TestCapture - Core-only subprocess capture helper for tests

=head2 SYNOPSIS

    use TestCapture qw(run_cmd);

    my $r = run_cmd(
      argv  => [ $^X, '-Ilib', 'bin/mojo-prettytidy', '--stdin' ],
      stdin => "alpha  \n",
    );

=head2 DESCRIPTION

This module provides a small core-only helper for running a subprocess
in tests while capturing standard input, standard output, standard
error, and exit status.

It uses temporary files and a fork/exec model to keep capture behavior
simple and predictable.

=head2 FUNCTIONS

=head3 run_cmd

    my $r = run_cmd(
      argv  => \@argv,
      stdin => $input,
    );

Returns a hash reference containing:

=over 4

=item * C<stdout>

Captured standard output.

=item * C<stderr>

Captured standard error.

=item * C<exit>

Process exit status.

=back
