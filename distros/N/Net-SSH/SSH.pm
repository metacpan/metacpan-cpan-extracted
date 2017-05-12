package Net::SSH;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $ssh $equalspace $DEBUG @ssh_options);
use Exporter;
use POSIX ":sys_wait_h";
use IO::File;
use IO::Select;
use IPC::Open2;
use IPC::Open3;

@ISA = qw(Exporter);
@EXPORT_OK = qw( ssh issh ssh_cmd sshopen2 sshopen3 );
$VERSION = '0.09';

$DEBUG = 0;

$ssh = "ssh";

=head1 NAME

Net::SSH - Perl extension for secure shell

=head1 SYNOPSIS

  use Net::SSH qw(ssh issh sshopen2 sshopen3);

  ssh('user@hostname', $command);

  issh('user@hostname', $command);

  ssh_cmd('user@hostname', $command);
  ssh_cmd( {
    user => 'user',
    host => 'host.name',
    command => 'command',
    args => [ '-arg1', '-arg2' ],
    stdin_string => "string\n",
  } );

  sshopen2('user@hostname', $reader, $writer, $command);

  sshopen3('user@hostname', $writer, $reader, $error, $command);

=head1 DESCRIPTION

Simple wrappers around ssh commands.

For an all-perl implementation that does not require the system B<ssh> command,
see L<Net::SSH::Perl> instead.

=head1 SUBROUTINES

=over 4

=item ssh [USER@]HOST, COMMAND [, ARGS ... ]

Calls ssh in batch mode.

=cut

sub ssh {
  my($host, @command) = @_;
  @ssh_options = &_ssh_options unless @ssh_options;
  my @cmd = ($ssh, @ssh_options, $host, @command);
  warn "[Net::SSH::ssh] executing ". join(' ', @cmd). "\n"
    if $DEBUG;
  system(@cmd);
}

=item issh [USER@]HOST, COMMAND [, ARGS ... ]

Prints the ssh command to be executed, waits for the user to confirm, and
(optionally) executes the command.

=cut

sub issh {
  my($host, @command) = @_;
  my @cmd = ($ssh, $host, @command);
  print join(' ', @cmd), "\n";
  if ( &_yesno ) {
    system(@cmd);
  }
}

=item ssh_cmd [USER@]HOST, COMMAND [, ARGS ... ]

=item ssh_cmd OPTIONS_HASHREF

Calls ssh in batch mode.  Throws a fatal error if data occurs on the command's
STDERR.  Returns any data from the command's STDOUT.

If using the hashref-style of passing arguments, possible keys are:

  user (optional)
  host (requried)
  command (required)
  args (optional, arrayref)
  stdin_string (optional) - written to the command's STDIN

=cut

sub ssh_cmd {
  my($host, $stdin_string, @command);
  if ( ref($_[0]) ) {
    my $opt = shift;
    $host = $opt->{host};
    $host = $opt->{user}. '@'. $host if exists $opt->{user};
    @command = ( $opt->{command} );
    push @command, @{ $opt->{args} } if exists $opt->{args};
    $stdin_string = $opt->{stdin_string};
  } else {
    ($host, @command) = @_;
    undef $stdin_string;
  }

  my $reader = IO::File->new();
  my $writer = IO::File->new();
  my $error  = IO::File->new();

  my $pid = sshopen3( $host, $writer, $reader, $error, @command ) or die $!;

  print $writer $stdin_string if defined $stdin_string;
  close $writer;

  my $select = new IO::Select;
  foreach ( $reader, $error ) { $select->add($_); }

  my($output_stream, $error_stream) = ('', '');
  while ( $select->count ) {
    my @handles = $select->can_read;
    foreach my $handle ( @handles ) {
      my $buffer = '';
      my $bytes = sysread($handle, $buffer, 4096);
      if ( !defined($bytes) ) {
        waitpid($pid, WNOHANG);
        die "[Net::SSH::ssh_cmd] $!"
      };
      $select->remove($handle) if !$bytes;
      if ( $handle eq $reader ) {
        $output_stream .= $buffer;
      } elsif ( $handle eq $error ) {
        $error_stream  .= $buffer;
      }
    }

  }

  waitpid($pid, WNOHANG);

  die "$error_stream" if length($error_stream);

  return $output_stream;

}

=item sshopen2 [USER@]HOST, READER, WRITER, COMMAND [, ARGS ... ]

Connects the supplied filehandles to the ssh process (in batch mode).

=cut

sub sshopen2 {
  my($host, $reader, $writer, @command) = @_;
  @ssh_options = &_ssh_options unless @ssh_options;
  open2($reader, $writer, $ssh, @ssh_options, $host, @command);
}

=item sshopen3 HOST, WRITER, READER, ERROR, COMMAND [, ARGS ... ]

Connects the supplied filehandles to the ssh process (in batch mode).

=cut

sub sshopen3 {
  my($host, $writer, $reader, $error, @command) = @_;
  @ssh_options = &_ssh_options unless @ssh_options;
  open3($writer, $reader, $error, $ssh, @ssh_options, $host, @command);
}

sub _yesno {
  print "Proceed [y/N]:";
  my $x = scalar(<STDIN>);
  $x =~ /^y/i;
}

sub _ssh_options {
  my $reader = IO::File->new();
  my $writer = IO::File->new();
  my $error  = IO::File->new();
  open3($writer, $reader, $error, $ssh, '-V');
  my $ssh_version = <$error>;
  chomp($ssh_version);
  if ( $ssh_version =~ /.*OpenSSH[-|_](\w+)\./ && $1 == 1 ) {
    $equalspace = " ";
  } else {
    $equalspace = "=";
  }
  my @options = ( '-o', 'BatchMode'.$equalspace.'yes' );
  if ( $ssh_version =~ /.*OpenSSH[-|_](\w+)\./ && $1 > 1 ) {
    unshift @options, '-T';
  }
  @options;
}

=back

=head1 EXAMPLE

  use Net::SSH qw(sshopen2);
  use strict;

  my $user = "username";
  my $host = "hostname";
  my $cmd = "command";

  sshopen2("$user\@$host", *READER, *WRITER, "$cmd") || die "ssh: $!";

  while (<READER>) {
      chomp();
      print "$_\n";
  }

  close(READER);
  close(WRITER);

=head1 FREQUENTLY ASKED QUESTIONS

Q: How do you supply a password to connect with ssh within a perl script
using the Net::SSH module?

A: You don't (at least not with this module).  Use RSA or DSA keys.  See the
   quick help in the next section and the ssh-keygen(1) manpage.

A #2: See L<Net::SSH::Expect> instead.

Q: My script is "leaking" ssh processes.

A: See L<perlfaq8/"How do I avoid zombies on a Unix system">, L<IPC::Open2>,
L<IPC::Open3> and L<perlfunc/waitpid>.

=head1 GENERATING AND USING SSH KEYS

=over 4

=item 1 Generate keys

Type:

   ssh-keygen -t rsa

And do not enter a passphrase unless you wanted to be prompted for
one during file copying.

Here is what you will see:

   $ ssh-keygen -t rsa
   Generating public/private rsa key pair.
   Enter file in which to save the key (/home/User/.ssh/id_rsa):
   Enter passphrase (empty for no passphrase):

   Enter same passphrase again:

   Your identification has been saved in /home/User/.ssh/id_rsa.
   Your public key has been saved in /home/User/.ssh/id_rsa.pub.
   The key fingerprint is:
   5a:cd:2b:0a:cd:d9:15:85:26:79:40:0c:55:2a:f4:23 User@JEFF-CPU


=item 2 Copy public to machines you want to upload to

C<id_rsa.pub> is your public key. Copy it to C<~/.ssh> on target machine.

Put a copy of the public key file on each machine you want to log into.
Name the copy C<authorized_keys> (some implementations name this file
C<authorized_keys2>)

Then type:

     chmod 600 authorized_keys

Then make sure your home dir on the remote machine is not group or
world writeable.

=back

=head1 AUTHORS

Ivan Kohler <ivan-netssh_pod@420.am>

Assistance wanted - this module could really use a maintainer with enough time
to at least review and apply more patches.  Or the module should just be
deprecated in favor of Net::SSH::Expect or made into an ::Any style
compatibility wrapper that uses whatver implementation is avaialble
(Net::SSH2, Net::SSH::Perl or shelling out like the module does now).  Please
email Ivan if you are interested in helping.

John Harrison <japh@in-ta.net> contributed an example for the documentation.

Martin Langhoff <martin@cwa.co.nz> contributed the ssh_cmd command, and
Jeff Finucane <jeff@cmh.net> updated it and took care of the 0.04 release.

Anthony Awtrey <tony@awtrey.com> contributed a fix for those still using
OpenSSH v1.

Thanks to terrence brannon <tbone@directsynergy.com> for the documentation in
the GENERATING AND USING SSH KEYS section.

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Kohler.
Copyright (c) 2007-2008 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

Not OO.

Look at IPC::Session (also fsh, well now the native SSH "master mode" stuff)

=head1 SEE ALSO

For a perl implementation that does not require the system B<ssh> command, see
L<Net::SSH::Perl> instead.

For a wrapper version that allows you to use passwords, see L<Net::SSH::Expect>
instead.

For another non-forking version that uses the libssh2 library, see 
L<Net::SSH2>.

For a way to execute remote Perl code over an ssh connection see
L<IPC::PerlSSH>.

ssh-keygen(1), ssh(1), L<IO::File>, L<IPC::Open2>, L<IPC::Open3>

=cut

1;

