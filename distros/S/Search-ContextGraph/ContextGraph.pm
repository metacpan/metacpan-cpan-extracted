package Search::ContextGraph;

use strict;
use warnings;
use Carp;
use base "Storable";
use File::Find;
use IO::Socket;

our $VERSION = '0.15';


my $count = 0;


=head1 NAME

Search::ContextGraph - spreading activation search engine

=head1 SYNOPSIS

  use Search::ContextGraph;

  my $cg = Search::ContextGraph->new();

  # first you add some documents, perhaps all at once...
  
  my %docs = (
    'first'  => [ 'elephant', 'snake' ],
    'second' => [ 'camel', 'pony' ],
    'third'  => { 'snake' => 2, 'constrictor' => 1 },
  );

  $cg->bulk_add( %docs );
  
  # or in a loop...
  
  foreach my $title ( keys %docs ) {
  	 $cg->add( $title, $docs{$title} );
  }

  #	or from a file...

  my $cg = Search::ContextGraph->load_from_dir( "./myfiles" );

  # you can store a graph object for later use
  
  $cg->store( "stored.cng" );
  
  # and retrieve it later...
  
  my $cg = ContextGraph->retrieve( "stored.cng" );
  
  
  # SEARCHING
  
  # the easiest way 

  my @ranked_docs = $cg->simple_search( 'peanuts' );


  # get back both related terms and docs for more power

  my ( $docs, $words ) = $cg->search('snake');


  # you can use a document as your query

  my ( $docs, $words ) = $cg->find_similar('First Document');


  # Or you can query on a combination of things

  my ( $docs, $words ) = 
    $cg->mixed_search( { docs  => [ 'First Document' ],
                         terms => [ 'snake', 'pony' ]
                     );


  # Print out result set of returned documents
  foreach my $k ( sort { $docs->{$b} <=> $docs->{$a} }
      keys %{ $docs } ) {
      print "Document $k had relevance ", $docs->{$k}, "\n";
  }



  # Reload it
  my $new = Search::ContextGraph->retrieve( "filename" );



=head1 DESCRIPTION

Spreading activation is a neat technique for building search engines that 
return accurate results for a query even when there is no exact keyword match.
The engine works by building a data structure called a B<context graph>, which
is a giant network of document and term nodes.  All document nodes are connected
to the terms that occur in that document; similarly, every term node is connected
to all of the document nodes that term occurs in.   We search the graph by 
starting at a query node and distributing a set amount of energy to its neighbor
nodes.  Then we recurse, diminishing the energy at each stage, until this
spreading energy falls below a given threshold.   Each node keeps track of 
accumulated energy, and this serves as our measure of relevance.  

This means that documents that have many words in common will appear similar to the
search engine.  Likewise, words that occur together in many documents will be 
perceived as semantically related.  Especially with larger, coherent document 
collections, the search engine can be quite effective at recognizing synonyms
and finding useful relationships between documents. You can read a full 
description of the algorithm at L<http://www.nitle.org/papers/Contextual_Network_Graphs.pdf>.

The search engine gives expanded recall (relevant results even when there is no
keyword match) without incurring the kind of computational and patent issues
posed by latent semantic indexing (LSI).  The technique used here was originally
described in a 1981 dissertation by Scott Preece.

=head1 CONSTRUCTORS

=over

=item new %PARAMS

Object constructor.   Possible parameters:

=over

=item auto_reweight

Rebalance the graph every time a change occurs. Default is true.
Disable and do by hand using L<reweight_graph> for better performance in
graphs with frequent updates/additions/deletions.


=item debug LEVEL

Set this to 1 or 2 to turn on verbose debugging output

=item max_depth

Set the maximum distance to spread energy out from the start
node.  Default is effectively unlimited.  You can tweak it using L<set_max_depth>.
Comes in handy if you find searches are too slow.

=item xs

When true, tells the module to use compiled C internals.  This reduces
memory requirements by about 60%, but actually runs a little slower than the 
pure Perl version.  Don't bother to turn it on unless you have a huge graph. 
Default is pure Perl.

=over

=item * using the compiled version makes it impossible to store the graph to disk.

=item * xs is B<broken> in version 0.09.   But it will return in triumph!

=back 

=item START_ENERGY

Initial energy to assign to a query node.  Default is 100.

=item ACTIVATE_THRESHOLD

Minimal energy needed to propagate search along the graph.  Default is 1.

=item COLLECT_THRESHOLD

Minimal energy needed for a node to enter the result set.  Default is 1.

=back

=cut


sub new {
	my ( $class, %params) = @_;

	# backwards compatible...
	*add_document = \&add;
	*add_documents = \&bulk_add;
	
	# plucene friendly
	*optimize	= \&reweight_graph;
	*is_indexed = \&has_doc;
	
	# fail on all unknown paramters (helps fight typos)
	my @allowed = qw/debug auto_reweight use_global_weights max_depth START_ENERGY ACTIVATE_THRESHOLD COLLECT_THRESHOLD use_file xs/;
	my %check;
	$check{$_}++ foreach @allowed;
	
	my @forbidden;
	foreach my $k ( keys %params ) {
		push @forbidden, $k unless exists $check{$k};
	}
	if ( @forbidden ) {
		croak "The following unrecognized parameters were detected: ", 
		join ", ", @forbidden;
	}


	my $obj = bless 
		{ debug => 0,
		  auto_reweight => 1,
		  use_global_weights => 1,
		  max_depth => 100000000,
		  START_ENERGY => 100,
		  ACTIVATE_THRESHOLD => 1,
		  COLLECT_THRESHOLD => .2,
	      %params,

	      depth => 0,
	      neighbors => {}, 

		}, 
	$class;
	
	
	if ( $obj->{use_file} ) {
		my %neighbors;
		use MLDBM qw/DB_File Storable/;
		use Fcntl;
		warn "Using MLDBM: $obj->{use_file}";
		$obj->{neighbors} = tie %neighbors, 'MLDBM', $obj->{use_file} or die $!;
		#$obj->{neighbors} = \%neighbors;
		
	
	}

	return $obj;

}


=item load_from_dir  DIR [, \&PARSE ]

Load documents from a directory.  Takes two arguments, a directory path
and an optional parsing subroutine.  If the parsing subroutine is passed
an argument, it will use it to extract term tokens from the file.
By default, the file is split on whitespace and stripped of numbers and
punctuation.

=cut

{
	my $parse_sub;

	sub load_from_dir  {
		my ( $class, $dir, $code ) = @_;

		croak "$dir is not a directory" unless -d $dir;

		require File::Find;
		unless ( defined $code 
				 and ref $code 
				 and ref $code eq 'CODE' ) {
			$code = sub {
				my $text = shift;
				$text =~ s/[^\w]/ /gs;
				my @toks = split /\s+/m, $text;
				return grep { length($_) > 1 } @toks;
			};
		}

		$parse_sub = $code;
		my %docs;

		# Recursively open every file and provide the contents
		# to whatever parsing subroutine we're using

		my $reader = 

			sub {
				my ( $parse ) = @_;
				return if /^\./;
				return unless -f $_;
				open my $fh, $_ or 
				   croak "Could not open file $File::Find::name: $!";
				local $/;
				my $contents = <$fh>;
				close $fh or croak "failed to close filehandle";
				my @words = $parse_sub->($contents);
				$docs{ $File::Find::name } = \@words;
			};


		find( $reader , $dir );
		my $self = __PACKAGE__->new();
		$self->bulk_add( %docs );
		return $self;
	}
}



=item load_from_tdm FILENAME

Opens and loads a term-document matrix (TDM) file to initialize the graph.
The TDM encodes information about term-to-document links.
This is a legacy method mainly for the convenience of the module author.
For notes on the proper file format, see the README file.
=cut

sub load_from_tdm {
	my  ( $self, $file ) = @_;
	croak "TDM file $file does not exist" unless -f $file;
	return if $self->{'loaded'};
	$self->_read_tdm( $file );
	$self->{'loaded'} = 1;
	$self->reweight_graph();
}


=item rename OLD, NEW

Renames a document.  Will return undef if the new name is already in use.

=cut
sub rename {

	my ( $self, $old, $new ) = @_;
	croak "rename method needs two arguments" unless
		defined $old and defined $new;
	croak "document $old not found" unless
		exists $self->{neighbors}{ _nodeify('D', $old ) };
	
	my $bad = _nodeify( 'D', $old );
	my $good = _nodeify( 'D', $new );
	
	return if exists $self->{neighbors}{$good};
	
	my $s = $self->{neighbors};
	foreach my $n ( keys %{ $s->{$bad} } ) {
		$s->{$good}{$n} = 
		$s->{$n}{$good} =
		$s->{$bad}{$n};
		delete $s->{$bad}{$n};
		delete $s->{$n}{$bad};
	}
	delete $s->{$bad};
	return 1;

}



=item retrieve FILENAME

Loads a previously stored graph from disk, using Storable.

=cut

sub retrieve {
	my ( $self, $file ) = @_;
	croak "Must provide a filename to retrieve graph"
		unless  $file;
	croak "'$file' is not a file" unless
		-f $file;

	Storable::retrieve( $file );
}


=back

=head1 ACCESSORS

=over

=item [get|set]_activate_threshold

Accessor for node activation threshold value.  This value determines how far 
energy can spread in the graph.  Lower it to increase the number of results.
Default is 1.

=cut

sub get_activate_threshold {    $_[0]->{'ACTIVATE_THRESHOLD'} }
sub set_activate_threshold {
	my ( $self, $threshold ) =  @_;
	croak "Can't set activate threshold to zero"
		unless $threshold;
	croak "Can't set activate threshold to negative value"
		unless $threshold > 0;
	$self->{'ACTIVATE_THRESHOLD'} = $_[1]; 
}


=item [get|set]_auto_reweight

Accessor for auto reweight flag.  If true, edge weights will be recalculated
every time a document is added, updated or removed.  This can significantly slow 
down large graphs.  On by default.

=cut

sub get_auto_reweight{ $_[0]->{auto_reweight} }
sub set_auto_reweight{ $_[0]->{auto_reweight} = $_[0]->[1]; }


=item [get|set]_collect_threshold

Accessor for collection threshold value.  This determines how much energy a
node must have to make it into the result set.  Lower it to increase the 
number of results.   Default is 1.

=cut

sub get_collect_threshold {  
	return ( $_[0]->{'xs'} ? 
		$_[0]->{Graph}->collectionThreshold :
		$_[0]->{'COLLECT_THRESHOLD'})
 }

sub set_collect_threshold {	
	 my ( $self, $newval ) = @_;

	 $newval ||=0;

	 $self->{Graph}->collectionThreshold( $newval )
	 	if $self->{'xs'};

	 $self->{'COLLECT_THRESHOLD'} = $newval || 0;
	 return 1;
}

=item [get|set]_debug_mode LEVEL

Turns debugging on or off.  1 is verbose, 2 is very verbose, 0 is off.

=cut

sub get_debug_mode { $_[0]->{debug} }
sub set_debug_mode {
	my ( $self, $mode ) = @_;
	$self->{'debug'} = $mode;
}



=item [get|set]_initial_energy

Accessor for initial energy value at the query node.  This controls how 
much energy gets poured into the graph at the start of the search.
Increase this value to get more results from your queries.

=cut

sub get_initial_energy { $_[0]->{'START_ENERGY'} }
sub set_initial_energy { 
	my ( $self, $start_energy ) = @_;
	croak "Can't set initial energy to zero"
		unless $start_energy;
	croak "Can't set initial energy to negative value"
		unless $start_energy > 0;
	$self->{'START_ENERGY'} = $start_energy ;
}

=item [get|set]_max_depth LEVEL

You can tell the graph to cut off searches after a certain distance from
the query node.  This can speed up searches on very large graphs, and has
little adverse effect, especially if you are interested in just the first
few search results.  Set this value to undef to restore the default (10^8).

=cut

sub get_max_depth { $_[0]->{max_depth} }
sub set_max_depth { croak "Tried to set maximum depth to an undefined value" 
	 unless defined $_[1];
	 $_[0]->{max_depth} = $_[1] || 100000000 
}




=back

=head1 METHODS

=over 

=item add DOC, WORDS

Add a document to the search engine.  Takes as arguments a unique doc
identifier and a reference to an array or hash of words in the 
document.
For example:

	TITLE => { WORD1 => COUNT1, WORD2 => COUNT2 ... }

or

	TITLE => [ WORD1, WORD2, WORD3 ]

Use L<bulk_add> if you want to pass in a bunch of docs all at once.

=cut


sub add {

	my ( $self, $title, $words ) = @_;


	croak "Please provide a word list" unless defined $words;
	croak "Word list is not a reference to an array or hash"
		unless ref $words and ref $words eq "HASH" or ref $words eq "ARRAY";

	croak "Please provide a document identifier" unless defined $title;

	my $dnode =  _nodeify( 'D', $title );
	croak "Tried to add document with duplicate identifier: '$title'\n"
		if exists $self->{neighbors}{$dnode};

	my @list;
	if ( ref $words eq 'ARRAY' ) {
		@list = @{$words};
	} else {
		@list = keys %{$words};
	}

	croak "Tried to add a document with no content" unless scalar @list;

	my @edges;
	foreach my $term ( @list ) {
		my $tnode = _nodeify( 'T', lc( $term ) );

		# Local weight for the document
		my $lcount = ( ref $words eq 'HASH' ? $words->{$term} : 1 );

		# Update number of docs this word occurs in
		my $gcount = ++$self->{term_count}{lc( $term )};

		my $final_weight = 1;
		push @edges, [ $dnode, $tnode, $final_weight, $lcount ];

	}
	$self->{reweight_flag} = 1;
	__normalize( \@edges );


=cut

DEVELOPMENT 

	if ( $self->{supersize} ) {
		my $n = $self->{neighbors};
		foreach my $e ( @edges ) {
			#warn "adding edge $e->[0], $e->[1]\n";
			
			$n->{$e->[0]} = {} unless exists $n->{$e->[0]};
			$n->{$e->[1]} = {} unless exists $n->{$e->[1]};
			
			my $tmp = $n->{$e->[0]};
			$tmp->{$e->[1]} = join ',', $e->[2], $e->[3];
			$tmp = $n->{$e->[1]};
			$tmp->{$e->[0]} = join ',', $e->[2], $e->[3];
		}
=cut

		
	# PURE PERL VERSION 
	#}  else 	{
		foreach my $e ( @edges ) {
			$self->{neighbors}{$e->[0]}{$e->[1]} = join ',', $e->[2], $e->[3];
			$self->{neighbors}{$e->[1]}{$e->[0]} = join ',', $e->[2], $e->[3];
		}
	#}
	
	
	#print "Reweighting graph\n";
	$self->reweight_graph() if $self->{auto_reweight};
	return 1;

}


=item add_file PATH [, name => NAME, parse => CODE]

Adds a document from a file.   By default, uses the PATH provided as the document
identifier, and parses the file by splitting on whitespace.  If a fancier title, 
or more elegant parsing behavior is desired, pass in named arguments as indicated.
NAME can be any string, CODE should be a reference to a subroutine that takes one
argument (the contents of the file) and returns an array of tokens, or a hash in the
form TOKEN => COUNT, or a reference to the same.

=cut

sub add_file {
	my ( $self, $path, %params ) = @_;
	
	croak "Invalid file '$path' provided to add_file method."
		unless defined $path and -f $path;
		
	my $title = ( exists $params{name} ? $params{name} : $path );

	local $/;
	open my $fh, $path or croak "Unable to open $path: $!";
	my $content = <$fh>;
	
	my $ref;
	
	if ( exists $params{parse} ) {
		croak "code provided is not a reference" unless
			ref $params{parse};
		croak "code provided is not a subroutine" unless
			ref $params{parse} eq 'CODE';
		
		$ref = $params{parse}->( $content );
		croak "did not get an appropriate reference back after parsing"
			unless ref $ref and ref $ref =~ /(HASH|ARRAY)/;
		
		
	} else {
	
		my $code = sub { 
			my $txt  = shift; 
			$txt =~ s/\W/ /g;
			my @toks = split m/\s+/, $txt;
			\@toks;
		};
		$ref = $code->($content);
	}
	
	return unless $ref;
	$self->add( $title, $ref );
	
}

=item bulk_add DOCS

Add documents to the graph in bulk.  Takes as an argument a hash
whose keys are document identifiers, and values are references
to hashes in the form { WORD1 => COUNT, WORD2 => COUNT...}
This method is faster than adding in documents one by one if
you have auto_rebalance turned on.

=cut

sub bulk_add {

	my ( $self, %incoming_docs ) = @_;

	# Disable graph rebalancing until we've added everything
	{
		local $self->{auto_reweight} = 0;

		foreach my $doc ( keys %incoming_docs ) {
			$self->add( $doc, $incoming_docs{$doc});
		} 
	}
	$self->reweight_graph() if $self->{auto_reweight};
}


=item degree NODE

Given a raw node, returns the degree (raw node means the node must
be prefixed with 'D:' or 'T:' depending on type )

=cut

sub degree { scalar keys %{$_[0]->{neighbors}{$_[1]}} }


=item delete DOC

Remove a document from the graph.  Takes a document identifier
as an argument.  Returns 1 if successful, undef otherwise.

=cut

sub delete {

	my ( $self, $type, $name ) = @_;
	
	croak "Must provide a node type to delete() method" unless defined $type;
	croak "Invalid type $type passed to delete method.  Must be one of [TD]"
		unless $type =~ /^[TD]$/io;
	croak "Please provide a node name" unless defined $name;
	
	return unless defined $name;
	my $node = _nodeify( $type, $name);

	my $n = $self->{neighbors};
	croak "Found a neighborless node $node"
		unless exists $n->{$node};

	my @terms = keys %{ $n->{$node} };

	warn "found ", scalar @terms, " neighbors attached to $node\n"
		if $self->{debug};
	# Check to see if we have orphaned any terms
	foreach my $t ( @terms ) {
		
		delete $n->{$node}{$t};
		delete $n->{$t}{$node};

		if ( scalar keys %{ $n->{$t} } == 0 ) {
			warn "\tdeleting orphaned node $t" if $self->{debug};
			my ( $subtype, $name ) = $t =~ /^(.):(.*)$/;
			#$self->delete( $subtype, $name );
			delete $n->{$t};
		}
	}

	delete $n->{$node};
	$self->check_consistency();
	$self->{reweight_flag} = 1;
	$self->reweight_graph if $self->{auto_reweight};
	1;
}



=item has_doc DOC

Returns true if the document with identifier DOC is in the collection

=cut

sub has_doc { 
	my ( $self, $doc ) = @_;
	carp "Received undefined value for has_doc" unless defined $doc;
	my $node = _nodeify( 'D', $doc );
	return exists $self->{neighbors}{$node} ||  undef;
}

=item has_term TERM

Returns true if the term TERM is in the collection

=cut

sub has_term { 
	my ( $self, $term ) = @_;
	carp "Received undefined value for has_term" unless defined $term;
	my $node = _nodeify( 'T', $term );
	return exists $self->{neighbors}{$node} || undef;
}	



=item distance NODE1, NODE2, TYPE

Calculates the distance between two nodes of the same type (D or T)
using the formula:

	distance = ...
=cut

sub distance {
	my ( $self, $n1, $n2, $type ) = @_;
	croak unless $type;
	$type = lc( $type );
	croak unless $type =~ /^[dt]$/;
	my $key = ( $type eq 't' ? 'terms' : 'documents' );
	my @shared = $self->intersection( $key => [ $n1, $n2 ] );
	return 0 unless @shared;
	#warn "Found ", scalar @shared, " nodes shared between $n1 and $n2\n";
	
	my $node1 = _nodeify( $type, $n1 );
	my $node2 = _nodeify( $type, $n2 );
	# formula is w(t1,d1)/deg(d1) + w(t1,d2)/deg(d2) ... ) /deg( t1 )
	
	#warn "Calculating distance\n";
	my $sum1 = 0;
	my $sum2 = 0;
	foreach my $next ( @shared ) {
		my ( undef, $lcount1) =  split m/,/, $self->{neighbors}{$node1}{$next};
		my ( undef, $lcount2) =  split m/,/, $self->{neighbors}{$node2}{$next};

		my $degree = $self->degree( $next );
		#warn "\t degree of $next is $degree\n";
		my $elem1 = $lcount1 / $degree;
		$sum1 += $elem1;
		my $elem2 = $lcount2 / $degree;
		$sum2 += $elem2;
	}
	#warn "sum is $sum1, $sum2\n";
	my $final = ($sum1 / $self->degree( $node1 )) + ( $sum2 / $self->degree( $node2 ));
	#warn "final is $final\n";
	return $final;
	
	
}

=item distance_matrix TYPE LIMIT

Used for clustering using linear local embedding.  Produces a similarity matrix
in a format I'm too tired to document right now.  LIMIT is the maximum number
of neighbors to keep for each node.

=cut

sub distance_matrix {
	my ( $self, $type, $limit ) = @_;
	croak "Must provide type argument to distance_matrix()" 
		unless defined $type;
	croak "must provide limit" unless $limit;
	my @nodes;
	if ( lc( $type ) eq 'd' ) {
		@nodes = $self->doc_list();
	} elsif ( lc( $type ) eq 't' ) {
		@nodes = $self->term_list();
	} else {
		croak "Unsupported type $type";
	}
	
	my @ret;
	my $count = 0;
	foreach my $from ( @nodes ) {
		warn $from, " - $count\n";
		$count++;
		my $index = -1;
		my @found;
		foreach my $to ( @nodes ) {
			$index++;
			next if $from eq $to;
			my $dist = $self->distance( $from, $to, $type );
			push @found, [ $index, $dist ] if $dist;
			#print( $index++, ' ', $dist, " " ) if $dist;
		}
		my @sorted = sort { $b->[1] <=> $a->[1] } @found;
		my @final = splice ( @sorted, 0, $limit );
		push @ret, join " ", ( map { join ' ', $_->[0],  substr($_->[1], 0, 7)  } 
						  sort { $a->[0] <=> $b->[0] } 
						  @final), "\n";
		#print "\n";
	}
	return join "\n", @ret;

}

=item intersection @NODES

Returns a list of neighbor nodes that all the given nodes share in common

=cut

sub intersection {
	my ( $self, %nodes ) = @_;
	my @nodes;
	if ( exists $nodes{documents} ) {
		push @nodes, map { _nodeify( 'D', $_ ) } @{ $nodes{documents}};
	} 
	if ( exists $nodes{terms} ) {
		push @nodes, map { _nodeify( 'T', $_ ) } @{ $nodes{terms}};
	} 
	
	my %seen;
	foreach my $n ( @nodes ) {
		my @neighbors = $self->_neighbors( $n );
		$seen{ $_ }++ foreach @neighbors;
	}
	return map { s/^[DT]://; $_ }
		   grep { $seen{$_} == scalar @nodes } 
		   keys %seen;
}

=item raw_search @NODES

Given a list of nodes, returns a hash of nearest nodes with relevance values,
in the format NODE => RELEVANCE, for all nodes above the threshold value. 
(You probably want one of L<search>, L<find_similar>, or L<mixed_search> instead).

=cut

sub raw_search {
	my ( $self, @query ) = @_;

	$self->_clear();
	foreach ( @query ) {
		$self->_energize( $_, $self->{'START_ENERGY'});
	}
	my $results_ref = $self->_collect();


	return $results_ref;
}




=item reweight_graph

Iterates through the graph, calculating edge weights and normalizing 
around nodes.  This method is automatically called every time a 
document is added, removed, or updated, unless you turn the option
off with auto_reweight(0).   When adding a lot of docs, this can be
time consuming, so either set auto_reweight to off or use the 
L<bulk_add> method to add lots of docs at once

=cut

sub reweight_graph {
	my ( $self ) = @_;

	my $n = $self->{neighbors}; #shortcut
	my $doc_count = $self->doc_count();
	#print "Renormalizing for doc count $doc_count\n" if $self->{debug};
	foreach my $node ( keys %{$n} ) {

		next unless $node =~ /^D:/o;
		warn "reweighting at node  $node\n" if $self->{debug} > 1;
		my @terms = keys %{ $n->{$node} };
		my @edges;
		foreach my $t ( @terms ) {

			my $pair = $n->{$node}{$t};
			my ( undef, $lcount ) = split /,/, $pair;
			( my $term = $t ) =~ s/^T://;
			croak "did not receive a local count" unless $lcount;
			my $weight;
			if ( $self->{use_global_weights} ) {

				my $gweight = log( $doc_count / $self->doc_count( $term ) ) + 1;
				my $lweight = log( $lcount ) + 1;
				$weight = ( $gweight * $lweight );
				
			} else {

				$weight = log( $lcount ) + 1;
			}
			push @edges, [ $node, $t, $weight, $lcount ];
		}

		__normalize( \@edges );

		foreach my $e ( @edges ) {
			my $pair = join ',', $e->[2], $e->[3];
			$n->{$node}{$e->[1]} = $n->{$e->[1]}{$node} = $pair;
		}
	}
	$self->{reweight_flag} = 0;
	return 1;
}




=item update ID, WORDS

Given a document identifier and a word list, updates the information for
that document in the graph.  Returns the number of changes made

=cut

sub update {

	my ( $self, $id, $words ) = @_;

	croak "update not implemented in XS" if $self->{xs};
	croak "Must provide a document identifier to update_document" unless defined $id;
	my $dnode = _nodeify( 'D', $id );

	return unless exists $self->{neighbors}{$dnode};
	croak "must provide a word list " 
		unless defined $words and 
						ref $words and
					  ( ref $words eq 'HASH' or
						ref $words eq 'ARRAY' );

	my $n = $self->{neighbors}{$dnode};
	
	# Get the current word list
	my @terms = keys %{ $n };

	if ( ref $words eq 'ARRAY' ) {
		my %words;
		$words{$_}++ foreach @$words;
		$words = \%words;
	}

	local $self->{auto_reweight} = 0;

	my $must_reweight = 0;
	my %seen;

	foreach my $term ( keys %{$words} ) {

		my $t = _nodeify( 'T', $term );

		if ( exists $n->{$t} ){

			# Update the local count, if necessary
			my $curr_val = $n->{$t};
			my ( undef, $loc ) = split m/,/, $curr_val;

			unless ( $loc == $words->{$term} ) {
				$n->{$t} = join ',', 1, $words->{$term};
				$must_reweight++;
			}	
			}

		else {

			$n->{$t} = 
				$self->{neighbors}{$t}{$dnode} = 
				join ',', 1, $words->{$term};
			$must_reweight++;
		}

		$seen{$t}++;
	}

	# Check for deleted words
	foreach my $t ( @terms ) {
		$must_reweight++ 
			unless exists $seen{$t};
	}

	$self->reweight_graph() if 
		$must_reweight;

	return $must_reweight;

}


=item doc_count [TERM]

Returns a count of all documents that TERM occurs in.
If no argument is provided, returns a document count
for the entire collection.

=cut

sub doc_count {
	my ( $self, $term ) = @_;
	if ( defined $term ) {
		$term = _nodeify( 'T', $term ) unless $term =~ /^T:/;
		my $node = $self->{neighbors}{$term};
		return 0 unless defined $node;
		return scalar keys %{$node};
	} else {
		return scalar grep /D:/, 
			keys %{ $self->{'neighbors'} };
	}
}


=item doc_list [TERM]

Returns a sorted list of document identifiers that contain
TERM, in ASCII-betical order.  If no argument is given,
returns a sorted document list for the whole collection.

=cut

sub doc_list {
	my ( $self, $term ) = @_;
	my $t;
	if ( defined $term and $term !~ /T:/) {
		$t = _nodeify( 'T', $term );
	}
	my $hash = ( defined $term ?
				 $self->{neighbors}{$t} :
				 $self->{neighbors} );

	sort map { s/^D://o; $_ }
		 grep /^D:/, keys %{ $hash };
}


sub dump {
	my ( $self ) = @_;
	my @docs = $self->doc_list();

	foreach my $d ( @docs ) {
		print $self->dump_node( $d );
	}
}

=item dump_node NODE

Lists all of the neighbors of a node, together with edge
weights connecting to them

=cut

sub dump_node {
	my ( $self, $node ) = @_;

	my @lines;
	push @lines, join "\t", "COUNT", "WEIGHT", "NEIGHBOR";

	foreach my $n ( keys %{ $self->{neighbors}{$node} } ) {
		my $v = $self->{neighbors}{$node}{$n};
		my ( $weight, $count ) = split /,/, $v;
		push @lines, join "\t", $count, substr( $weight, 0, 8 ), $n;
	}
	return @lines;
}



=item dump_tdm [FILE]

Dumps internal state in term-document matrix (TDM) format, which looks 
like this:

	A B C B C B C
	A B C B C B C
	A B C B C B C

Where each row represents a document, A is the number of terms in the
document, B is the term node and C is the edge weight between the doc
node and B.   Mostly used as a legacy format by the module author. 
Doc and term nodes are printed in ASCII-betical sorted order, zero-based 
indexing.  Up to you to keep track of the ID => title mappings, neener-neener!
Use doc_list and term_list to get an equivalently sorted list

=cut

sub dump_tdm {
	my ( $self, $file ) = @_;

	my $counter = 0;
	my %lookup;
	$lookup{$_} = $counter++ foreach $self->term_list;

	my @docs = $self->doc_list;

	my $fh;
	if ( defined $file ) {
		open $fh, "> $file" or croak
			"Could not open TDM output file: $!";
	} else {
		*fh = *STDOUT;
	}
	foreach my $doc ( @docs ) {
		my $n = $self->{neighbors}{$doc};

		my $row_count = scalar keys %{$n};
		print $fh $row_count;

		foreach my $t ( sort keys %{$doc} ) {
			my $index = $lookup{$t};
			my ( $weight, undef ) = split m/,/, $n->{$t};
			print $fh ' ', $index, ' ', $weight;
		}
		print $fh "\n";
	}
}



=item near_neighbors [NODE] 

Returns a list of neighbor nodes of the same type (doc/doc, or term/term) two
hops away.

=cut

sub near_neighbors {
	my ( $self, $name, $type ) = @_;
	
	my $node = _nodeify( $type, $name );
	
	my $n = $self->{neighbors}{$node};
	
	my %found;
	foreach my $next ( keys %{$n} ) {
		foreach my $mynext ( keys %{ $self->{neighbors}{$next} }){
			$found{$mynext}++;
		}
	}
	delete $found{$node};
	return keys %found;
}


=item term_count [DOC]

Returns the number of unique terms in a document or,
if no document is specified, in the entire collection.

=cut

sub term_count {
	my ( $self, $doc ) = @_;
	if ( defined $doc ) {
		my $node = $self->{neighbors}{ _nodeify( 'D', $doc) };
		return 0 unless defined $node;
		return scalar keys %{$node};
	} else {
		return scalar grep /T:/, 
		keys %{ $self->{neighbors} };
	}
}


=item term_list [DOC]

Returns a sorted list of unique terms appearing in the document
with identifier DOC, in ASCII-betical order.  If no argument is
given, returns a sorted term list for the whole collection.

=cut

sub term_list {
	my ( $self, $doc ) = @_;

	my $node = ( defined $doc ?
				 $self->{neighbors}{ _nodeify( 'D', $doc) } :
				 $self->{neighbors}
			 );

	sort map { s/^T://o; $_ }
		 grep /^T:/, keys %{ $node };
}



=item word_count [TERM]

Returns the total occurence count for a term, or if no argument is given,
a word count for the entire collection.  The word count is always greater than
or equal to the term count.

=cut

sub word_count {

	my ( $self, $term ) = @_;

	my $n = $self->{neighbors}; # shortcut

	my $count = 0;
	my @terms;
	if ( defined $term ) {
		push @terms, $term;
	}	else {
		@terms = $self->term_list();
	}

	foreach my $term (@terms ) {
		$term = _nodeify( 'T', $term) unless $term =~/^T:/o;
		foreach my $doc ( keys %{ $n->{$term} } ) {
			( undef, my $lcount ) = split /,/, $n->{$term}{$doc};
			$count += $lcount;
		}
	}

	return $count;
}





=item search @QUERY

Searches the graph for all of the words in @QUERY.  Use find_similar if you
want to do a document similarity instead, or mixed_search if you want
to search on any combination of words and documents.  Returns a pair of hashrefs:
the first a reference to a hash of docs and relevance values, the second to 
a hash of words and relevance values.

=cut

sub search {
	my ( $self, @query ) = @_;	
	my @nodes = _nodeify( 'T', @query );
	my $results = $self->raw_search( @nodes );	
	my ($docs, $words) = _partition( $results );
	return ( $docs, $words);
}



=item simple_search QUERY

This is the DWIM method - takes a query string as its argument, and returns an array
of documents, sorted by relevance.

=cut

sub simple_search {
	my ( $self, $query ) = @_;
	my @words = map { s/\W+//g; lc($_) }
				split m/\s+/, $query;	
	my @nodes = _nodeify( 'T', @words );
	my $results = $self->raw_search( @nodes );
	my ($docs, $words) = _partition( $results );
	my @sorted_docs = sort { $docs->{$b} <=> $docs->{$a} } keys %{$docs};
	return @sorted_docs;
}

=item find_by_title @TITLES

Given a list of patterns, searches for documents with matching titles

=cut

sub find_by_title {	
	my ( $self, @titles ) = @_;
	my @found;
	my @docs = $self->doc_list();
	my $pattern = join '|', @titles;
	my $match_me = qr/$pattern/i;
	#warn $match_me, "\n";
	foreach my $d ( @docs ) {
	#	warn $d, "\n";
		push @found, $d if $d =~ $match_me;
	}
	return @found;
}


=item find_similar @DOCS

Given an array of document identifiers, performs a similarity search 
and  returns a pair of hashrefs. First hashref is to a hash of docs and relevance
 values, second is to a hash of words and relevance values.

=cut

sub find_similar {
	my ( $self, @docs ) = @_;
	my @nodes = _nodeify( 'D', @docs );
	my $results = $self->raw_search( @nodes );
	my ($docs, $words) = _partition( $results );
	return ( $docs, $words);
}


=item merge TYPE, GOOD, @BAD

Combine all the nodes in @BAD into the node with identifier GOOD.
First argument must be one of 'T' or 'D' to indicate term or
document nodes.    Used to combine synonyms in the graph.

=cut

sub merge {
	my ( $self, $type, $good, @bad ) = @_;
	croak "must provide a type argument to merge"
		unless defined $type;
	croak "Invalid type argument $type to merge [must be one of (D,T)]" 
		unless $type =~ /^[DT]/io;
	
	my $target  = _nodeify( $type, $good );
	my @sources = _nodeify( $type, @bad );
	
	my $tnode = $self->{neighbors}{$target};
	

	foreach my $bad_node ( @sources ) {
		#print "Examining $bad_node\n";
		next if $bad_node eq $target;
		my %neighbors = %{$self->{neighbors}{$bad_node}};
		
		foreach my $n ( keys %neighbors ) {
			
			#print "\t $target ($bad_node) neighbor $n\n";
			if ( exists  $self->{neighbors}{$target}{$n} ) {
				#print "\t\t$n has link to $bad_node\n";
				# combine the local counts for the term members of the edge
				my $curr_val = $tnode->{$n};
				my $aug_val  = $self->{neighbors}{$bad_node}{$n};
				my ($w1, $c1) = split m/,/, $curr_val;
				my ($w2, $c2) = split m/,/, $aug_val;
				my $new_count = $c1 + $c2;
				$curr_val =~ s/,\d+$/,$new_count/;
				$tnode->{$n} = $curr_val;
				
				
			} else {
				
				die "sanity check failed for existence test"
					if exists $self->{neighbors}{$target}{$n};
				
				my $val = $self->{neighbors}{$bad_node}{$n};
				
				#print "\tno existing link -- reassigning $target -- $n\n";
				# reassign the current value of this edge
			    
				$self->{neighbors}{$n}{$target} = $val;
				$self->{neighbors}{$target}{$n} = $val;
			}
			
			delete $self->{neighbors}{$bad_node}{$n};
			delete $self->{neighbors}{$n}{$bad_node};
		}
		delete $self->{neighbors}{$bad_node};
	}
}

=item mixed_search @DOCS

Given a hashref in the form:
    { docs => [ 'Title 1', 'Title 2' ],
      terms => ['buffalo', 'fox' ], }
     }
Runs a combined search on the terms and documents provided, and
returns a pair of hashrefs.  The first hashref is to a hash of docs
and relevance values, second is to a hash of words and relevance values.

=cut

sub mixed_search {
	my ( $self, $incoming ) = @_;

	croak "must provide hash ref to mixed_search method"
		unless defined $incoming &&
		ref( $incoming ) &&
		ref( $incoming ) eq 'HASH';

	my $tref = $incoming->{'terms'} || [];
	my $dref = $incoming->{'docs'}  || [];

	my @dnodes = _nodeify( 'D', @{$dref} );
	my @tnodes = _nodeify( 'T', @{$tref} );

	my $results = $self->raw_search( @dnodes, @tnodes );
	my ($docs, $words) = _partition( $results );
	return ( $docs, $words);
}


=item store FILENAME

Stores the object to a file for later use.  Not compatible (yet)
with compiled XS version, which will give a fatal error.

=cut

sub store {
	my ( $self, @args ) = @_;
	if ( $self->{'xs'} ) {
		croak "Cannot store object when running in XS mode.";
	} else {
		$self->SUPER::nstore(@args);
	}
}


# Partition - internal method.
# Takes a result set and splits it into two hashrefs - one for
# words and one for documents

sub _partition {
	my ( $e ) = @_;
	my ( $docs, $words );
	foreach my $k ( sort { $e->{$b} <=> $e->{$a} }
					keys %{ $e } ) {

		(my $name = $k ) =~ s/^[DT]://o;
		$k =~ /^D:/  ? 
			$docs->{$name} = $e->{$k}  :
			$words->{$name} = $e->{$k} ;
	}
	return ( $docs, $words );
}

# return a list of all neighbor nodes
sub _neighbors {
	my ( $self, $node ) = @_;
	return unless exists $self->{neighbors}{$node};
	return keys %{ $self->{neighbors}{$node} };
}


sub _nodeify {
	my ( $prefix, @list ) = @_;
	my @nodes;
	foreach my $item ( @list ) {
		push @nodes,  uc($prefix).':'.$item;
	}
	( wantarray ?  @nodes : $nodes[0] );
}



sub _read_tdm {
	my ( $self, $file ) = @_;
	print "Loading TDM...\n" if $self->{'debug'} > 1;

	croak "File does not exist" unless -f $file;
	open my $fh, $file or croak "Could not open $file: $!";
	for ( 1..4 ){
		my $skip = <$fh>;
	}
	my %neighbors;
	my $doc = 0;	


	######### XS VERSION ##############
	if ( $self->{'xs'} ) {

		my $map = $self->{'node_map'}; # shortcut alias
		while (<$fh>) {
			chomp;
			my $dindex = $self->_add_node( "D:$doc", 2 );
			#warn "Added node $doc\n";
			my ( $count, %vals ) = split;
			while ( my ( $term, $edge ) = each %vals ) {
				$self->{'term_count'}{$term}++;
				my $tnode = "T:$term";

				my $tindex = ( defined $map->{$tnode} ?
								$map->{$tnode} : 
							 	$self->_add_node( $tnode, 1 )
							);
				$self->{Graph}->set_edge( $dindex, $tindex, $edge );				
			}
			$doc++;
		}

	####### PURE PERL VERSION ##########
	} else {
		while (<$fh>) {
			chomp;
			my $dnode = "D:$doc";
			my ( $count, %vals ) = split;
			while ( my ( $term, $edge ) = each %vals ) {
				$self->{'term_count'}{$term}++;
				my $tnode = "T:$term";

				$neighbors{$dnode}{$tnode} = $edge.',1';
				$neighbors{$tnode}{$dnode} = $edge.',1';
			}
			$doc++;
		}
		$self->{'neighbors'} = \%neighbors;	
	}

	print "Loaded.\n" if $self->{'debug'} > 1;
	$self->{'from_TDM'} = 1;
	$self->{'doc_count'} = $doc;
}



# XS version only
#
# This sub maintains a mapping between node names and integer index
# values. 

sub _add_node {
	my ( $self, $node_name, $type ) = @_;
	croak "Must provide a type" unless $type;
	croak "Must provide a node name" unless $node_name;
	croak "This node already exists" if 
		 $self->{'node_map'}{$node_name};

	my $new_id = $self->{'next_free_id'}++;
	$self->{'node_map'}{$node_name} = $new_id;
	$self->{'id_map'}[$new_id] = $node_name;
	$self->{'Graph'}->add_node( $new_id, $type );

	return $new_id;
}



#
# 	INTERNAL METHODS
# 

# each node should have the same number of inbound
# and outbound links

sub check_consistency {

	my ( $self ) = @_;
	my %inbound;
	my %outbound;
	
	
	foreach my $node ( keys %{$self->{neighbors}} ) {
		next unless $node =~ /^[DT]:/; # for MLDBM compatibility
		$outbound{$node} = scalar keys %{$self->{neighbors}{$node}};
		foreach my $neighbor ( keys %{ $self->{neighbors}{$node} } )	{
			$inbound{$neighbor}++;
		}
	}
	
	my $in = scalar keys %inbound;
	my $out = scalar keys %outbound;
	carp "number of nodes with inbound links ($in) does not match number of nodes with outbound links ( $out )"
		unless scalar keys %inbound == scalar keys %outbound;
	
	foreach my $node ( keys %inbound ) {
		$outbound{$node} ||= 0;
		carp "$node has $inbound{$node} inbound links, $outbound{$node} outbound links\n"
			unless $inbound{$node} == $outbound{$node};
	}

}


=item have_edge RAWNODE1, RAWNODE2

Returns true if the nodes share an edge.  Node names must be prefixed with 'D' or 'T'
as appropriate.

=cut

sub have_edge {
	my ( $self, $node1, $node2 ) = @_;
	return exists $self->{neighbors}{$node1}{$node2};
}


{

	my %visited;
	my %component;
	my $depth;
	
=item connected_components

Returns an array of connected components in the graph.  Each component is a list
of nodes that are mutually accessible by traveling along edges.

=cut

	sub connected_components {
		my ( $self ) = @_;
		
		%visited = (); # clear any old info
		%component = ();
		
		
		my $n = $self->{neighbors};
		
		
		my @node_list =  keys %{$n};
		my @components;
		
		while ( @node_list ) {
			my $start = shift @node_list;
			next if exists $visited{$start};
			
			last unless $start;
			warn "Visiting neighbors for $start\n";
			visit_neighbors( $n, $start );
			push @components, [ keys %component ];
			 %component = ();
		}
		
		warn "Found ", scalar @components, " connected components\n";
		return @components;
		
		
	}

	sub visit_neighbors {
		my ( $g, $l ) = @_;
		return if $visited{$l};
		$depth++;
		$visited{$l}++; $component{$l}++;
		warn  $depth, "  $l\n";
		my @neigh = keys %{ $g->{$l} };		
		foreach my $n ( @neigh ) {
			visit_neighbors( $g, $n );
		}
		$depth--;
	}	
}


# Wipe the graph free of stored energies

sub _clear {
	my ( $self ) = @_;
	$self->{'energy'} = undef;
}


# Gather the stored energy values from the graph

sub _collect {
	my ( $self ) = @_;
	my $e = $self->{'energy'};
	my $result = {};
	foreach my $k ( keys %{$self->{'energy'}} ) {
		next unless $e->{$k} > $self->{'COLLECT_THRESHOLD'};
		$result->{$k} = $e->{$k};
	}
	return $result;
}




 #  Assign a starting energy ENERGY to NODE, and recursively distribute  the 
 #  energy to neighbor nodes.   Singleton nodes get special treatment 

sub _energize {

	my ( $self, $node, $energy ) = @_;


	return unless defined $self->{neighbors}{$node};
	my $orig = $self->{energy}{$node} || 0;
	$self->{energy}->{$node} += $energy;
	return if ( $self->{depth} == $self->{max_depth} );
	$self->{depth}++;

	if ( $self->{'debug'} > 1 ) {
		print '   ' x $self->{'depth'};
		print "$node: energizing  $orig + $energy\n";
	}


	my $n = $self->{neighbors};
	
	#sleep 1;
	my $degree = scalar keys %{ $n->{$node} };


	if ( $degree == 0 ) {
		
		carp "WARNING: reached a node without neighbors: $node at search depth $self->{depth}\n";
		$self->{depth}--;
		return;
	}
	
	
	my $subenergy = $energy / (log($degree)+1);


	# At singleton nodes (words that appear in only one document, for example)
	# Don't spread energy any further.  This avoids a "reflection" back and
	# forth from singleton nodes to their neighbors.

	if ( $degree == 1 and  $energy < $self->{'START_ENERGY'} ) {

		#do nothing

	} elsif ( $subenergy > $self->{ACTIVATE_THRESHOLD} ) {
		print '   ' x $self->{'depth'}, 
		"$node: propagating subenergy $subenergy to $degree neighbors\n"
		 if $self->{'debug'} > 1;
		foreach my $neighbor ( keys %{ $n->{$node} } ) {
			my $pair = $n->{$node}{$neighbor};
			my ( $edge, undef ) = split /,/, $pair;
			my $weighted_energy = $subenergy * $edge;
			print '   ' x $self->{'depth'}, 
			" edge $edge ($node, $neighbor)\n"
				if $self->{'debug'} > 1;
			$self->_energize( $neighbor, $weighted_energy );
		} 
	}	
	$self->{'depth'}--;	
	return 1;
}


# Given an array, normalize using cosine normalization

sub __normalize {
	my ( $arr ) = @_;

	croak "Must provide array ref to __normalize" unless
		defined $arr and
		ref $arr and
		ref $arr eq 'ARRAY';

	my $sum;
	$sum += $_->[2] foreach @{$arr};
	$_->[2]/= $sum foreach @{$arr};
	return 1;
}




sub DESTROY {
	undef $_[0]->{Graph}
}

1;

__END__

package Search::ContextGraph::SQLite;

use DBI;
use strict;
use warnings;

our %hash;

sub TIEHASH {
	my ( $class ) = @_;
	my $self = {};
	warn "Creating tied hash\n";
	my $dbh = DBI->connect("dbi:SQLite:dbname=test.db","","");
	if ( !-f "test.db" ) {
		my $sql = $dbh->do( "drop table edges; create table edges ( source char(100), sink char(100), weight float )" );
		my $sql = $dbh->do( "create index source on edges(source)" );
		my $sql = $dbh->do( "create index sink on edges(sink)" );
		my $sql = $dbh->do( "create unique index edge on edges(source, sink)" );
	}
	$self->{dbh} = $dbh;
	bless $self, $class;
}

sub FETCH {
	my ( $self, $key ) = @_;
	
	$self->{$key};	
}

sub STORE {
	my ( $self, $key, $value ) = @_;
	print "Storing key $key, value $value\n";
	#print ref $value, "\n";
	print "Hash has ", scalar %{$value}, "values\n";
	foreach my $k ( keys %{$value} ) {
		print "\t$k $value->{$k}\n";
	}
	$self->{$key} = $value
}

sub EXISTS {
	my ( $self, $key ) = @_;
	exists $self->{$key};
}

sub DELETE {
	my ( $self, $key ) = @_;
	delete $self->{$key};
}

sub FIRSTKEY { 
	my ( $self ) = @_;
	my $a = keys %{ $self };
	each %{ $self };
}

sub NEXTKEY {
	my ( $self ) = @_;
	each %{ $self };
}

sub DESTROY {}
	
1;


package Search::ContextGraph::TieWrapper;

use strict;
use warnings;

our %hash;

sub TIEHASH {
	my ( $class ) = @_;
	my $self = {};
	bless $self, $class;
}

sub FETCH {
	my ( $self, $key ) = @_;
	$self->{$key};	
}

sub STORE {
	my ( $self, $key, $value ) = @_;
	$self->{$key} = $value
}

sub EXISTS {
	my ( $self, $key ) = @_;
	exists $self->{$key};
}

sub DELETE {
	my ( $self, $key ) = @_;
	delete $self->{$key};
}

sub FIRSTKEY { 
	my ( $self ) = @_;
	my $a = keys %{ $self };
	each %{ $self };
}

sub NEXTKEY {
	my ( $self ) = @_;
	each %{ $self };
}

sub DESTROY {}
	
1;



=back

=head1 BUGS

=over

=item * Document-document links are not yet implemented

=item * Can't store graph if using compiled C internals

=back

=head1 AUTHOR 

Maciej Ceglowski E<lt>maciej@ceglowski.comE<gt>

The spreading activation technique used here was originally discussed in a 1981
dissertation by Scott Preece, at the University of Illinois.

XS implementation thanks to Schuyler Erle.

=head1 CONTRIBUTORS 

	Schuyler Erle
	Ken Williams
	Leon Brocard  

=head1 COPYRIGHT AND LICENSE

Perl module:
(C) 2003 Maciej Ceglowski

XS Implementation:
(C) 2003 Maciej Ceglowski, Schuyler Erle

This program is free software, distributed under the GNU Public License.
See LICENSE for details.


=cut
