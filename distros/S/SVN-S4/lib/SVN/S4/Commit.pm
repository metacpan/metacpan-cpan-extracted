# See copyright, etc in below POD section.
######################################################################

package SVN::S4::Commit;
require 5.006_001;

use strict;
use Carp;
use IO::Dir;
use IO::File;
use Cwd;
use Digest::MD5;
use MIME::Base64;
use vars qw($AUTOLOAD);

use SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);
use SVN::S4::Path;

our $VERSION = '1.064';

our @Commit_status_data;
our @Commit_unsafe_data;  # [path,status,pstatus]
our $Commit_self;

#######################################################################
# Methods

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

######################################################################
### Package return
#package SVN::S4::Commit;

sub commit {
    my $self = shift;
    # Self contains:
    #		debug
    #		quiet
    my %params = (#paths=>[],
		  #fallback_cmd,
		  #unsafe
                  @_);

    DEBUG ("IN self ",Dumper($self), "params ",Dumper(\%params)) if $self->debug;
    $Commit_self = $self;

    my @newpaths;
    foreach my $path (@{$params{paths}}) {
	push @newpaths, $self->abs_filename($path);
    }
    push @newpaths, $self->abs_filename('.') if $#newpaths < 0;

    my $msg = "";
    my $block_unversioned_cfg = $self->config_get_bool('s4', 'commit-block-unversioned');
    my $block_unversioned = (!defined $block_unversioned_cfg ? 0 : $block_unversioned_cfg);  # Default off
    if (!$params{unsafe}
	&& $block_unversioned) {
	my @pathstats;
	foreach my $path (@newpaths) {
	    push @pathstats, $self->find_commit_unsafe_stuff($path, { recurse=>1 });
	}
	if ($#pathstats>=0) {
	    foreach my $pathstat (@pathstats) {
		$msg .= sprintf +("s4:    %s%s     %s\n",
				  $pathstat->[1],
				  $pathstat->[2],
				  $pathstat->[0]);
	    }
	    $msg .= "s4: %Error: Blocked unsafe commit as unversioned files present.  Add, repair svn:ignore, or use commit --unsafe to override.\n";
	}
    }

    my $block_non_top_cfg = $self->config_get_bool('s4', 'commit-block-non-top');
    my $block_non_top = (!defined $block_non_top_cfg ? 0 : $block_non_top_cfg);  # Default off
    if (!$params{paths}[0]
	&& !$params{unsafe}
	&& $block_non_top
	&& $self->dir_uses_svn("..")) {
	my $cwd_url = $self->file_url (filename=>'.', assert_exists=>0);
	DEBUG("  cwd url = ",$cwd_url||'',"\n") if $self->debug;
	if (!($cwd_url && $cwd_url =~ m!(trunk$)|(branches/[^/]+$)|(branches/eb/[^/]+$)|(tags/[^/]+$)!)) {
	    $msg .= "s4: %Error: Blocked unsafe commit as not committing from top of tree.  Use commit --unsafe to override.\n";
	}
    }

    die $msg if $msg;  # Complain about everything all at once

    return $self->run ($params{fallback_cmd});
}

sub quick_commit {
    my $self = shift;
    # Self contains:
    #		debug
    #		quiet
    #		dryrun
    my %params = (#paths=>[],
		  recurse => 1,
		  file => [],
		  message => [],
                  @_);

    #DEBUG ("IN self ",Dumper($self), "params ",Dumper(\%params)) if $self->debug;
    $Commit_self = $self;

    my @newpaths;
    foreach my $path (@{$params{paths}}) {
	push @newpaths, $self->abs_filename($path);
    }

    my @files;
    foreach my $path (@newpaths) {
	push @files, $self->find_commit_stuff ($path, \%params);
    }

    if ($#files >= 0) {
	my @args = (($self->{quiet} ? "--quiet" : ()),
		    ($self->{dryrun} ? "--dry-run" : ()),
		    #
		    "commit",
		    "--non-recursive",	# We've expanded files already
		    (defined $params{message}[0] ? ("-m", $params{message}[0]) : ()),
		    (defined $params{file}[0] ? ("-F", $params{file}[0]) : ()),
		    @files);
	DEBUG Dumper(\@args) if $self->debug;
	if (!$self->{dryrun}) {  # svn doesn't accept ci --dry-run
	    $self->run($self->{svn_binary}, @args);
	}
    }
}

sub commit_block_ignore {
    my ($self, $path) = @_;
    if (!$self->{_commit_block_regexp}) {
	my $commit_block_ignores = ($self->config_get('s4', 'commit-block-ignores')
				    || "*.new *.old *.tmp");
	my $re = $self->config_glob_to_regexp($commit_block_ignores);
	$self->{_commit_block_regexp} = qr/$re/;
    }
    return ($path =~ /$self->{_commit_block_regexp}/);
}

sub find_commit_stuff {
    my ($self, $path, $params) = @_;
    # do svn status and record anything that looks strange.
    DEBUG "find_commit_stuff '$path'...\n" if $self->debug;

    undef @Commit_status_data;
    my $stat = $self->client->status (
	    $path,		# canonical path
	    "WORKING",		# revision
	    \&Commit_statfunc,	# status func
	    ($params->{recurse}?1:0),	# recursive
	    0,			# get_all
	    0,			# update
	    0,			# no_ignore
	    );
    return @Commit_status_data;
}

sub find_commit_unsafe_stuff {
    my ($self, $path, $params) = @_;
    # do svn status and record anything that looks strange.
    DEBUG "find_commit_unsafe_stuff '$path'...\n" if $self->debug;

    undef @Commit_unsafe_data;
    my $stat = $self->client->status (
	    $path,		# canonical path
	    "WORKING",		# revision
	    \&Commit_statfunc,	# status func
	    ($params->{recurse}?1:0),	# recursive
	    1,			# get_all
	    0,			# update
	    0,			# no_ignore
	    );
    return @Commit_unsafe_data;
}

sub Commit_statfunc {
    my ($path, $status) = @_;
    my $stat = $status->text_status;

    my $text_status_name = $SVN::S4::WCSTAT_STRINGS{$stat};
    die "s4: %Error: text_status code $stat not recognized" if !defined $text_status_name;
    my $pstat = $status->prop_status;
    my $prop_status_name = $SVN::S4::WCSTAT_STRINGS{$pstat};
    die "s4: %Error: prop_status code $pstat not recognized" if !defined $prop_status_name;
    if ($Commit_self->debug) {
	print "================================\n";
	print "path = $path\n";
	print "text_status = $text_status_name\n";
	print "prop_status = $prop_status_name\n";
    }
    if ($Commit_self->{debug}) {  # Was {quiet} but commit will also print msg
	printf +("%s%s     %s\n",
		 $SVN::S4::WCSTAT_LETTERS{$stat},
		 $SVN::S4::WCSTAT_LETTERS{$pstat},
		 $path);
    }

    if ($status->text_status != $SVN::Wc::Status::ignored
	&& $status->text_status != $SVN::Wc::Status::unversioned) {
	push @Commit_status_data, $path;
    }
    if (($status->text_status == $SVN::Wc::Status::unversioned
	 && !$Commit_self->commit_block_ignore($path))
	|| $status->text_status == $SVN::Wc::Status::conflicted
	|| $status->text_status == $SVN::Wc::Status::missing
	|| $status->text_status == $SVN::Wc::Status::obstructed
	|| $status->text_status == $SVN::Wc::Status::incomplete) {
	# Must grab status immediately as text, as pointer may disappear on next callback
	push @Commit_unsafe_data, [$path, $SVN::S4::WCSTAT_LETTERS{$stat}, $SVN::S4::WCSTAT_LETTERS{$pstat}];
    }

    return 0;
}

1;
__END__

=pod

=head1 NAME

SVN::S4::Commit - commit hooks

=head1 SYNOPSIS

Scripts:
  use SVN::S4::Commit;
  $svns4_object->commit (paths=>I<path>);
  $svns4_object->quick_commit (paths=>I<path>);

=head1 DESCRIPTION

SVN::S4::Commit

=head1 METHODS

=over 4

=item $s4->commit(paths=>I<path>);

=item $s4->quick_commit(paths=>I<path>);

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2005-2017 by Bryce Denney and Wilson Snyder.  This package is
free software; you can redistribute it and/or modify it under the terms of
either the GNU Lesser General Public License Version 3 or the Perl Artistic
License Version 2.0.

=head1 AUTHORS

Bryce Denney, Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut
