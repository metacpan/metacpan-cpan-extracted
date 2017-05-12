#!/usr/bin/perl -w

package SVN::Notify::Mirror::SSH;
use strict;

BEGIN {
    use vars qw ($VERSION);
    use base qw(SVN::Notify::Mirror);
    $VERSION = '0.040';
    $VERSION = eval $VERSION;
}

__PACKAGE__->register_attributes(
    'ssh_host'     => 'ssh-host=s',
    'ssh_user'     => 'ssh-user:s',
    'ssh_tunnel'   => 'ssh-tunnel:s',
    'ssh_identity' => 'ssh-identity:s',
    'ssh_options'  => 'ssh-options:s',
);

sub _cd_run {
    my ($self, $path, $binary, $command, @args) = @_;
    eval "use Net::SSH qw(sshopen2)";
    die "Failed to load Net::SSH: $@" if $@;
    my $host = $self->{'ssh_host'};
    my $user = 
    	defined $self->{'ssh_user'} 
    	? $self->{'ssh_user'}.'@'.$host
	: $host;
    my @message;

    unshift @args, $binary, $command;
    $path =~ s/'/'"'"'/g; # quote single quotes
    my $cmd  = "cd '$path' && " . join(" ",@args); # wrap path in single quotes
    if ( defined $self->{'ssh_tunnel'} ) {
	if ( $self->{'ssh_tunnel'} =~ m/\d+:.+:\d+/ ) { 
	    # user-supplied configuration 
	    push @Net::SSH::ssh_options,
		'-R'.$self->{'ssh_tunnel'}, '-q';
	}
	else {
	    # default svnserve configuration
	    push @Net::SSH::ssh_options, 
		"-R3690:".$self->{'ssh_tunnel'}.":3690";
	}
    }
    if ( defined $self->{'ssh_identity'} ) {
	push @Net::SSH::ssh_options,
		"-i".$self->{'ssh_identity'};
    }
    if ( defined $self->{'ssh_options'} ) {
	push @Net::SSH::ssh_options,
	    split(" ",$self->{'ssh_options'});
    }

    sshopen2($user, *READER, *WRITER, $cmd) || die "ssh: $!";

    while (<READER>) {
	chomp;
	push @message, $_;
    }

    close(READER);
    close(WRITER);
    return (@message);
}

1;

__END__
########################################### main pod documentation begin ##

=head1 NAME

SVN::Notify::Mirror::SSH - Mirror a repository path via SSH

=head1 SYNOPSIS

Use F<svnnotify> in F<post-commit>:

  svnnotify --repos-path "$1" --revision "$2" \
   --handler Mirror::SSH --to "/path/to/www/htdocs" \
   [--svn-binary /full/path/to/svn] \
   [[--ssh-host remote_host] [--ssh-user remote_user] \
   [--ssh-tunnel 10.0.0.2] \
   [--ssh-identity /home/user/.ssh/id_rsa]]

or better yet, use L<SVN::Notify::Config> for a more
sophisticated setup:

  #!/usr/bin/perl -MSVN::Notify::Config=$0
  --- #YAML:1.0
  '':
    PATH: "/usr/bin:/usr/local/bin"
  'path/in/repository':
    handler: Mirror
    to: "/path/to/www/htdocs"
  'some/other/path/in/repository':
    handler: Mirror::SSH
    to: "/path/to/remote/www/htdocs"
    ssh-host: "remote_host"
    ssh-user: "remote_user"
    ssh-tunnel: "10.0.0.2"
    ssh-identity: "/home/user/.ssh/id_rsa"

=head1 DESCRIPTION

Keep a directory in sync with a portion of a Subversion repository.
Typically used to keep a development web server in sync with the changes
made to the repository.  This directory can either be on the same box as
the repository itself, or it can be remote (via SSH connection).

=head1 USAGE

Depending on whether the target is a L<Local Mirror> or a L<Remote
Mirror>, there are different options available.  All options are
available either as a commandline option to svnnotify or as a hash
key in L<SVN::Notify::Config> (see their respective documentation for
more details).

=head2 Working Copy on Mirror

Because 'svn export' is not able to be consistently updated, the
sync'd directory must be a full working copy, and if you are running
Apache, you should add lines like the following to your Apache
configuration file:

  # Disallow browsing of Subversion working copy
  # administrative directories.
  <DirectoryMatch "^/.*/\.svn/">
   Order deny,allow
   Deny from all
  </DirectoryMatch>
  
The files in the working copy must be writeable (preferrably owned)
by the user identity executing the hook script (this is the user 
identity that is running Apache or svnserve respectively).

=head1 Local Mirror

Please see L< SVN::Notify::Mirror > for details.

=head2 Remote Mirror

Used for directories not located on the same machine as the
repository itself.  Typically, this might be a production web
server located in a DMZ, so special consideration must be paid
to security concerns.  In particular, the remote mirror server
may not be able to directly access the repository box.

NOTE: be sure and consult L<Remote Mirror Pre-requisites>
before configuring your post-commit hook.

=over 4

=item * ssh-host

This value is required and must be the hostname or IP address
of the remote host (where the mirror directories reside).

=item * ssh-user

This value is optional and specifies the remote username that
owns the working copy mirror.

=item * ssh-identity

This value may be optional and should be the full path to the
local identity file being used to authenticate with the remote
host. If you are setting the ssh-user to be something other than
the local user name, you will typically also have to set the
ssh-identity.

=item * ssh-tunnel

If the remote server does not have direct access to the repository
server, it is possible to use the tunneling capabilities of SSH
to provide temporary access to the repository.  This works even 
if repository is located internally, and the remote server is 
located outside of a firewall or on a DMZ.

The value passed for ssh-tunnel should be the IP address to which the
local repository service is bound (when using svnserve).  This will
tunnel port 3690 from the repository box to localhost:3690 on the
remote box.  This must also be the way that the original working copy
was checked out (see below).

To tunnel some other port, for example when using Apache/mod_dav,
ssh-tunnel should be the entire mapping expression, as described in the
OpenSSH documentation under the C<-R> option (remote port forwarding).  
For most sites, passing C<8080:10.0.0.2:80> will work (which will tunnel
port 80 from the repository to port 8080 on the remote client).  If you are
using SSL with Apache, you can use e.g. C<80443:10.0.0.2:443>.

For example, see L<Remote Mirror Pre-requisites> and after step #6,
perform the following additional steps (when using svnserve):

  # su - localuser
  $ ssh -i .ssh/id_rsa remote_user@remote_host -R3690:10.0.0.2:3690
  $ cd /path/to/mirror/working/copy
  $ svn co svn://127.0.0.1/repos/path/to/files .

where 10.0.0.2 is the IP address hosting the repository service.  For the
same configuration when using Apache/mod_dav, do this instead:

  # su - localuser
  $ ssh -i .ssh/id_rsa remote_user@remote_host -R8080:10.0.0.2:80
  $ cd /path/to/mirror/working/copy
  $ svn co http://127.0.0.1:8080/repos/path/to/files .

=item * ssh-options

If you have any other options that you would like to pass to the ssh
client (for example to change the default SSH port), you can pass extra
options using this parameter.  Be sure that you pass it a string that 
has ssh long option/value pairs separated by a space, or short options
without any space at all.  Internally, parameter is split on spaces and
passed in the @Net::SSH::options array.

=back

=head2 Remote Mirror Pre-requisites

Before you can configure a remote mirror, you need to produce
an SSH identity file to use:

=over 4

=item 1. Log in as repository user

Give the user identity being used to execute the hook scripts 
(the user running Apache or svnserve) a shell and log in as 
that user, e.g. C<su - svn>;

=item 2. Create SSH identity files on repository machine

Run C<ssh-keygen> and create an identity file (without a password).

=item 3. Log in as remote user

Perform the same steps as #1, but this time on the remote machine.
This username doesn't have to be the same as in step #1, but it
must be a user with full write access to the mirror working copy.

=item 4. Create SSH identity files on remote machine

It is usually more efficient to go ahead and use C<ssh-keygen> to
create the .ssh folder in the home directory of the remote user.

=item 5. Copy the public key from local to remote

Copy the .ssh/id_dsa.pub (or id_rsa.pub if you created an RSA key)
to the remote server and add it to the .ssh/authorized_keys for
the remote user.  See the SSH documentation for instructions on
how to configure 

=item 6. Confirm configuration

As the repository user, confirm that you can sucessfully connect to
the remote account, e.g.:

  # su - local_user
  $ ssh -i .ssh/id_rsa remote_user@remote_host

This is actually a good time to either check out the working copy
or to confirm that the remote account has rights to update the
working copy mirror.  If the remote server does not have direct
network access to the repository server, you can use the tunnel
facility of SSH (see L<ssh-tunnel> above) to provide access (e.g.
through a firewall).

=back

Once you have set up the various accounts, you are ready to set
your options.

=over 4

=head1 AUTHOR

John Peacock <jpeacock@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 John Peacock

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<SVN::Notify>, L<SVN::Notify::Config>, L<SVN::Notify::Mirror>

=cut

############################################# main pod documentation end ##
