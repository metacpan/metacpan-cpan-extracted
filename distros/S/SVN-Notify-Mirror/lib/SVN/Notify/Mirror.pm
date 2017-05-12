#!/usr/bin/perl -w

package SVN::Notify::Mirror;
use base qw/SVN::Notify/;
use strict;

use vars qw ($VERSION);
$VERSION = '0.040';
$VERSION = eval $VERSION;

__PACKAGE__->register_attributes(
    'ssh_host'     => 'ssh-host=s',
    'ssh_user'     => 'ssh-user:s',
    'ssh_tunnel'   => 'ssh-tunnel:s',
    'ssh_identity' => 'ssh-identity:s',
    'svn_binary'   => 'svn-binary:s',
    'tag_regex'    => 'tag-regex:s',
    'minimal'      => 'minimal',
);

sub prepare {
    my $self = shift;
    $self->prepare_recipients;
    $self->prepare_files;
}

sub execute {
    my ($self) = @_;
    return unless defined $self->to;
    $self->svn_binary( $ENV{SVN} || SVN::Notify->find_exe('svn') )
    	unless $self->svn_binary;

    foreach my $to ( $self->to ) {
	my $command = 'update';
	my @args = (
	    -r => $self->revision,
	);  	

	# need to swap function calls for backwards compatibility for now
	if ( defined $self->ssh_host 
	     and not $self->isa('SVN::Notify::Mirror::SSH') )
	{	
	    no warnings 'redefine';
	    warn "Deprecated - please use SVN::Notify::Mirror::SSH directly";
	    require SVN::Notify::Mirror::SSH;
	    *_cd_run = \&SVN::Notify::Mirror::SSH::_cd_run;
	}

	# deal with the possible switch case
	if ( defined $self->tag_regex ) {
	    $DB::single = 1;
	    $command = 'switch';
	    my $regex = $self->tag_regex;
	    my ($tag) = grep /$regex/, @{$self->{'files'}->{'A'}};
	    $tag =~ s/^.+\/tags\/(.+)/$1/;
	    return unless $tag;
	    my @message = $self->_cd_run(
		$to,
		$self->svn_binary,
		'info',
	    );
	    my $URL = (split ": ", $message[1], 2)[1];
	    if ( $URL =~ m/^(.+\/tags\/).+$/m ) {
		my $url = $1;
		$tag = $url.$tag;
	    }
	    push @args, $tag;
	}

	if ( $self->minimal ) {
	    # perform minimal update only
	    my @paths;
	    my $prefix = $self->{'handle_path'}; # simple case
	    unless ( $prefix ) {
		# hard case
		$DB::single = 1;
		my @message = $self->_cd_run($to, $self->svn_binary, 'info');
		my $URL = (split ": ", $message[1], 2)[1];
		my $ROOT = (split ": ", $message[2], 2)[1];
		$ROOT .= '/' unless $ROOT =~ m:/$:;
		($prefix = $URL) =~ s/$ROOT//;
	    }

	    foreach my $files ( values %{ $self->files } ) {
		push @paths, map { s/$prefix// && $_ } @{ $files };
	    }
	    $to .= '/'. _shortest_path(@paths);
	}

	print join("\n", 
	    $self->_cd_run(
		$to,
		$self->svn_binary,
		$command,
		@args,
	    )
	);
    }
}

sub _cd_run {
    my ($self, $path, $binary, $command, @args) = @_;
    my @message;
    my $cmd ="$binary $command " . join(" ",@args);
    $self->_dbpnt("running 'cd $path; $cmd'") if $self->{verbose} > 1;

    chdir ($path) or die "Couldn't CD to $path: $!";

    open my $RUN, '-|', $cmd
      or die "Running [$cmd] failed with $?: $!";
    while (<$RUN>) {
	chomp;
	push @message, $_;
    }
    close $RUN;
    return (@message);
}

sub _shortest_path {
    my @dirs = grep { /\S/ } @_;

    # Set shortest_path to first dir
    my $shortest_path = shift(@dirs) || '';

    # Find common prefix between each dir and shortest_path
    foreach my $dir (@dirs) {
        chop $shortest_path while (index($dir, $shortest_path) != 0);
    }

    # Remove final / and anything after
    $shortest_path =~ s{/[^/]*?$}{};

    return $shortest_path;
}

1;

__END__
########################################### main pod documentation begin ##

=head1 NAME

SVN::Notify::Mirror - Keep a mirrored working copy of a repository path

=head1 SYNOPSIS

Use F<svnnotify> in F<post-commit>:

  svnnotify --repos-path "$1" --revision "$2" \
   --handler Mirror --to "/path/to/www/htdocs" \
   [--svn-binary /full/path/to/svn] \
   [--tag-regex "regex"]
   [--minimal]

or better yet, use L<SVN::Notify::Config> for a more
sophisticated setup:

  #!/usr/bin/perl -MSVN::Notify::Config=$0
  --- #YAML:1.0
  '':
    PATH: "/usr/bin:/usr/local/bin"
  'path/in/repository':
    handler: Mirror
    minimal: 1
    to: "/path/to/www/htdocs"
  'some/other/path/in/repository':
    handler: Mirror
    to: "/path/to/remote/www/htdocs"
  'some/project/tags':
    handler: Mirror
    to: "/path/to/another/dir"
    tag-regex: "TRUNK-"

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

=head2 Common Options

In addition to all of the options available to svnnotify, there is a
single global option that affects both L<Local Mirror> and L<Remote
Mirror> targets:

=over 4

=item minimal

If the C<--minimal> flag is passed on the commandline (or a hash entry
created in a config file), then the update will occur at the shortest common
path of all files/dirs that are changed for that revision.  For example,
using the example config file above, the following changes occured in 
rev 23:

  Changed paths:
    M path/in/repository/subdir/subdir2/file.1
    A path/in/repository/subdir/file.2
    M path/in/repository/subdir/subdir3/file.3

B<and> the checked-out mirror was in C</path/to/www/htdocs>, then the
update would be executed in the C</path/to/www/htdocs/subdir> directory.
This is the shorted common path of the updated files.

NOTE: when using the SVN::Notify::Config mode, the matching path (in the
above example C<path/in/repository>) is stripped off of the shortest
common path prior to appending that to the destination path (the C<to:> 
key).  It is assumed that a matching key is the "root" of the working 
copy.

=back

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

=head2 Local Mirror

Used for directories local to the repository itself (NFS or other
network mounted drives count).  The only required options are:

=over 4

=item * handler = Mirror

Specifies that this module is called to process the Notify event.

=item * to = /path/to/working/copy

Specified which directory should be updated.

=back

=head2 Remote Mirror

Used for mirrors on some other box, e.g. a web server in a DMZ
network.  See L<SVN::Notify::Mirror::SSH> or L<SVN::Notify::Mirror::Rsync>
for more details.  All C<ssh-*> options are now deprecated in the
base class and support for them will be removed in the next major release.
Please update your configurations (see L<SVN::Notify::Mirror::SSH> for
details).

=over 4

=head2 Methods of Mirroring

There are two schemes to keep a directory synced to a path in the
repository:

=over 4

=item 1. Update a checked out working copy

This is the normal mode of operation and is commonly used to keep a
test web server in sync with the repository on every commit.

=item 2. Switch a working copy to a new tag

This is the preferred method when you want to keep a production web
server up to date with only specific revisions, through the use of
smart tagging.

=back

For the latter case, L<SVN::Notify::Mirror> can be configured to
monitor a path in the repository and only trigger an update when
the path matches a specific regular expression, and do so by switching
the mirrored path to the new tag.

=over 4

=item * tag-regex

This optional parameter works with any L<Local Mirror> or L<Remote Mirror>,
using any of the applicable transfer methods (currently local, SSH, or
Rsync).  The C<--tag-regex> parameter takes a string which will be 
interpreted as a conventional Perl regex, and only those repository
paths which match the regex will be updated.  The regex also determines
what the mirrored directory will be switched to.

For example, using a SVN::Notify::Config file (which is the most useful
way to employ this option):

  #!/usr/bin/perl -MSVN::Notify::Config=$0
  --- #YAML:1.0
  '':
    PATH: "/usr/bin:/usr/local/bin"
  'project1/trunk':
    handler: Mirror
    to: "/path/to/test/htdocs"
  'project1/tags':
    handler: Mirror
    to: "/path/to/production/htdocs"
    tag-regex: "TRUNK-"
 
This would have the effect of keeping the path C</path/to/test/htdocs>
in sync on every commit, but C</path/to/production/htdocs> would be
switched only when a tag was created in C<project1/tags> that matched
the string C<TRUNK->.  B<NOTE:> this is not a sophisticated regex; in
particular you should not employ anchors, since the URL is not split
into repos-root and path segments before testing.

To initialize the switch directory, you must perform an initial 
checkout like this:

 $ svn checkout file://$REPOS/project1/tags/TRUNK-0_0_1

where C<TRUNK-0_0_1> is the name of any path in the C<.../tags/>
folder.

=back

=head1 PREREQUISITES (Optional and otherwise)

The only mandatory prerequisite is SVN::Notify (obviously), but the
presence of several other modules will enable other features:

=over 4

=item SVN::Notify::Config

Permits a YAML config file to be used as the entire postcommit script, like
the second example in the L<SYNOPSIS> above.

=item Net::SSH

Required to use SSH to update a remote working copy.  See
L<SVN::Notify::Mirror::SSH> for usage of that transport method.

=item File::Rsync

Required to use rsync to update a remote working copy  See
L<SVN::Notify::Mirror::RSync> for usage of that transport method..

=back

If you install any of these modules after installing SVN::Notify::Mirror,
those features will be available immediately (though you can rerun the
install in order to see the tests).

=head1 AUTHOR

John Peacock <jpeacock@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 John Peacock

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<SVN::Notify>, L<SVN::Notify::Config>

=cut

############################################# main pod documentation end ##
