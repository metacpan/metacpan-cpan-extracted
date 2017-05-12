package Net::SCP;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $scp $DEBUG);
use Exporter;
use Carp;
use File::Basename;
use String::ShellQuote;
use IO::Handle;
use Net::SSH qw(sshopen3);
use IPC::Open3;

@ISA = qw(Exporter);
@EXPORT_OK = qw( scp iscp );
$VERSION = '0.08';

$scp = "scp";

$DEBUG = 0;

=head1 NAME

Net::SCP - Perl extension for secure copy protocol

=head1 SYNOPSIS

  #procedural interface
  use Net::SCP qw(scp iscp);
  scp($source, $destination);
  iscp($source, $destination); #shows command, asks for confirmation, and
                               #allows user to type a password on tty

  #OO interface
  $scp = Net::SCP->new( "hostname", "username" );
  #with named params
  $scp = Net::SCP->new( { "host"=>$hostname, "user"=>$username } );
  $scp->get("filename") or die $scp->{errstr};
  $scp->put("filename") or die $scp->{errstr};
  #tmtowtdi
  $scp = new Net::SCP;
  $scp->scp($source, $destination);

  #Net::FTP-style
  $scp = Net::SCP->new("hostname");
  $scp->login("user");
  $scp->cwd("/dir");
  $scp->size("file");
  $scp->get("file");

=head1 DESCRIPTION

Simple wrappers around ssh and scp commands.

=head1 SUBROUTINES

=over 4

=item scp SOURCE, DESTINATION

Can be called either as a subroutine or a method; however, the subroutine
interface is depriciated.

Calls scp in batch mode, with the B<-B> B<-p> B<-q> and B<-r> options.
Returns false upon error, with a text error message accessable in
$scp->{errstr}.

Returns false and sets the B<errstr> attribute if there is an error.

=cut

sub scp {
  my $self = ref($_[0]) ? shift : {};
  my($src, $dest, $interact) = @_;
  my $flags = '-p';
  $flags .= 'r' unless &_islocal($src) && ! -d $src;
  my @cmd;
  if ( ( defined($interact) && $interact )
       || ( defined($self->{interactive}) && $self->{interactive} ) ) {
    @cmd = ( $scp, $flags, $src, $dest );
    print join(' ', @cmd), "\n";
    unless ( &_yesno ) {
      $self->{errstr} = "User declined";
      return 0;
    }
  } else {
    $flags .= 'qB';
    @cmd = ( $scp, $flags, $src, $dest );
  }
  my($reader, $writer, $error ) =
    ( new IO::Handle, new IO::Handle, new IO::Handle );
  $writer->autoflush(1);#  $error->autoflush(1);
  local $SIG{CHLD} = 'DEFAULT';
  my $pid = open3($writer, $reader, $error, @cmd );
  waitpid $pid, 0;
  if ( $? >> 8 ) {
    my $errstr = join('', <$error>);
    #chomp(my $errstr = <$error>);
    $self->{errstr} = $errstr;
    0;
  } else {
    1;
  }
}

=item iscp SOURCE, DESTINATION

Can be called either as a subroutine or a method; however, the subroutine
interface is depriciated.

Prints the scp command to be execute, waits for the user to confirm, and
(optionally) executes scp, with the B<-p> and B<-r> flags.

Returns false and sets the B<errstr> attribute if there is an error.

=cut

sub iscp {
  if ( ref($_[0]) ) {
    my $self = shift;
    $self->{'interactive'} = 1;
    $self->scp(@_);
  } else {
    scp(@_, 1);
  }
}

sub _yesno {
  print "Proceed [y/N]:";
  my $x = scalar(<STDIN>);
  $x =~ /^y/i;
}

sub _islocal {
  shift !~ /^[^:]+:/
}

=back

=head1 METHODS

=over 4

=item new HOSTNAME [ USER ] | HASHREF

This is the constructor for a new Net::SCP object.  You must specify a
hostname, and may optionally provide a user.  Alternatively, you may pass a
hashref of named params, with the following keys:

    host - hostname
    user - username
    interactive - bool
    cwd - current working directory on remote server

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self;
  if ( ref($_[0]) ) {
    $self = shift;
  } else {
    $self = {
              'host'        => shift,
              'user'        => ( scalar(@_) ? shift : '' ),
              'interactive' => 0,
              'cwd'         => '',
            };
  }
  bless($self, $class);
}

=item login [USER]

Compatibility method.  Optionally sets the user.

=cut

sub login {
  my($self, $user) = @_;
  $self->{'user'} = $user if $user;
}

=item cwd CWD

Sets the cwd (used for a subsequent get or put request without a full pathname).

=cut

sub cwd {
  my($self, $cwd) = @_;
  $self->{'cwd'} = $cwd || '/';
}

=item get REMOTE_FILE [, LOCAL_FILE]

Uses scp to transfer REMOTE_FILE from the remote host.  If a local filename is
omitted, uses the basename of the remote file.

=cut

sub get {
  my($self, $remote, $local) = @_;
  $remote = $self->{'cwd'}. "/$remote" if $self->{'cwd'} && $remote !~ /^\//;
  $local ||= basename($remote);
  my $source = $self->{'host'}. ":$remote";
  $source = $self->{'user'}. '@'. $source if $self->{'user'};
  $self->scp($source,$local);
}

=item mkdir DIRECTORY

Makes a directory on the remote server.  Returns false and sets the B<errstr>
attribute on errors.

(Implementation note: An ssh connection is established to the remote machine
and '/bin/mkdir B<-p>' is used to create the directory.)

=cut

sub mkdir {
  my($self, $directory) = @_;
  $directory = $self->{'cwd'}. "/$directory"
    if $self->{'cwd'} && $directory !~ /^\//;
  my $host = $self->{'host'};
  $host = $self->{'user'}. '@'. $host if $self->{'user'};
  my($reader, $writer, $error ) =
    ( new IO::Handle, new IO::Handle, new IO::Handle );
  $writer->autoflush(1);
  my $pid = sshopen3( $host, $writer, $reader, $error,
                      '/bin/mkdir', '-p ', shell_quote($directory) );
  waitpid $pid, 0;
  if ( $? >> 8 ) {
    chomp(my $errstr = <$error> || '');
    $self->{errstr} = $errstr || "mkdir exited with status ". ($?>>8);
    return 0;
  }
  1;
}

=item size FILE

Returns the size in bytes for the given file as stored on the remote server.
Returns 0 on error, and sets the B<errstr> attribute.  In the case of an actual
zero-length file on the remote server, the special value '0e0' is returned,
which evaluates to zero when used as a number, but is true.

(Implementation note: An ssh connection is established to the remote machine
and wc is used to determine the file size.)

=cut

sub size {
  my($self, $file) = @_;
  $file = $self->{'cwd'}. "/$file" if $self->{'cwd'} && $file !~ /^\//;
  my $host = $self->{'host'};
  $host = $self->{'user'}. '@'. $host if $self->{'user'};
  my($reader, $writer, $error ) =
    ( new IO::Handle, new IO::Handle, new IO::Handle );
  $writer->autoflush(1);
  #sshopen2($host, $reader, $writer, 'wc', '-c ', shell_quote($file) );
  my $pid =
    sshopen3($host, $writer, $reader, $error, 'wc', '-c ', shell_quote($file) );
  waitpid $pid, 0;
  if ( $? >> 8 ) {
    chomp(my $errstr = <$error>);
    $self->{errstr} = $errstr || "wc exited with status ". $?>>8;
    0;
  } else {
    chomp( my $size = <$reader> || 0 );
    if ( $size =~ /^\s*(\d+)/ ) {
      $1 ? $1 : '0e0';
    } else {
      $self->{errstr} = "unparsable output from remote wc: $size";
      0;
    }
  }
}

=item put LOCAL_FILE [, REMOTE_FILE]

Uses scp to trasnfer LOCAL_FILE to the remote host.  If a remote filename is
omitted, uses the basename of the local file.

=cut

sub put {
  my($self, $local, $remote) = @_;
  $remote ||= basename($local);
  $remote = $self->{'cwd'}. "/$remote" if $self->{'cwd'} && $remote !~ /^\//;
  my $dest = $self->{'host'}. ":$remote";
  $dest = $self->{'user'}. '@'. $dest if $self->{'user'};
  warn "scp $local $dest\n" if $DEBUG;
  $self->scp($local, $dest);
}

=item binary

Compatibility method: does nothing; returns true.

=cut

sub binary { 1; }

=item quit

Compatibility method: does nothing; returns true.

=cut

sub quit { 1; }

=back

=head1 FREQUENTLY ASKED QUESTIONS

Q: How do you supply a password to connect with ssh within a perl script
using the Net::SSH module?

A: You don't (at least not with this module).  Use RSA or DSA keys.  See the
   quick help in the next section and the ssh-keygen(1) manpage.

A #2: See L<Net::SCP::Expect> instead.

Q: My script is "leaking" scp processes.

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

Could really use a maintainer with enough time to at least review and apply
patches more patches.  Or the module should just be deprecated in favor of
Net::SFTP::Expect or Net::SFTP::Foreign and made into a simple compatiblity
wrapper.

Ivan Kohler <ivan-netscp_pod@420.am>

Major updates Anthony Deaver <bishop@projectmagnus.org>

Thanks to Jon Gunnip <jon@soundbite.com> for fixing a bug with size().

Patch for the mkdir method by Anthony Awtrey <tony@awtrey.com>.

Thanks to terrence brannon <tbone@directsynergy.com> for the documentation in
the GENERATING AND USING SSH KEYS section.

=head1 COPYRIGHT

Copyright (c) 2000 Ivan Kohler
Copyright (c) 2007 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

Still has no-OO cruft.

In order to work around some problems with commercial SSH2, if the source file
is on the local system, and is not a directory, the B<-r> flag is omitted.
It's probably better just to use OpenSSH <http://www.openssh.com/> which is
the de-facto standard these days anyway.

The Net::FTP-style OO stuff is kinda lame.  And incomplete.

iscp doesnt expect you to be logging into the box that you are copying to
for the first time. so it's completely clueless about how to handle  the
whole 'add this file to known hosts' message so it just hangs after the
user hits y.  (Thanks to John L. Utz III).  To avoid this, SSH to the box
once first.

=head1 SEE ALSO

For a perl implementation that does not require the system B<scp> command, see
L<Net::SFTP> instead.

For a wrapper version that allows you to use passwords, see L<Net::SCP::Expect>
instead.

For a wrapper version of the newer SFTP protocol, see L<Net::SFTP::Foreign>
instead.

L<Net::SSH>, L<Net::SSH::Perl>, L<Net::SSH::Expect>, L<Net::SSH2>,
L<IPC::PerlSSH>

scp(1), ssh(1), L<IO::File>, L<IPC::Open2>, L<IPC::Open3>

=cut

1;


