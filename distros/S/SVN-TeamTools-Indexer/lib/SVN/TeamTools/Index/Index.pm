use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Index::Index;
{
        $SVN::TeamTools::Index::Index::VERSION = '0.002';
}
# ABSTRACT: Parent object for all Lucy indexes used by SVN::TeamTools

use Carp;
use Error qw(:try);

use SVN::TeamTools::Store::Config;
use SVN::TeamTools::Index::PrefixQuery;

use Lucy;
use LucyX::Search::Filter;

my $conf;
my $logger;
BEGIN { $conf = SVN::TeamTools::Store::Config->new(); $logger = $conf->{logger}; }

# #########################################################################################################
#
# Lucy functions
#

# Constructor:
#   - path to the index
#   - mode: r, rw, w
#   - schema, if present, index will be (re)created
sub new {
	my $class	= shift;
	my %args	= @_;
	my $self = {
		_indexpath	=> $args{path},
		_mode		=> $args{mode},
		_schema		=> $args{schema},
	};
	my $create	= $args{create};

	$self->{_index} = $self->{_indexpath};
	$self->{_indexer} = 0;

	try {
		#$self->{_index} = Lucy::Store::FSFolder->new(path => $self->{_indexpath});

		if ($self->{_mode} =~ /w/) {
			if ($create) {
				my $indexer = Lucy::Index::Indexer->new(
					index    => $self->{_index},
					schema   => $self->{_schema},
					create   => 1,
					truncate => 1 
				);
				$indexer->commit();
			}
		}
        } otherwise {
                my $exc = shift;
                croak "Error creating new Index object with path ", $self->{_indexpath}, " error: $exc";
        };

	bless $self, $class;
	return $self;
}

sub getWriter {
	my $self = shift;

	if ($self->{_mode} !~ /w/) {
                croak "getWriter conflicts with open mode: ", $self->{_mode};
	}
		
	if ( ref($self->{_indexer}) ne "Lucy::Index::Indexer" ) {
		try {
			$self->{_indexer} = Lucy::Index::Indexer->new(
					index    => $self->{_index},
					schema   => $self->{_schema}
				);
        	} otherwise {
	                my $exc = shift;
	                croak "Error recreating Indexer, error: $exc";
	        };
	}
	return $self->{_indexer};
}

sub getSearcher {
	my $self = shift;

	if ( ref($self->{_indexer}) eq "Lucy::Index::Indexer" ) {
		$self->commit();
	}

	try {
		return Lucy::Search::IndexSearcher->new(index => $self->{_index});
       	} otherwise {
                my $exc = shift;
                croak "Error recreating Searcher, error: $exc";
        };
}

sub commit {
	my $self = shift;

	if ( ref($self->{_indexer}) eq "Lucy::Index::Indexer"  ) {
		try {
			$self->{_indexer}->commit();
			$self->{_indexer} = 0;
		} otherwise {
			my $exc = shift;
			croak "Error commiting to index, error: $exc";
		}
	}
}

sub optimize {
	my $self = shift;

#	$self->commit();
	try {
		$self->getWriter()->optimize();
	} otherwise {
		my $exc = shift;
		croak "Error optimizing index, error: $exc";
	}
}

sub setIndexRev {
	my $self	= shift;
	my %args	= @_;
	my $rev		= $args{rev};

	try {
		$self->delTerm(field=>'type', term=>'status');
		my $w = $self->getWriter();
		$w->add_doc (Lucy::Document::Doc->new(fields => { 'type' => 'status', 'rev' => $rev }));
	} otherwise {
		my $exc = shift;
		croak "Error writing index revision, error: $exc";
	};

	$self->commit();
}

sub getIndexRev {
	my $self = shift;

	try {
		my $hits = $self->getSearcher()->hits( query => Lucy::Search::TermQuery->new(field => 'type', term  => 'status'));
		my $hit = $hits -> next();
		return $hit->{rev};
	} otherwise {
		my $exc = shift;
		croak "Error getting index revision, error: $exc";
	};
}


sub getQuery {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};
	my $term	= $args{term};

	try {
		my $query_parser = Lucy::Search::QueryParser->new(
			schema => $self->{_schema},
			fields => [$field]
		);
		return $query_parser->parse( $term );
	} otherwise {
		my $exc = shift;
		croak "Error creating query on '$field' with term '$term', error: $exc";
	}
}

sub getPrefixQuery {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};
	my $prefix	= $args{prefix};

	try {
		return SVN::TeamTools::Index::PrefixQuery->new(
			field	=> $field,
			prefix	=> $prefix,
		);
	} otherwise {
		my $exc = shift;
		croak "Error creating query on '$field' with prefix '$prefix', error: $exc";
	}
}

sub getTermQuery {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};
	my $term	= $args{term};

	try {
		return Lucy::Search::TermQuery->new(
			field => $field,
			term => $term
		);
	} otherwise {
		my $exc = shift;
		croak "Error creating Termquery on '$field' with term '$term', error: $exc";
	}
}

sub getANDQuery {
	my $self	= shift;
	my %args	= @_;
	my @queries	= @{ $args{queries} };

	try {
		return Lucy::Search::ANDQuery->new(
			children => [ @queries ],
		);
	} otherwise {
		my $exc = shift;
		croak "Error getting AND query, error: $exc";
	}
}

sub execANDQuery {
	my $self	= shift;
	my %args	= @_;
	my @queries	= @{ $args{queries} };

	try {
		my $query = Lucy::Search::ANDQuery->new(
			children => [ @queries ],
		);
		if (exists $args{pagenum} ) {
			return $self->getSearcher()->hits( query => $query , num_wanted => $args{pagesize}, offset => $args{pagenum}*$args{pagesize});
		} else {
			return $self->getSearcher()->hits( query => $query , num_wanted => -1);
		}
	} otherwise {
		my $exc = shift;
		croak "Error executing query, error: $exc";
	}
}

sub getORQuery {
	my $self	= shift;
	my %args	= @_;
	my @queries	= @{ $args{queries} };

	try {
		return Lucy::Search::ORQuery->new(
			children => [ @queries ],
		);
	} otherwise {
		my $exc = shift;
		croak "Error getting OR query, error: $exc";
	}
}

sub execORQuery {
	my $self	= shift;
	my %args	= @_;
	my @queries	= @{ $args{queries} };

	try {
		my $query = Lucy::Search::ORQuery->new(
			children => [ @queries ],
		);
		if (exists $args{pagenum} ) {
			return $self->getSearcher()->hits( query => $query , num_wanted => $args{pagesize}, offset => $args{pagenum}*$args{pagesize});
		} else {
			return $self->getSearcher()->hits( query => $query , num_wanted => -1);
		}
	} otherwise {
		my $exc = shift;
		croak "Error executing paginated query, error: $exc";
	}
}

sub getTermFilter {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};
	my $term	= $args{term};

	try {
		return LucyX::Search::Filter->new( 
        	    query => $self->getTermQuery (field => $field, term => $term)
	        );
	} otherwise {
		my $exc = shift;
		croak "Error executing paginated query, error: $exc";
	}
}

sub delTerm {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};
	my $term	= $args{term};

	$self->getWriter()->delete_by_term (field=>$field, term=>$term);
}

sub getUniques {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};

	my %res;
	my $docs = $self->execANDQuery (queries=>[ Lucy::Search::MatchAllQuery->new() ]);
	while (my $doc = $docs->next()) {
		my $key = $doc->{$field};
		if (defined $key) {$res{uc($key)} = 1;}
	}
	return %res;
}

sub getLexicon {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};

	my $result	= resultArr->new();

	my $polyreader = Lucy::Index::IndexReader->open( index => $self->{_index},);
	my $seg_readers = $polyreader->seg_readers;
	for my $seg_reader (@$seg_readers) {
		my $lex_reader = $seg_reader->obtain('Lucy::Index::LexiconReader');
		my $lex = $lex_reader->lexicon( field => $field );
                if (defined $lex) {
                        while ( $lex->next() ) {
                                $result->_push(value => $lex->get_term());
                        }
                }
        }
	return $result;
}


sub getPostings {
	my $self	= shift;
	my %args	= @_;
	my $field	= $args{field};
	my $term	= $args{term};

	my $result	= resultArr->new();

	my $polyreader = Lucy::Index::IndexReader->open( index => $self->{_index},);
	my $seg_readers = $polyreader->seg_readers;
	for my $seg_reader (@$seg_readers) {
		my $posting_list_reader = $seg_reader->obtain("Lucy::Index::PostingListReader");
		my $doc_reader = $seg_reader->obtain("Lucy::Index::DocReader");

		my $posting_list = $posting_list_reader->posting_list( 
			field => $field,
			term  => $term,
		);
		while ( my $doc_id = $posting_list->next() ) {
			my $doc = $doc_reader->fetch_doc($doc_id);
			$result->_push(value=>$doc);
		}
	}
	return $result;
}

package resultArr;
sub new {
	my $class	= shift;
	my @result;
	my $self = {
		_result	=> \@result,
	};

	bless $self,$class;
	return $self;
}
sub _push {
        my $self        = shift;
        my %args        = @_;
        my $value       = $args{value};

	push (@{$self->{_result}}, $value);
}
sub next {
        my $self        = shift;

	my $result	= shift (@{$self->{_result}});
	return $result;
}
sub length {
	my $self	= shift;

	return scalar(@{$self->{_result}});
}

1;

=pod

=head1 NAME

SVN::TeamTools::Index::Index

=head1 DESCRIPTION

Parent class for all Lucy index used by SVN::TeamTools. For internal use only. See the 'child' modules (like Indexer and DepIndex) for details on how to use the search index.

=head1 AUTHOR

Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut

