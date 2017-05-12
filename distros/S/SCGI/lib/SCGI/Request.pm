package SCGI::Request;

use strict;
use warnings;

use SCGI;

use POSIX ':errno_h';

our $VERSION = $SCGI::VERSION;

=head1 NAME

SCGI::Request

=head1 DESCRIPTION

This module implements the part of the SCGI protocol that reads the environment. All that remains after this is the content of the request. The protocol and this module guarentee that there will be a CONTENT_LENGTH for the body of the request in the environment.

=head1 SYNOPISIS

  # $request got from SCGI
  $request->read_env;
  
  read $request->connection, my $body, $request->env->{CONTENT_LENGTH};

=head2 public methods

=over

=item read_env

Read the environment in a blocking or non-blocking manner, per parameter to C<SCGI->new>. Returns true if it has finished.

=cut

sub read_env {
  my ($this) = @_;
  goto &_blocking_read_env if $this->blocking;
  die 'read_env called when env already read - use env method to access' if $this->{env_read};
  $this->{env_length_buffer} ||= '';
  $this->{env_buffer} ||= '';
  unless ($this->{env_length_read}) {
    my $bytes_read = sysread $this->connection, my $buffer, 14;
    die "read error: $!" unless defined $bytes_read || $! == EAGAIN;
    return unless $bytes_read;
    if ($buffer =~ m{ ^ (\d+) : (.*) $ }osx) {
      $this->{env_length_buffer} .= $1;
      $this->{env_buffer} .= $2;
      $this->{env_length_read} = 1;
    }
    elsif ($this->{env_length_buffer} ne '' && $buffer =~ m{ ^ : (.*) $ }osx) {
      $this->{env_buffer} .= $1;
      $this->{env_length_read} = 1;
    }
    elsif ($buffer =~ m{ ^ \d+ $ }osx) {
      $this->{env_length_buffer} .= $buffer;
      return;
    }
    else {
      die "malformed env length";
    }
  }
  my $left_to_read = $this->{env_length_buffer} - length($this->{env_buffer});
  my $buffer = '';
  my $read = sysread $this->connection, $buffer, $left_to_read + 1;
  die "read error: $!" unless defined $read || $! == EAGAIN;
  return unless $read;
  if ($read == $left_to_read + 1) {
    if ((my $comma = substr $buffer, $left_to_read) ne ',') {
      die "malformed netstring, expected terminating comma, found \"$comma\"";
    }
    $this->_decode_env($this->{env_buffer} . substr $buffer, 0, $left_to_read);
    return 1;
  }
  else {
    $this->{env_buffer} .= $buffer;
    return;
  }
}

=item env

Gets the environment for this request after it has been read. This will return undef until C<read_env> or C<sysread_env> has been called and returned true.

=cut

sub env {
  my ($this) = @_;
  $this->{env};
}

=item connection

Returns the open connection to the client.

=cut

sub connection {
  my ($this) = @_;
  $this->{connection};
}

=item close

Closes the connection.

=cut

sub close {
  my ($this) = @_;
  $this->connection->close if $this->connection;
  $this->{closed} = 1;
}

=item blocking

Returns true if the connection is blocking.

=cut

sub blocking {
  my ($this) = @_;
  $this->{blocking};
}

=item set_blocking

If boolean argument is true turns on blocking, otherwise turns it off.

=cut

sub set_blocking {
  my ($this, $blocking) = @_;
  return if $this->{blocking} && $blocking || ! $this->{blocking} && ! $blocking;
  if ($blocking) {
    $this->connection->blocking(1);
  }
  else {
    $this->connection->flush;
    $this->connection->blocking(0);
  }
}

=back

=head2 private methods

=over

=item _new

Creates a new SCGI::Request. This is used by SCGI in the C<accept> method, so if you are considering using this, use that instead.

=cut

sub _new {
  my ($class, $connection, $blocking) = @_;
  bless {connection => $connection, blocking => $blocking}, $class;
}

=item _decode_env

Takes the encoded environment as a string and sets the env ready for access with C<env>.

=cut

sub _decode_env {
  my ($this, $env_string) = @_;
  my %env;
  pos $env_string = 0;
  $env_string =~ m{
    \G CONTENT_LENGTH \0 (\d+) \0
  }msogcx or die "malformed CONTENT_LENGTH header";
  $env{CONTENT_LENGTH} = $1;
  while ($env_string =~ m{ ([^\0]+) \0 ([^\0]+) \0 }msogcx) {
    warn "repeated $1 header in env" if $env{$1};
    $env{$1} = $2;
  }
  die "malformed header" unless pos $env_string = length $env_string;
  die "missing SCGI header" unless $env{SCGI} && $env{SCGI} eq '1';
  $this->_set_env(\%env);
}

=item _set_env

Sets the environment for this request.

=cut

sub _set_env {
  my ($this, $env) = @_;
  $this->{env} = $env;
}

=item _blocking_read_env

Reads and decodes the environment in one go. Returns true on success, raises an exception on failiure.

=cut

sub _blocking_read_env {
  my ($this) = @_;
  read $this->connection, my $env_length, 14 or die "cannot read env length from connection: $!";
  my ($length, $rest) = $env_length =~ m{ ^ (\d+) : (.*) $ }osx
    or die 'malformed env length';
  read $this->connection, my $env, $length + 1 - length($rest) or die "cannot read env from connection: $!";
  if ((my $comma = substr $env, $length - length $rest) ne ',') {
    die "malformed netstring, expected terminating comma, found \"$comma\"";
  }
  $this->_decode_env($rest . substr $env, 0, $length);
  1;
}

sub DESTROY {
  my ($this) = @_;
  $this->close unless $this->{closed};
}

1;

__END__

=back

=head1 AUTHOR

Thomas Yandell L<mailto:tom+scgi@vipercode.com>

=head1 COPYRIGHT

Copyright 2005, 2006 Viper Code Limited. All rights reserved.

=head1 LICENSE

This file is part of SCGI (perl SCGI library).

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
