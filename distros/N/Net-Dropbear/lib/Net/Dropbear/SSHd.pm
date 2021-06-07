package Net::Dropbear::SSHd;

use strict;
use v5.8;
our $VERSION = '0.14';

use Child;

use autodie;
use Carp;
use Try::Tiny;
use Moo;
use Types::Standard qw/ArrayRef HashRef GlobRef Str Int Bool InstanceOf/;

has addrs => (
  is => 'rw',
  isa => ArrayRef[Str],
  coerce => sub { ref $_[0] ? $_[0] : [ $_[0] ] },
);

has keys => (
  is => 'rw',
  isa => ArrayRef[Str],
  coerce => sub {
    my $value = shift;
    $value = ref $value ? $value : [ $value ];
    foreach my $key ( @$value )
    {
      carp "Key file does not exist: $key"
        if !-e $key;
    }
    return $value;
  },
);

has hooks => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} },
);

has debug          => ( is => "rw", isa => Bool, default => 0, );
has forkbg         => ( is => "rw", isa => Bool, default => 0, );
has usingsyslog    => ( is => "rw", isa => Bool, default => 0, );
has inetdmode      => ( is => "rw", isa => Bool, default => 0, );
has norootlogin    => ( is => "rw", isa => Bool, default => 1, );
has noauthpass     => ( is => "rw", isa => Bool, default => 1, );
has norootpass     => ( is => "rw", isa => Bool, default => 1, );
has allowblankpass => ( is => "rw", isa => Bool, default => 0, );
has delay_hostkey  => ( is => "rw", isa => Bool, default => 0, );
has domotd         => ( is => "rw", isa => Bool, default => 0, );
has noremotetcp    => ( is => "rw", isa => Bool, default => 1, );
has nolocaltcp     => ( is => "rw", isa => Bool, default => 1, );

has child => (
  is => 'rwp',
  isa => InstanceOf['Child::Link::Proc'],
);

has comm => (
  is => 'rwp',
  isa => GlobRef,
);

our $_will_run_as_root = 0;

my $tell_parent;

sub is_running
{
  my $self = shift;
  return defined $self->child;
}

sub run
{
  my $self = shift;
  my $child_hook = shift;

  if (defined $child_hook && ref $child_hook ne 'CODE')
  {
    croak '$child_hook was not a code ref when calling run';
  }

  use Socket;
  use IO::Handle;
  socketpair(my $child_comm, my $parent_comm, AF_UNIX, SOCK_STREAM, PF_UNSPEC);

  my $child = Child->new(sub {
    my $parent = shift;
    $0 .= " [Net::Dropbear Child]";

    $self->_set_comm($child_comm);

    $tell_parent = sub
    {
      # Tell the parent we're ready by writing to the socket we normally read
      # from.
      $parent_comm->print("\n");
      $parent_comm->close;
    };

    require Net::Dropbear::XS;

    Net::Dropbear::XS->setup_svr_opts($self);

    $child_hook->($parent)
      if defined $child_hook;

    Net::Dropbear::XS->svr_main();

    # Should never return
    croak 'Unexpected return from dropbear';
  });

  $self->_set_child($child->start);
  $self->_set_comm($parent_comm);

  # Wait for child to come up by reading from the socket we normally close
  $child_comm->getline;
  $child_comm->close;

  return;
}

sub stop
{
  my $self = shift;
  if ($self->is_running)
  {
    $self->child->kill(15);
  }
}

sub wait
{
  my $self = shift;
  if ($self->is_running)
  {
    try { $self->child->wait };
  }
}

sub auto_hook
{
  my $self = shift;
  my $hook = shift;

  if ($hook eq 'on_start' && ref $tell_parent eq 'CODE')
  {
    $tell_parent->();
    undef $tell_parent;
  }

  if (exists $self->hooks->{$hook})
  {
    return $self->hooks->{$hook}->(@_);
  }

  return Net::Dropbear::XS::HOOK_CONTINUE();
}

sub import
{
  require Net::Dropbear::XS;
  Net::Dropbear::XS->export_to_level(1, @_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::Dropbear::SSHd - Embed and control a Dropbear SSH server inside of perl

=head1 SYNOPSIS

  use Net::Dropbear::SSHd;
  
  Net::Dropbear::XS::gen_key($key_filename);
  
  my $sshd = Net::Dropbear::SSHd->new(
    addrs      => '2222',
    keys       => $key_filename,
    hooks      => {
      on_log => sub
      {
        my $priority = shift;
        my $msg      = shift;
        warn( "$msg\n" );
        return HOOK_CONTINUE;
      },
    }
  );
  
  $sshd->run;
  $sshd->wait;

=head1 DESCRIPTION

Net::Dropbear::SSHd allows you to embed and control an SSH server (using Dropbear) from perl.

=head2 Motivation

Maybe you're asking yourself why you'd want to do that? Imagine that you want
to run a service where you let users run remote commands over SSH, say SFTP
or git. Also imagine that you'd like maintain the users or public keys in a
database instead of in a file.  A good example of this behavior would be
Github and other cloud-based git-over-ssh solutions.

I'm pretty confident that one could get OpenSSH to do this, but I saw a couple
problems:

=over

=item The user must be a real user

Any user that wants to connect must be a real user at the OS level. Managing
multiple users, let alone millions, is a nightmare.

=item OpenSSH really likes running as root

Until recently, running as non-root was even possible. It's now possible,
but a lot of interesting features are restricted.

=item Authorized keys can be provided through a script owned by root

A continuation of the point above, but in order to enable OpenSSH to verify
a key, a script can be provided. This script (and all directories leading
to the script) must be owned by root.

=item OpenSSH (and SSH) have a lot of options

And while that is a good thing in general, in this particular case I was not
confident that I could tune all the options correctly to make sure I wasn't
completely securing the system.

=back

I really didn't want to provide outside users with a clever way to
gain access to my machine. That's where this module comes into play. The goal
of C<Net::Dropbear::SSHd> is that you can control the entire lifecycle of
SSHd, including which usernames are accpeted, which public keys are authorized
and what commands are ran.

=head1 CONSTRUCTOR

=head2 new

  my $sshd = Net::Dropbear::SSHd->new({ %params });

Returns a new C<Net::Dropbear::SSHd> object.

=head3 Attributes

=over

=item addrs

A string or an array of addresses to bind to. B<Default>: Nothing

=item keys

An array of strings that are the server keys for Dropbear. B<Default>:
Generate keys automatically

=item hooks

A hashref of coderef's that get called during key points of the SSH server
session. See L</Hooks>.

=back

=head3 Dropbear options

=over

=item debug

B<Default:> off

If Dropbear is complied with trace debuging turned on (not the default),
turning this on will enable Dropbear's debugging information to be dumped.

=item forkbg

B<Default:> off

Turning the forkbg option on means that Dropbear will fork into the
background. Since Net::Dropbear::SSHd forks to run the main Dropbear code,
doing this second fork would seem redundant.

=item usingsyslog

B<Default:> off

Turning the usingsyslog option on means Dropbear will use syslog to output
it's logs. Regardless of this setting, the on_log hook will still be called.

=item norootlogin

B<Default:> on

Turning the norootlogin option on means that root can not login.

=item noauthpass

B<Default:> on

Turning the noauthpass option on means that password authentication is not
allowed

=item norootpass

B<Default:> on

Turning the norootpass option on means that root cannot authenticate using
a password.

=item allowblankpass

B<Default:> off

Turning the allowblankpass option on means that if the SSH client requests it,
Dropbear will authenticate someone with a blank password.

=item delay_hostkey

B<Default:> off

Turning the delay_hostkey option on tells Dropbear to not generate hostkey
files until the first user connects.  This allows for faster startup times
the very first time in exchange for a delayed connection for the very first
user.

=item domotd

B<Default:> off

Turning on the domotd option means that when an interactive session is
started, the message of the day is sent.

=item noremotetcp

B<Default:> on

Turning on the noremotetcp option means that Dropbear will not create remote
forwarded TCP tunnels.

=item nolocaltcp

B<Default:> on

Turning on the nolocaltcp option means that Dropbear will not create locally
forwarded TCP tunnels.

=back

=head3 Hooks

During the run of Dropbear, Net::Dropbear::SSHd hooks into certain points
of the processing.  With these hooks, the outcome of Dropbear can be changed.
Each hook can return one of the hook constants: L</HOOK_COMPLETE>,
L</HOOK_CONTINUE> or L</HOOK_FAILURE>.  Unless otherwise noted, returning
L</HOOK_CONTINUE> will result in Dropbear continuing as though the hook
hadn't been called. See the C<hooks> attribute.

=over

=item on_log(priority, message)

The on_log hook is called when Dropbear logs anything.

B<HOOK_COMPLETE> - No more logging will take place

B<HOOK_FAILURE> - Logging will continue as normal

=item on_start()

The on_start hook is called after Dropbear is done initalizing.

B<HOOK_COMPLETE> - Identical to HOOK_CONTINUE

B<HOOK_FAILURE> - Dropbear will exit

=item on_username(username)

The on_username hook is called when a username is given. Returning anything
but HOOK_CONTINUE from this will prevent C<on_passwd_fill> or
C<on_shadow_fill> from being called.

B<HOOK_COMPLETE> - The username is acceptable and dummy entries are used for the password file

B<HOOK_FAILURE> - The username is rejected

=item on_passwd_fill(L<AuthState|Net::Dropbear::XS::AuthState>, username)

The on_passwd_fill hook is called when Dropbear is filling in information
for a user from the passwd file.  The L<AuthState|Net::Dropbear::XS::AuthState>
paramater is an object that can be manipulated to fill in information for
Dropbear. See L<Net::Dropbear::XS::AuthState>. If any AuthState data is left
invalid, Dropbear will exit.

B<HOOK_COMPLETE> - The L<AuthState|Net::Dropbear::XS::AuthState> object should be used as the passwd information.

B<HOOK_FAILURE> - The passwd information is invalid and the user connection will be rejected.

=item on_shadow_fill(crypt_password, pw_name)

The on_shadow_fill hook is called when the shadow file is consulted for a
users password.  Note that this is called even if HOOK_COMPLETE is returned
from on_passwd_fill.  The first paramter (crypt_password) is mutable and
can be used to set what the user's crypted password is. If the crypt_password
is invalid (null), Dropbear will exit.

B<HOOK_COMPLETE> - The shadow file will not be consulted for the given user

B<HOOK_FAILURE> - Ignored

=item on_crypt_passwd(input_passwd, salt, pw_name)

The on_crypt_passwd hook is used as an opportunity to crypt the password
given by the connection yourself. It will give you the password as it was
entered, and you are expected to change $_[0] in place to a crypted version
that will match the value given in either C<on_passwd_fill> or
C<on_shadow_fill>.

B<HOOK_COMPLETE> - The crypt function doesn't need to be ran, and Dropbear can check the value of input_passwd directly.

B<HOOK_FAILURE> - Ignored

=item on_check_pubkey(authkeys, pw_name)

The on_check_pubkey hook is called right before the the public keys for a
user is checked. The first paramater, C<authkeys>, is an string that can be
populated with an L<authorized_keys(8)> file and it will be used to
authenticate the user given with pw_name.

B<HOOK_COMPLETE> - Identical to HOOK_CONTINUE

B<HOOK_FAILURE> - The public keys could not be retrieved and will not be checked.

=item on_new_channel(on_new_channel)

The on_new_channel hook is called when the client requests a new channel.
The first paramater, C<on_new_channel>, will contain the channel type as a
string.

B<HOOK_COMPLETE> - Identical to HOOK_CONTINUE

B<HOOK_FAILURE> - The channel is denied with C<SSH_OPEN_ADMINISTRATIVELY_PROHIBITED>

=item on_chansess_command(L<chansess|Net::Dropbear::XS::SessionAccept>)

The on_chansess_command hook is called when a new command is being requested
by the client.  The first paramater, L<chaness|Net::Dropbear::XS::SessionAccept>,
is an object that should be used to let Dropbear know how to interact with
the channel.  See L<Net::Dropbear::XS::SessionAccept> for more details.

B<HOOK_COMPLETE> - No attempts will be made to start the command specified

B<HOOK_CONTINUE> - The values from L<chansess|Net::Dropbear::XS::SessionAccept> will be copied into Dropbear and used in Dropbear's default operations

B<HOOK_FAILURE> - The command session will behave as though the command had vailed

=back

=head1 METHODS

=head2 run

Call C<$sshd-E<gt>run> to start Dropbear.

=head2 child

If Dropbear has been started, then this will return the L<Child::Link::Proc>
object of the child process. If Dropbear is not running, this will return
C<undef>. In the child process this will be C<undef> as well.

=head2 comm

The C<comm> method is a convience for both parent and child processes. This
contains a two-way socket between the parent and child (and sub-children)
processes.  This is a AF_UNIX socket, which means you can pass new file
handles between the processes.

=head2 is_running

Returns true if Dropbear is running, false if it's not.

=head2 stop

This will stop Dropbear.

=head2 wait

This waits for Dropbear to exit after it is sent the kill signal.

=head1 CONSTANTS

The constants below are exported by default.

=over

=item HOOK_COMPLETE

This is used to indicate that a hook is done and not to use Dropbear's default
operations.

=item HOOK_CONTINUE

This is used to indicate that the hook has decided not to do anything.

=item HOOK_FAILURE

This is used to indicate that the hook has failed and Dropbear should not
continue.

=back

=head1 CHILD PROCESSES

Since Dropbear is a program itself, it is ran as a child process.  Each
connection will also have it's own child process.

=head1 AUTHOR

Jon Gentle E<lt>atrodo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015-2016 Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

This includes a complete copy of Dropbear that is patched and used. The 
majority of Dropbear is Copyright (c) 2002-2014 Matt Johnston under the MIT
license.  See L<https://matt.ucc.asn.au/dropbear/dropbear.html> for details
about Dropbear and it's license.

=cut
