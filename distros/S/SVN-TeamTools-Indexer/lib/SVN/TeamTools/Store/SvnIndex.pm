use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Store::SvnIndex;
{
        $SVN::TeamTools::Store::SvnIndex::VERSION = '0.002';
}
# ABSTRACT: Common methods for accessing a SVN Lucy Index 

use parent 'SVN::TeamTools::Index::Index';

use Carp;
use Error qw(:try);

use SVN::TeamTools::Store::Config;
use SVN::TeamTools::Store::Repo;

use Data::Dumper;

my $conf;
my $logger;
BEGIN { $conf = SVN::TeamTools::Store::Config->new(); $logger = $conf->{logger}; }

sub hasAction {
        shift;
        my %args        = @_;
        my $action      = $args{action};
        return ("|dsp.config|" =~ /\|\Q$action\E\|/);
}

sub getTemplate {
	shift;
	my %args        = @_;
	my $action      = $args{action};
	if ($action =~ /dsp.config/) {
        	return HTML::Template->new( filename => 'SVN/TeamTools/Store/tmpl/svnindex-config.tmpl', path => @INC );
	}
}


# #########################################################################################################
#
# Lucy functions
#

# Constructor:
#   - create (0/1)
sub new {
	my $class	= shift;
	my %args	= @_;
	my $mode	= $args{mode};
	my $create	= $args{create};

	my $self = $class->SUPER::new (path => $conf->{svnindex}, mode=>$mode, schema=>_getSchema(), create=>$create);

	$self->{_repo} = SVN::TeamTools::Store::Repo->new ();

	bless  $self, $class;
	if ($create == 1) {
		$self->setIndexRev(rev => 0);
	}

	return $self;
}

sub addDoc {
	my $self	= shift;
	my %args	= @_;
	my $rev		= $args{rev};
	my $revadd	= $args{rev_added};
	my $path	= $args{path};

	my $look = $self->{_repo}->getLook (rev => $rev);

	$path =~ /\/([^\/]+)\.([^\/\.]+)$/;
	my $module = $1; my $ext = $2;

	try {
		$self->getWriter()->add_doc (Lucy::Document::Doc->new(fields => {
			type		=> 'doc',
			rev		=> $rev,
			revadd		=> $revadd,
			module		=> $module,
			path		=> $path,
			searchpath	=> $path,
			ext		=> $ext,
			author		=> $look->author(),
			date		=> $look->date(),
			content		=> $self->{_repo}->svnCat(rev => $rev, path => $path)
		}));
        } otherwise {
                my $exc = shift;
                croak "Error writing doc object with revision: $rev, path: $path, error: $exc";
        };
}

sub addLink {
        my $self	= shift;
	my %args	= @_;
	my $rev		= $args{rev};
	my $path	= $args{path};
	my $cfpath	= $args{cfpath};

	my $look = $self->{_repo}->getLook(rev => $rev);

	$path =~ /\/([^\/]+)\.([^\/\.]+)$/;
	my $module = $1; my $ext = $2;

	try {
		$self->getWriter()->add_doc (Lucy::Document::Doc->new(fields => {
			type		=> 'link',
			rev		=> $rev,
			module		=> $module,
			path		=> $path,
			searchpath	=> $path,
			ext		=> $ext,
			cfpath		=> $cfpath,
			cfrev		=> $rev,
			author		=> $look->author(),
			date		=> $look->date()
		}));
        } otherwise {
                my $exc = shift;
                croak "Error writing link object with revision: $rev, path: $path, error: $exc";
        };
}

sub deleteDoc {
	my $self	= shift;
	my %args	= @_;
	my $rev		= $args{rev};
	my $path	= $args{path};

	my $linked = $self->linkSearch(path => $path);

	while ( my $link = $linked->next()) {
		$self->addDoc (rev => $link->{cfrev}, rev_added => $rev, path => $link->{path});
	}
	$self->delTerm (field=>'cfpath', term=>$path);
	$self->delTerm (field=>'path', term=>$path);
}

sub addRev {
	my $self	= shift;
	my %args	= @_;
	my $rev		= $args{rev};

	my $look = $self->{_repo}->getLook(rev => $rev);

	$self->getWriter()->add_doc (Lucy::Document::Doc->new(fields => {
		type		=> 'rev',
		rev		=> $look->rev(),
		comments	=> $look->log_msg(),
		author		=> $look->author(),
		date		=> $look->date(),
		added		=> join(',',$look->added()),
		deleted		=> join(',',$look->deleted()),
		copied		=> join(',',$look->copied_to()),
	}));
}

sub linkSearch {
	my $self	= shift;
	my %args	= @_;
	my $path	= $args{path};

	return $self->execANDQuery (queries => [ $self->getTermQuery (field => 'cfpath',term => $path) ]);
}
###################################################################################################
### Create Lucy Index
#
# Static method
sub _getSchema {
	my $schema = Lucy::Plan::Schema->new;
	my $rawtype = Lucy::Plan::StringType->new();

	$schema->spec_field( name => 'type', 		type => $rawtype );	# All records (being doc, link, status,hist or rev)
	$schema->spec_field( name => 'rev', 		type => $rawtype );	# All records
	$schema->spec_field( name => 'revadd', 		type => $rawtype );	# docs (Revision the doc was added)
	$schema->spec_field( name => 'module', 		type => $rawtype );	# doc, link
	$schema->spec_field( name => 'path', 		type => $rawtype );	# doc, link
	$schema->spec_field( name => 'searchpath',	type => Lucy::Plan::FullTextType->new( 
				analyzer => Lucy::Analysis::PolyAnalyzer->new( 
					analyzers => [	Lucy::Analysis::CaseFolder->new(), 
							Lucy::Analysis::RegexTokenizer->new( pattern => '[^\/\.]+')]
				),
				stored => 0,
				boost  => 2.0));	# doc, link
	$schema->spec_field( name => 'ext', 		type => $rawtype );	# doc, link
	$schema->spec_field( name => 'author', 		type => $rawtype );	# doc, link, rev
	$schema->spec_field( name => 'date', 		type => $rawtype );	# doc, link, rev
	$schema->spec_field( name => 'cfpath', 		type => $rawtype );	# link
	$schema->spec_field( name => 'cfrev', 		type => $rawtype );	# link
	$schema->spec_field( name => 'content', 	type => Lucy::Plan::FullTextType->new( 
				analyzer => Lucy::Analysis::PolyAnalyzer->new(
					analyzers => [	Lucy::Analysis::CaseFolder->new(), 
							Lucy::Analysis::RegexTokenizer->new( pattern=> '[A-Za-z][A-Za-z0-9\$#_]+')]
				),
				stored => 0,
				highlightable => 1,
				boost  => 1.0)); # doc
	$schema->spec_field( name => 'comments', 	type => Lucy::Plan::FullTextType->new( 
				analyzer => Lucy::Analysis::PolyAnalyzer->new( language => 'en'),
				stored => 0,
				boost => 1.5)); # rev

	$schema->spec_field( name => 'added', 	type => Lucy::Plan::FullTextType->new( 
				analyzer => Lucy::Analysis::PolyAnalyzer->new(
					analyzers => [	Lucy::Analysis::CaseFolder->new(), 
							Lucy::Analysis::RegexTokenizer->new( pattern=> '[A-Za-z][A-Za-z0-9\$#_]+')]
				),
				stored => 0,
				boost  => 0.5)); # rev
	$schema->spec_field( name => 'deleted', 	type => Lucy::Plan::FullTextType->new( 
				analyzer => Lucy::Analysis::PolyAnalyzer->new(
					analyzers => [	Lucy::Analysis::CaseFolder->new(), 
							Lucy::Analysis::RegexTokenizer->new( pattern=> '[A-Za-z][A-Za-z0-9\$#_]+')]
				),
				stored => 0,
				boost  => 0.5)); # rev
	$schema->spec_field( name => 'copied', 	type => Lucy::Plan::FullTextType->new( 
				analyzer => Lucy::Analysis::PolyAnalyzer->new(
					analyzers => [	Lucy::Analysis::CaseFolder->new(), 
							Lucy::Analysis::RegexTokenizer->new( pattern=> '[A-Za-z][A-Za-z0-9\$#_]+')]
				),
				stored => 0,
				boost  => 0.5)); # rev

	return $schema;
}
1;

=pod

=head1 NAME

SVN::TeamTools::Store::SvnIndex

=head1 SYNOPSIS

use SVN::TeamTools::Store::SvnIndex;

my $svnindex = SvnIndex->new (mode=>"rw", create=>1);

=head1 DESCRIPTION

Used by various SVN::TeamTools modules to access the index. See the 'Indexer' module for more information on how to use the index.
The SvnIndex distinguished revisions, documents and links. 
A revision contains the revision log message and lists of added and deleted files.
A document is a file within the repository.
The 'link' type was introduced to save space and processing power. If a large trunk is copied to a branch for a development project, in general only a limited amount of files is actually modified. In this example, all files contained by the trunk will be created as linked objects in the new branch (in the search index). All routines within SVN::TeamTools automatically extend search results (on documents) with all their linked objects. As soon a the file in the branch is modified (and committed), the link is removed and the file is stored in the search index as a document.

=head2 Methods

=over 12

=item new

Creates a new index object. Parameters:
mode: r for read only, rw for read-write access
create: if set, the index is recreated.

=item linkSearch

Parameter 'path' (String).

Returns: a Lucy query result.

Finds the 'links' to the specified path, e.g. entities in SubVersion that where created during a branch (copy) operation. 

=item addDoc

Only for use by the Indexer

=item addLink

Only for use by the Indexer

=item deleteDoc

Only for use by the Indexer

=item addRev

Only for use by the Indexer

=item hasAction

Only for internal use by the web interface

=item getTemplate

Only for internal use by the web interface

=item getData

Only for internal use by the web interface

=item store

Only for internal use by the web interface

=back

=head1 AUTHOR

Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut

