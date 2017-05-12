#
# PDSH.pm
#
# Interface for Parallel Distributed shell
#
package Net::PDSH;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $pdsh $equalspace $DEBUG @pdsh_options 
            $list_options $set_credentials $set_batch_mode $set_connect_timeout 
            $set_command_timeout $set_fanout $set_remote_command $list_modules);

use Exporter;
use POSIX ":sys_wait_h";
use IO::File;
use IO::Select;
use IPC::Open2;
use IPC::Open3;
use Data::Dumper;
use String::Util ':all';

@ISA = qw(Exporter);
@EXPORT_OK = qw(pdsh pdsh_cmd pdshopen2 pdshopen3 list_options pdsh_options
                DEBUG set_batch_mode set_credentials set_connect_timeout
                set_command_timeout set_fanout set_remote_commmand
                list_moodules);
$VERSION = '0.01';

$DEBUG = 1;

$pdsh = "pdsh";
$list_options = "list_options";
$list_modules= "list_modules";
$set_remote_command = "set_remote_command";
$set_credentials = "set_credentials"; 
$set_batch_mode = "set_batch_mode";
$set_connect_timeout = "set_connect_timeout";
$set_command_timeout = "set_command_timeout";
$set_fanout = "set_fanout";
$set_remote_command = "set_remote_command";
$list_modules = "list_modules";

sub new {
  my($class,%args) = @_;
  my $self = {};
  bless($self,$class);
  $self->{_DEBUG} = 0;
  $self->{_pdsh_options} = 0;
  $self->{_batch_mode} = 0;
  $self->{_user} = "";
  $self->{_connect_timeout} = 0;
  $self->{_command_timeout} = 0;
  $self->{_fanout} = 0;
  $self->{_rcmd} = "";
  return $self;
}


=head1 NAME

Net::PDSH - Perl extension for parallel distributed shell

=head1 SYNOPSIS

  use Net::PDSH;

  my $pdsh = Net::PDSH->new;

  $pdsh->pdsh("remotehost", "/bin/ls");

  cmd( [
   { 
    user => 'user',
    host => 'host.name,host.name,...',
    command => 'command',
    args => [ '-arg1', '-arg2' ],
    stdin_string => "string\n",
   },
   { 
    user => 'user',
    host => 'host.name,host.name,...',
    command => 'command',
    args => [ '-arg1', '-arg2' ],
    stdin_string => "string\n",
   }
   ]
 );

=head1 DESCRIPTION

Simple wrappers around pdsh commands.

=over 

=cut

sub pdsh {
  my($self, $host, @command) = @_;
  our(@pdsh_options);
  if ($self->{_rcmd} ne "") {
    push @pdsh_options, ("-R", $self->{_rcmd});
  } else {
    push @pdsh_options, ("-R", "exec") if $DEBUG == 1;
  }
  if ($self->{_user} ne "") {
    push @pdsh_options, ("-l", $self->{_user});
  }
  if ($self->{_connect_timeout} != 0) {
    push @pdsh_options, ("-t", $self->{_connect_timeout});
  }
  if ($self->{_command_timeout} != 0 ) {
    push @pdsh_options, ("-u", $self->{_command_timeout});
  }
  my @cmd = ($pdsh, @pdsh_options, "-w $host", @command);
  warn "[Net::PDSH::pdsh] executing ". join(' ', @cmd). "\n"
    if $DEBUG;
  @cmd = join(' ', @cmd);
  system(@cmd);
}

=item cmd 

Calls pdsh in batch mode.  Throws a fatal error if data occurs on the command's
STDERR.  Returns any data from the command's STDOUT.

If using the hashref-style of passing arguments, possible keys are:

  host (requried)
  command (required)
  args (optional, arrayref)
  stdin_string (optional) - written to the command's STDIN

=cut
sub cmd {
  my $self = shift;
  my @command_list = @_;
  my %pids;
  our @pdsh_options;
  my @pdsh_version = &_pdsh_options unless @pdsh_options;

  my $reader = IO::File->new();
  my $writer = IO::File->new();
  my $error  = IO::File->new();
  foreach (@command_list) {
    my %cmd = %$_;
    # print "Executing:" . $cmd{hostname}. " = =============". Dumper($cmd{command})."=========\n";
    if ($self->{_rcmd} ne "") {
      push @pdsh_options, ("-R", $self->{_rcmd});
    } else {
      push @pdsh_options, ("-R", "exec") if $DEBUG == 1;
    }
    if ($self->{_user} ne "") {
      push @pdsh_options, ("-l", $self->{_user});
    }
    if ($self->{_connect_timeout} != 0) {
      push @pdsh_options, ("-t", $self->{_connect_timeout});
    }
    if ($self->{_command_timeout} != 0) {
      push @pdsh_options, ("-u", $self->{_command_timeout});
    }
    if ($DEBUG == 1) {
      push @pdsh_options, ("-d") ;
    }
    my @cmd2 = $cmd{command};
    my @arguments = $cmd{arguments};
    my $pid = pdshopen3($cmd{hostname}, $writer, $reader, $error, @cmd2);
    waitpid($pid, WNOHANG);
    my $buffer;
    while(<$reader>) {
      my $buffer1 = $_;
      my @buffer2 = split(" ", $buffer1);
      $buffer = $buffer . "\n" .$buffer2[1];
    }
    $pids{$pid} = $buffer;
    
  }
  return %pids;
}

sub pdshopen2 {
  my($host, $reader, $writer, @command) = @_;
  @pdsh_options = &_pdsh_options unless @pdsh_options;
  open2($reader, $writer, $pdsh, @pdsh_options, $host, @command);
}

sub pdshopen3 {
  my($host, $writer, $reader, $error, $command) = @_;
  @pdsh_options = &_pdsh_options unless @pdsh_options;
  my @cmd1 = @pdsh_options;
  my $end = $#$command;
  my $i = 0;
  while($i <= $end) {
    push @cmd1, @$command[$i];
    $i = $i + 1;
  }
 
  open3($writer, $reader, $error, $pdsh, @pdsh_options, "-w $host", @cmd1);
}

sub _yesno {
  print "Proceed [y/N]:";
  my $x = scalar(<STDIN>);
  $x =~ /^y/i;
}

sub _pdsh_options {
  my $reader = IO::File->new();
  my $writer = IO::File->new();
  my $error  = IO::File->new();
  open3($writer, $reader, $error, $pdsh, '-V');
  my $pdsh_version = <$reader>;
  chomp($pdsh_version);
  $pdsh_version = split(" ", $pdsh_version);
  $equalspace = " ";
  my @options = ""; 
# ( '-V', $pdsh_version );
  @pdsh_options;
}


=item set_batch_mode

Executes pdsh in batchmode

Input: 0/1

=cut

sub set_batch_mode {
  my ($self, $batch_mode) = @_;
  $self->{_batch_mode} = $batch_mode;
  return $self->{_batch_mode};
}

=item set_credentials

Executes pdsh under a given user. All the further commands would be executed as that user.

Input: username

=cut

sub set_credentials {
  my ($self, $user) = @_;
  $self->{_user} = $user;
  return $self->{_user};
}

sub set_connect_timeout {
  my ($self, $val) = @_;
  $self->{_connect_timeout} = $val;
  return $self->{_connect_timeout};
}
sub set_command_timeout {
  my ($self, $val) = @_;
  $self->{_command_timeout} = $val;
  return $self->{_command_timeout};
}
sub set_fanout {
  my ($self, $val) = @_;
  $self->{_fanout} = $val;
  return $self->{_fanout};
}
sub set_remote_command {
  my ($self, $val) = @_;
  $self->{_rcmd} = $val;
  return $self->{_rcmd};
}

sub list_modules {
  my($self, $host) = @_;
  my @pdsh_version = &_pdsh_options unless @pdsh_options;
  use vars qw(@pdsh_options);
  my @cmd = ($pdsh, @pdsh_options, "-w $host -L");
  @cmd = join(' ', @cmd);
  my $options = `@cmd`;
  my @options = split '\n',$options;
  my %options;
nextoption:  foreach (@options) {
    my @val2 = split(':', $_);
    my $key = @val2[0];
    my $val = @val2[1];
    next nextoption if((trim($key) eq '') || (trim($key) =~ /^--/)) ; 
    $options{trim($key)} = trim($val);
  }
  return %options;
}

sub list_options {
  my($self, $host) = @_;
  my @pdsh_version = &_pdsh_options unless @pdsh_options;
  use vars qw(@pdsh_options);
  my @cmd = ($pdsh, @pdsh_options, "-w $host -q");
  @cmd = join(' ', @cmd);
  my $options = `@cmd`;
  my @options = split '\n',$options;
  my %options;
nextoption:  foreach (@options) {
    my $val2 = join('        ', split('\t', $_));
    my $key = substr $val2, 0, 24;
    my $val = substr $val2, 24, 100;
    next nextoption if((trim($key) eq '') || (trim($key) =~ /^--/)) ; 
    $options{trim($key)} = trim($val);
  }
  return %options;
}


=back

=head1 EXAMPLE

  my @cmd_arr = (
  { "hostname" => "remotehost1,remotehost2",
    "command" =>  ["/bin/cat", "/tmp/fsck.log", "/etc/hosts", ],
  },
  { "hostname" => "remotehost3",
    "command" =>  ["/bin/cat", "/etc/sysconfig/network",],
  },
  );
  my %pids = $pdsh->cmd(@cmd_arr);

  This would execute "cat /tmp/fsck.log /etc/hosts" on remotehost1 and remotehost2
  and it would execute "cat /etc/sysconfig/network" on remotehost3

  It would return the output in %pids hash table where keys are pids and values are
  output contents

=head1 FREQUENTLY ASKED QUESTIONS

Q: How do you supply a password to connect with pdsh within a perl script
using the Net::PDSH module?

A: You don't (at least not with this module).  Use RSA or DSA keys.  See the
   quick help in the next section and the ssh-keygen(1) manpage.

A #2: See L<Net::SSH::Expect> instead.

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
   Enter file in which to save the key (/home/User/.pdsh/id_rsa):
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:

   Your identification will be saved in /home/User/.ssh/id_rsa
   Your public key will be saved in /home/User/.ssh/id_rsa.pub

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

Aditya Pandit <adityaspandit@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 SEE ALSO

L<Net::SSH::Perl>,  L<Net::SSH::Expect>, L<Net::SSH2>, L<IPC::PerlSSH>,  pdsh(1)

=cut

1;

