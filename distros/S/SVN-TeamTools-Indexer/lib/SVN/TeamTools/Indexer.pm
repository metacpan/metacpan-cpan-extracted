use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Indexer;
{
        $SVN::TeamTools::Indexer::VERSION = '0.002';
}
# ABSTRACT: Created a Lucy index on a SVN repository.

use Carp;
use Error qw(:try);

use SVN::TeamTools::Store::Config;
use SVN::TeamTools::Store::Repo;
use SVN::TeamTools::Store::SvnIndex;

use SVN::Look;
use Getopt::Long;

my $conf;
my $logger;
BEGIN { $conf = SVN::TeamTools::Store::Config->new(); $logger = $conf->{logger}; }

sub run {
	my $createindex = 0;
	GetOptions ('createindex' => \$createindex);

	my $repo 		= SVN::TeamTools::Store::Repo-> new();
	my $svnindex 	= SVN::TeamTools::Store::SvnIndex->new (mode=>"rw", create=>$createindex);

	my $indextypes	= "txt";
	while (my ($regex, $lang) = each (%{$conf->{src_types}})) {
		if ('1' == $lang->{index}) {
			$indextypes="$indextypes|$regex";
		}
	}

	my $lowerRev = $svnindex->getIndexRev();
	$lowerRev++;
	
	my $optimize_count=0;
	$logger->info ("Indexing, starting at revision $lowerRev");
	for (my $rev=$lowerRev; $rev<=$repo->getSvnRev(); $rev++) {
		$logger->info ("Indexing revision $rev");
	
		my $revlook = $repo->getLook(rev => $rev);
		$svnindex->addRev(rev => $rev);
	
		### Explode copied and renamed
		while (my ($to, $from) = each (%{$revlook->changed_hash()->{copied}})) {
			if ( grep { $_ eq @$from[0] } $revlook->deleted() ) { # So.. it was moved
				if ( $to =~ /\/$/ ) { # So, a directory (don't have to add if not)
					try {
						foreach my $path (grep (!/\/$/, $revlook->tree($to, "--full-paths"))) {
							if ( $path =~ /\.($indextypes)$/ ) {
								$svnindex->addDoc (rev => $rev, rev_added=>$rev, path => $path);
							}
						}
				        } otherwise {
				                my $exc = shift;
				                croak "Error getting tree on revision " . $revlook->rev() . " on path $to";
				        };
				}
			} else { # So, a copy
				if ( $to =~ /\.($indextypes)$/ ) { # Not a directory
					$svnindex->addLink (rev => $rev, path => $to, cfpath => $$from[0]);
				} else {
					my $o = $repo->getLook(rev => @$from[1]);
					try {
						foreach my $path (grep (/\.($indextypes)$/, $o->tree(@$from[0], "--full-paths"))) {
							$svnindex->addLink (rev => $rev, path => $to . substr($path,length(@$from[0])), cfpath => $path);
						}
					} otherwise {
				                my $exc = shift;
				                croak "Error getting tree on revision " . $revlook->rev() . " on path $to";
					};
				}
			}
		}
	
		### Explode deleted
		foreach my $path ($revlook->deleted()) {
			if ( $path !~ /\/$/ ) { # Not a directory
				if ( $path =~ /\.($indextypes)$/ ) { # Stored filetype
					$svnindex->deleteDoc (rev => $rev, path => $path );
				}
			} else { # Check in previous release
				my $o = $repo->getLook(rev => $rev - 1);
				try {
					foreach my $epath (grep (/\.($indextypes)$/, $o->tree($path, "--full-paths"))) {
						$svnindex->deleteDoc (rev => $rev, path => $epath );
					}
				} otherwise {
			                my $exc = shift;
					carp "Error getting tree (for deletion) on revision " . $o->rev() . " on path $path";
			        };
			}
		}
	
		### Updated documents
		foreach my $path (grep (/\.($indextypes)$/,$revlook->updated())) {
			if ( $path =~ /\.($indextypes)$/ ) {
				$svnindex->deleteDoc (rev => $rev, path => $path );
				$svnindex->addDoc ( rev => $rev, rev_added => $rev, path => $path);
			}
		}
	
		###  Added
		foreach my $path ( grep (/\.($indextypes)$/,$revlook->added())) {
			$svnindex->addDoc ( rev => $rev, rev_added => $rev, path => $path);
		}
	
		$svnindex->setIndexRev(rev => $rev);
		$svnindex->commit();
	
		$optimize_count++;
		if ( $optimize_count > 100 ) {
			$logger->info("Optimizing the index");
			$svnindex->optimize();
			$optimize_count=0;
		}
	}
	$svnindex->optimize();
}
1;

=pod

=head1 NAME

SVN::TeamTools::Indexer

=head1 SYNOPSIS

=head2 As a module

    use SVN::TeamTools::Indexer;
    SVN::TeamTools::Indexer->run();

=head2 From the command line

    Indexer #(for an incremental run)

    Indexer --createindex # For the initial index build or to re-initialize

=head1 DESCRIPTION

Builds a Lucy index for a SVN repository. If an index already exists and no command 
line option 'createindex' is issued, the process is incremental. Only new revisions are indexed.

TODO: include index structure and examples how to use it.

=head2 Tested Environments:

This module has been developed and tested on CentOs 6.3, no guarantees are given
that it should work on other systems. Please inform me (markleeuw@gmail.com)
whenever an installation on a different platform fails (please provide build.log).

=head2 Prerequisits:

This module is known to have the following requirements on CentOs 6.3:
- subversion
- perl-CPAN
- perl-YAML
- perl-XML-Parser
- gcc-c++

To install there requirements use:
    yum install perl-CPAN perl-YAML perl-XML-Parser gcc-c++ make


=head1 AUTHOR

Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut
