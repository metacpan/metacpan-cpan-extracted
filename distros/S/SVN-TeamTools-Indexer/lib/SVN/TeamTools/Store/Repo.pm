use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Store::Repo;
{
        $SVN::TeamTools::Store::Repo::VERSION = '0.002';
}
# ABSTRACT: Common methods for accessing a SubVersion Repository

use Carp;
use Error qw(:try);

use SVN::TeamTools::Store::Config;
use SVN::TeamTools::Plugins::Mailer;

use DateTime;
use File::Path qw(make_path remove_tree);
use SVN::Look;
use List::Util qw[min max];

use Data::Dumper;
my $conf;
my $logger;
BEGIN { $conf = SVN::TeamTools::Store::Config->new(); $logger = $conf->{logger}; }

sub hasAction {
	shift;
	my %args        = @_;
	my $action      = $args{action};
	return ("|svn.calc.contexts|svn.get.contexts|svn.calc.struct|svn.calc.branches|dsp.config|" =~ /\|\Q$action\E\|/);
}

sub getTemplate {
	shift;
	my %args        = @_;
	my $action      = $args{action};
	if ($action =~ /dsp.config/) {
		return HTML::Template->new( filename => 'SVN/TeamTools/Store/tmpl/repo-config.tmpl', path => @INC );
	}
}
sub getData {
	my $class	= shift;
	my %args	= @_;
	my $action	= $args{action};
	my $param	= $args{param};
	if ($action =~ /svn.calc.contexts/) {
		my @result;
		if (scalar (grep (m/.+/, grep (defined, @{$param->{regex}}) )) ) {
			my $look = $class->new()->getLook();
			my %paths;
			$paths{"/"} = undef;
			my $regex = "^/?(". join ("|",grep (/.+/,grep (defined, @{$param->{regex}}))).")\$";
			$logger->info($regex);
			for (my $i=0; $i<$param->{depth}; $i++) {
				for my $path (keys (%paths)) {
					my @tree = $look->tree ($path, "--full-paths", "--non-recursive");
					for my $t (@tree) {
						$paths{$t}=undef;
					}
				}
			}
			@result = grep ( m#$regex#,keys (%paths));
			foreach (@result) {
				s/^\///;
			}
		}

		return \@result;
	} elsif ($action =~ /svn.get.contexts/) {
		return $conf->{config}->{trees}->{context};
	} elsif ($action =~ /svn.calc.struct/) {
		my $look = $class->new()->getLook();
		my $rtrunk  = $conf->{config}->{svn}->{regex_trunk};
		my $rbranch = $conf->{config}->{svn}->{regex_branch};
		my $rtags = $conf->{config}->{svn}->{regex_tags};
		my %result = (
			trunk	=> [],
			branch	=> [],
			tags	=> [],
		);
		my @mt = split(m#/#,$rtrunk);
		my @mb = split(m#/#,$rbranch);
		my @mg = split(m#/#,$rtags);
		my $maxdepth = max (scalar(@mt), scalar(@mb), scalar(@mg));
		my %paths;
		$paths{"/"} = undef;
		for (my $i=0; $i<$maxdepth; $i++) {
			for my $path (keys (%paths)) {
				my @tree = $look->tree ($path, "--full-paths", "--non-recursive");
				for my $t (@tree) {
					$paths{$t}=undef;
				}
			}
		}
		$rtrunk = '^/?('.$rtrunk.')$';
		$rbranch = '^/?('.$rbranch.')$';
		$rtags = '^/?('.$rtags.')$';
		push (@{$result{trunk}}, grep (m#$rtrunk#, keys (%paths)));
		push (@{$result{branch}}, grep (m#$rbranch#, keys (%paths)));
		push (@{$result{tags}}, grep (m#$rtags#, keys (%paths)));
		return \%result;	
	} elsif ($action =~ /svn.calc.branches/) {
		my $look = $class->new()->getLook();
		my $rbranch = $conf->{config}->{svn}->{regex_branch};
		my @result;

		my @mb = split(m#/#,$rbranch);
		my $maxdepth = scalar(@mb)+1;
		my %paths;
		$paths{"/"} = undef;
		for (my $i=0; $i<$maxdepth; $i++) {
			for my $path (keys (%paths)) {
				my @tree = $look->tree ($path, "--full-paths", "--non-recursive");
				for my $t (@tree) {
					$paths{$t}=undef;
				}
			}
		}
		$rbranch = '^/?('.$rbranch.'[^/]+/)$';
		push (@result, grep (m#$rbranch#, keys (%paths)));
		return \@result;	
	}
}
			
			
			
	


# #########################################################################################################
#
# Subversion functions
#


# New (initalizer):
#  - repopath
#
sub new {
	my $class = shift;
	my $self = {
		_repo => $conf->{repo},
		_cache_rev => 0,
		_cache_txn => 0,
		_cache_look => 0
	};
	bless $self, $class;

	return $self;
}

### Get current revision from Subversion repository
sub getSvnRev {
	my $self = shift;
	try {
		my $rev = SVN::Look->new($self->{_repo})->youngest();
		chomp($rev);
		return $rev;
	} otherwise {
		my $exc = shift;
		croak "Error getting latest revision on path $self->{_repo} error : $exc";
	};
}

### Get an SVNLook object
sub getLook {
	my $self 	= shift;
	my %args	= @_;
	my $rev		= $args{rev};
	my $txn		= $args{txn};

	if ( $self->{_cache_rev} != (defined $rev) ? $rev : -1 and $self->{_cache_txn} != (defined $txn) ? $txn : -1 ) {
		try {
			if (defined $rev) {
				$self->{_cache_rev} = $rev;
				$self->{_cache_txn} = 0;
				$self->{_cache_look} = SVN::Look->new ($self->{_repo}, -r => $rev);
			} elsif (defined $txn) {
				$self->{_cache_txn} = $txn;
				$self->{_cache_rev} = 0;
				$self->{_cache_look} = SVN::Look->new ($self->{_repo}, -t => $txn);
			} else {
				my $r = $self->getSvnRev();
				$self->{_cache_rev} = $r;
				$self->{_cache_txn} = 0;
				$self->{_cache_look} = SVN::Look->new ($self->{_repo}, -r => $r);
			}
		} otherwise {
			my $exc = shift;
			croak "Error getting svnlook on revision $rev on path $self->{_repo} error : $exc";
		};
	}
	return $self->{_cache_look};
}


### Retrieve document text for a specific path and revision
sub svnCat {
	my $self	= shift;
	my %args	= @_;
	my $rev		= $args{rev};
	my $path	= $args{path};
	my $content = "";
	try {
		$content = $self->getLook(rev => $rev)->cat($path);
	} otherwise {
		my $exc = shift;
		carp "Error getting file content on revision $rev  on path ", $self->{_repo}, " error : $exc";
	};

	return $content;
}
### Subversion repo change ops


sub mergeFiles {
## To merge new files into the rerpository or delete files. Operations (in \@files) have to be in the correct order
#
	shift;
	my %args	= @_; # $path, $msg, \@files= {path,content,action}

	my $wdtag	= DateTime->now()->epoch();
	my $wd		= $conf->{config}->{svn}->{wc} . '/' . $wdtag;
	my $prefix	= 'file://'.$conf->{repo}.'/';

	my $err;
	eval {make_path ($wd,{error=>\$err});};
	die "Could not make working directory $wd:\n".Dumper($err)."\n" if $@;

	## Analyse directory usage in new files
	my %basedirs;
	my %dirs;
	for my $act (@{$args{files}}) {
		if ($act->{action} !~ /delete/i) {
			$act->{path} =~ m/^\/?([^\/]+)/;
			$basedirs{$1} = undef;
			$act->{path} =~ m/^\/?(.+)\/[^\/]*$/;
			my @d = split (/\//,$1);
			for (my $i=0; $i<scalar(@d); $i++) {
				$dirs{ join ('/',@d[0..$i]) } = undef;
			}
		}
	}
	my $cinfo;
	## Add missing directories directly to the repository
	for my $dir (sort(keys %dirs)) {
		$cinfo = `svn info $prefix$args{path}/$dir`;
		if ($@) {
			$cinfo=`svn mkdir $prefix$args{path}/$dir -m"Creating directory for automerge"`;
			if ($?) {
				die "Could not make directory: $cinfo";
			}
		}
	}

	## Checkout the base dirs
	for my $dir (keys %basedirs) {
		$cinfo = `svn checkout $prefix$args{path}/$dir $wd/$dir`;
		if ($?) {
			die "Could not checkout $args{path}/$dir: $cinfo";
		}
	}

	# DO the actual merge
	for my $act (@{$args{files}}) {
		if ($act->{action} =~ /delete/i) {
			## Delete operations
			$cinfo = `svn delete $wd/$act->{path}`;
			if ($?) {
				die "Could not delete $act->{path}: $cinfo";
			}
		} else {
			open (my $fh, '>', $wd.'/'.$act->{path}) or die "Could not open $wd/$act->{path} for writing";
			print $fh $act->{content};
			close $fh;
			$cinfo = `svn info $prefix/$args{path}/$act->{path}`;
			if ($@) {
				$cinfo = `svn add $wd/$act->{path}`;
				if ($?) {
					die "Could not add path $act->{path}: $cinfo";
				}
			}
		}
	}

	# Commit and clean up
	my @result;
	for my $dir (keys %basedirs) {
		my $cinfo = `svn commit $wd/$dir -m"Automatic commit on $dir for file integration (user message: $args{msg})"`;
		if ($?) {
			die "Could not commit:$cinfo";
		}
		push (@result,$cinfo);
	}
	return \@result;
}
sub mergeBranches {
# target
# trunk
# email addresses (comma separated)
# branch, branch, branch, ....
	my $class	= shift;
	my %args	= @_;
	my $target	= $args{target};
	$target =~ s/\/$//;
	my $trunk	= $args{trunk};
	$trunk =~ s/\/$//;
	my @addresses	= split (/ ,;/,$args{addresses});
	my @branches	= @{$args{branches}};
	s/\/$// for (@branches);
	
	my @actioncode;

	my $wdtag	= DateTime->now()->epoch();
	my $wd		= $conf->{config}->{svn}->{wc} . '/' . $wdtag;

	my $prefix = "file://".$conf->{repo}."/";

	my $status=1;
	my $msg="Creating $target based on $trunk using ".join(",",@branches)."\n\n";

## Create initial copy 
	my $cinfo = `svn copy $prefix$trunk $prefix$target -m"Create new copy for automated merging\n$args{message}"`;
	if ($?) {
		$status=0;
		$msg.="Failure during svn copy:\n$cinfo\n";
	} else {
		$msg .= "Created a new copy $target from $trunk\n$cinfo\n";

		## Checkout new copy
		$cinfo = `svn checkout $prefix$target $wd -q --non-interactive`;
		if ($?) {
			$status=0;
			$msg.="Failure during checkout:\n$cinfo\n";
		} else {
			$msg .= "Checked out $target\n$cinfo\n";
			## Merge the provided branches
			for my $branch (@branches) {
				$cinfo = `svn merge $prefix$trunk $prefix$branch $wd`;
				if ($?) {
					$status=0;
					$msg .= "Failure during merge of $branch:\n$cinfo\n";
					last;
				} else {
					$msg .= "Merged $branch\n$cinfo\n";
				}
			}
		}
	}
	if ($status eq 1) {
		$cinfo = `svn commit $wd -m "$args{message}"`;
		if ($?) {
			$status=0;
			$msg .= "Failure duing commit\n$cinfo\n";
		} else {
			$msg .= "Commited new target\n$cinfo\n";
		}
	}
	SVN::TeamTools::Plugins::Mailer->sendMail (
			subject=>($status eq 1) ? "Success: $args{message}" : "Failure: $args{message}",
			recipients=>\@addresses,
			message=>$msg);
}
1;

=pod

=head1 NAME

SVN::TeamTools::Store::Repo

=head1 SYNOPSIS

use SVN::TeamTools::Store::Repo;
my $repo = SVN::TeamTools::Store::Repo-> new();
my $rev = $repo->getSvnRev(); # Get latest revision number
my $svnlook = $repo->getLook (rev=>1234); # Get a SVN::Look objects
my $svnlook = $repo->getLook (txn=>1234); # Get a SVN::Look objects
my $text = $repo->svnCat(rev=>1234, path=>'trunk/file.txt'); # Get a file from the SVN repository

=head1 DESCRIPTION

Common methods for accessing a SubVersion Respository.

The location of the SVN repository must be specified in the config.xml file. An example:
  <svn>
    <authz>conf/authz</authz>
    <passwd>conf/passwd</passwd>
    <regex_branch>branches/</regex_branch>
    <regex_tags>tags/</regex_tags>
    <regex_trunk>trunk/</regex_trunk>
    <repo>/u02/svn/repo01</repo>
    <url>http://localhost/svn/repo01</url>
    <wc>/tmp/svn</wc>
  </svn>

=over 12

=item repo

The absolute path to the SubVersion repository

=item authz

The path, absolute or relative to the repo path, to the authorization file

=item passwd

The path, absolute or relative to the repo path, to the password file

=item wc

The absolute base path of the local working copy location. Branche and Merge operation will create subdirectories under this path (only used by the webinterface)

=item url

The url to the web access as in mod_dav_svn (only used by the webinterface)

=item regex_trunk

A regular expression identifying the 'trunk' or 'trunks' in the repository (only used by the webinterface)

=item regex_tags

A regular expression identifying the 'tags' in the repository (only used by the webinterface)

=item regex_branch

A regular expression identifying the 'branches' in the repository (only used by the webinterface)

=back

=head2 Methods

=over 12

=item new

Creates a new repository object. No parameters needed.

=item getSvnRev

Gets latest revision number.

=item getLook

Takes one parameter; rev (the revision number) or txn (a transaction number, if used by a hook).

Returns a SVN::Look object.

=item svnCat

Takes two parameters:
rev - a revision number, this has to be a real number, e.g. HEAD can not be used.
path - a string representing a path in the repository.

returns a string containing the content of the file.

=item mergeFiles

Merges new files into the repository or deletes existing files. Only used by the webinterface (in combination with the database modules).

=item mergeBranches

Automatically merges branches (with the trunk) to produce new branches or tags. Only used by the webinterface and the scheduler.

=item hasAction

Only for internal use by the web interface

=item getTemplate

Only for internal use by the web interface

=item getData

Only for internal use by the web interface

=back

=head1 AUTHOR

Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut

