#!/usr/bin/perl -w

package SVN::Notify::Mirror::Rsync;

use strict;

BEGIN {
    use vars qw ($VERSION);
    use base qw(SVN::Notify::Mirror);
    $VERSION = '0.040';
    $VERSION = eval $VERSION;
}

__PACKAGE__->register_attributes(
     'rsync_host'   => 'rsync-host=s',
     'rsync_args'   => 'rsync-args=s%',
     'rsync_dest'   => 'rsync-dest=s',
     'rsync_delete' => 'rsync-delete',
     'rsync_ssh'    => 'rsync-ssh',
     'ssh_user'     => 'ssh-user:s',
     'ssh_binary'   => 'ssh-binary:s',
     'ssh_identity' => 'ssh-identity:s',
     'ssh_options'  => 'ssh-options:s',
);

sub _cd_run {
     my ($self, $path, $binary, $command, @args) = @_;
     my @message = $self->SUPER::_cd_run($path, $binary, $command, @args);
     eval "use File::Rsync";
     die "Failed to load File::Rsync: $@" if $@;

     my $host = $self->{'rsync_host'} || 'localhost';
     my $dest = $self->{'rsync_dest'} || $path;

     # Set some common arguments to pass to new()
     my $args;
     if ( defined $self->{'rsync_args'} ) {
	 $args = $self->{'rsync_args'};
     }
     else {
	 $args = {
	     archive => 1, 
	     compress => 1,
	 };
     }

     $args->{delete} = 1
	 unless defined $self->{'rsync_delete'} 
	 	and $self->{'rsync_delete'} == 0;
     push @{$args->{'exclude'}}, '.svn';

#     $args->{debug} = 1;

     # define the ssh options if necessary
     if ( defined $self->{'rsync_ssh'} ) {

	 # Check for various ssh options
	 my $ssh_binary   = (defined $self->{'ssh_binary'} 
	 			? $self->{'ssh_binary'}
				: '/usr/bin/ssh');
	 my $ssh_user     = (defined $self->{'ssh_user'}
	 			? $self->{'ssh_user'}
				: "");
	 my $ssh_identity = (defined $self->{'ssh_identity'} 
	 			? $self->{'ssh_identity'}
				: "");
	 my $ssh_options  = (defined $self->{'ssh_options'}
	 			? $self->{'ssh_options'}
				: "");

	 $args->{'rsh'} = 
	 	   $ssh_binary
	 	. ($ssh_user     ? " -l $ssh_user"     : "")
		. ($ssh_identity ? " -i $ssh_identity" : "")
		. ($ssh_options  ? " $ssh_options"     : "");
     }

     my $rsync = File::Rsync->new($args);
     $rsync->exec(
     	{ 
	    src => $path."/", 
	    dest => "$host:$dest", 
	})
         or push @message, "rsync failed:\n" . join("\n",$rsync->err);

     return (@message);
}

1;

__END__
########################################### main pod documentation begin ##

=head1 NAME

SVN::Notify::Mirror::Rsync - Mirror a repository path via Rsync

=head1 SYNOPSIS

Use F<svnnotify> in F<post-commit>:

  svnnotify --repos-path "$1" --revision "$2" \
   --handler Mirror::Rsync --to "/path/to/local/htdocs" \
   [--svn-binary /full/path/to/svn] \
   --rsync-host remote_server \
   [--rsync-delete=[yes|no]] \
   [--rsync-dest "/path/on/remote/server"] \
   [--rsync-args arg1 [--rsync-args arg2...]]
   [[--rsync-ssh] [--ssh-user remote_user] \
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
    handler: Mirror
    to: "/path/to/local/www/htdocs"
    rsync-host: "remote_host"
    rsync-dest: "/path/on/remote/www/htdocs"
    ssh-user: "remote_user"
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

=head2 Working Copy on Local host

Because 'svn export' is not able to be consistently updated, the
local rsync'd directory must be a full working copy.  The remote server
will only contain the ordinary files (no Subversion admin files).

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

=over 4

=item * rsync-host

This value is required and must be the hostname or IP address
of the remote host (where the mirror directories reside).

=item * rsync-delete

The default mode of operation is to delete remote files which are
not present in the local working copy.  NOTE: this will B<delete>
any unversioned files in the remote directory tree.  Unless you
have all of your files under version control, you should pass the 
C<--no-rsync-delete> or C<--rsync-delete no> option.

=item * rsync-dest

This optional value specifies the path to update on the remote
host.  If you do not specify this value, the same path as passed
in as the C<--to> parameter will be used (this may not be what you
meant to do).

=item * rsync-args

This optional parameter can be used to pass additional commandline
options to the rsync command.  You can use this multiple times in
order to pass multiple options.  The default args are C<--archive 
--compress>.  See the C<rsync-ssh> options for using SSH instead of
RSH (rather than pass those commands via C<--rsync-args>

=item * rsync-ssh

This optional parameter signals that you wish to use SSH instead of
whatever the default remote shell program is configured in your
copy of rsync.  You may need to set one or more of the C<ssh-*>
parameters as well.

=item * ssh-user

If the remote user is different than the local user executing the
postcommit script, you can specify it with this parameter.  You would
often use this in conjunction with the next parameter.

=item * ssh-identity

This value may be optional and should be the full path to the
local identity file being used to authenticate with the remote
host. If you are setting the ssh-user to be something other than
the local user name, you will typically also have to set the
ssh-identity.

=back

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
