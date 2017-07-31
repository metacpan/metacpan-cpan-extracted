# See copyright, etc in below POD section.
######################################################################

package SVN::S4::Info;
require 5.006_001;

use SVN::S4;
use strict;
use Carp;
use IO::Dir;
use IO::File;
use Cwd;
use vars qw($AUTOLOAD);

use SVN::S4::Debug qw (DEBUG is_debug);
use SVN::S4::Path;

our $VERSION = '1.066';

#######################################################################
# Methods

sub _status_switches_cb {
    my $s4 = shift;
    my ($path, $status) = @_;
    # Gets result from svn->status call; see SVN::Wc manpage
    DEBUG "_status_switches_cb $status\n" if $s4->debug;
    if ($status->entry) {
	if (!$s4->{_info_cb_data}{files}  # First file
	    || $status->switched) {
	    printf "Path: %s\n",$path;
	    printf "URL: %s\n",$status->entry->url;
	    printf "Revision: %s\n", $status->entry->revision;
	    printf "Node Kind: %s\n", (($status->entry->kind == $SVN::Node::file) && "file"
				       || ($status->entry->kind == $SVN::Node::dir) && "directory"
				       || ($status->entry->kind == $SVN::Node::none) && "none"
				       || "unknown");
	    printf "Last Changed Author: %s\n", $status->entry->cmt_author;
	    printf "Last Changed Rev: %s\n", $status->entry->cmt_rev;
	    #printf "Last Changed Date: %s\n", $status->entry->cmt_date;

	    my $prop_rev = $s4->rev_on_date(url=>$status->entry->url,
					    date=>"HEAD");
	    printf "Head Rev: %s\n", $prop_rev;

	    print "\n";
	}
	$s4->{_info_cb_data}{files}++;
    }
}

sub _info_switches_cb {
    my $s4 = shift;
    my $allow_viewspec = shift;
    my ($path, $info) = @_;
    # Gets result from svn->info call; see SVN::Client manpage svn_info_t structure
    DEBUG "_info_switches_cb $info\n" if $s4->debug;
    if ($info) {
	printf "Path: %s\n",$info->URL;   # Only used on URL calls, so print the URL again
	printf "URL: %s\n",$info->URL;
	printf "Revision: %s\n", $info->rev;
	printf "Node Kind: %s\n", (($info->kind == $SVN::Node::file) && "file"
				   || ($info->kind == $SVN::Node::dir) && "directory"
				   || ($info->kind == $SVN::Node::none) && "none"
				   || "unknown");
	printf "Last Changed Author: %s\n", $info->last_changed_author;
	printf "Last Changed Rev: %s\n", $info->last_changed_rev;
	#printf "Last Changed Date: %s\n", $info->last_changed_date;

	# We queried HEAD for this call, so we can print it directly
	#my $prop_rev = $s4->rev_on_date(url=>$info->URL,
	#				date=>"HEAD");
	printf "Head Rev: %s\n", $info->rev;

	print "\n";

	if ($allow_viewspec) {
	    $s4->_info_viewspecs(url=>$info->URL);
	}
    }
}

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

sub info_switches {
    my $self = shift;
    my %params = (#revision=>,
                  #paths=>,  # listref
                  @_);
    my @paths = @{$params{paths}};

    foreach my $path (@{$params{paths}}) {
	$path = $self->clean_filename($path);
	# State, for callback
	$self->{_info_cb_data} = {};
	# Do status
	if ($self->is_file_local(filename=>$path)) {
	    # Recursively look at status to determine switchpoints
	    my $canonical_path = $self->abs_filename ($path);
	    DEBUG "info-switches is local for $canonical_path\n" if $self->debug;
	    my $stat = $self->client->status
		($canonical_path,	# canonical path
		 "WORKING",		# revision
		 sub { SVN::S4::Info::_status_switches_cb($self,@_); }, # status func
		 1,			# recursive
		 1,			# get_all
		 0,			# update
		 0,			# no_ignore
		 );
	} else {
	    # Like 'svn info' on a URL, but deal with Project.viewspec's
	    $self->_info_one_url_recurse($path,1);
	}
    }
}

sub _info_one_url_recurse {
    my $self = shift;
    my $path = shift;
    my $allow_viewspec = shift;
    DEBUG "info-switches is URL\n" if $self->debug;
    my $stat = $self->client->info
	($path,			# canonical path
	 undef,			# peg_revision
	 "HEAD",		# revision
	 sub { SVN::S4::Info::_info_switches_cb($self,$allow_viewspec,@_); }, # status func
	 0,			# recursive
	 );
}

sub _info_viewspecs {
    my $self = shift;
    my %params = (#url=>,
		  rev=>'HEAD',
                  @_);

    # see if the area has a viewspec file
    my $viewspec_url = "$params{url}/$self->{viewspec_file}";
    my $found_viewspec = $self->is_file_in_repo (url => $viewspec_url);
    if (!$found_viewspec) {
        DEBUG "tree with no viewspec. done\n" if $self->debug;
	return;
    }

    DEBUG "Parse the viewspec file $viewspec_url\n" if $self->debug;
    $self->parse_viewspec (filename=>$viewspec_url, revision=>$params{rev});

    foreach my $path ($self->viewspec_urls) {
	DEBUG "Recurse into viewspec URL $viewspec_url\n" if $self->debug;
	$self->_info_one_url_recurse($path,0);
    }
}

######################################################################
### Package return
package SVN::S4::Info;
1;
__END__

=pod

=head1 NAME

SVN::S4::Info - Enhanced update and checkout methods

=head1 SYNOPSIS

Shell:
  s4 info-switches PATH URL

Scripts:
  use SVN::S4::Info;
  $svns4_object->info_switches

=head1 DESCRIPTION

SVN::S4::Info

=head1 METHODS

=over 4

=item info_switches

Perform a svn info on all of the switchpoints plus the trunk.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2006-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut
