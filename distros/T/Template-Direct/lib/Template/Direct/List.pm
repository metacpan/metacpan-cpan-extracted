package Template::Direct::List;

use base Template::Direct::Base;

use strict;
use warnings;

=head1 NAME

Template::Direct::List - Handle a list template display

=head1 DESCRIPTION

  Provide support for lists and repetitive templating

=head1 METHODS

=cut

use Carp;

=head2 I<$class>->new( $template, $data )

  Create a new instance object.

=cut
sub new {
	my ($class, $index, $data) = @_;
	my $self = $class->SUPER::new();
	$self->{'startTag'} = $index;
	my ($dataName, @options) = split(/\s+/, $data);
	$self->{'options'}  = $self->getOptions(join(' ', @options));
	$self->{'listName'} = $dataName;
	return $self;
}

=head2 I<$list>->tagName( )

  Returns 'list'

=cut
sub tagName { 'list' }

=head2 I<$list>->subTags( )

  Returns a list of expected tags in a list construct: [sublist, entry, noentry, seperator]

=cut
sub subTags {
    {
        'sublist'   => 0,
        'entry'     => 2,
		'noentry'   => 1,
		'seperator' => 1,
    }
}


=head2 I<$list>->compile( )

  Modifies a template with the data listed correctly.

=cut
sub compile {
    my ($self, $data, $template, %p) = @_;

	# Do list stuff here
	my $section = $self->getFullSection( $template );
	$self->{'contents'} = $self->getEntryContent( $section );
	my $result = $self->compileListData( $data, $self->{'listName'}, %p );

	# Prcoess any children in the section content
	$self->SUPER::compile( $data, \$result, %p );

	# Put the whole section back in the template
	$self->setSection( $template, $result )
}

=head2 I<$list>->compileListData( $data, $name, %p )

  From the scoped data object, find the data named data
  field and return it as a list.

=cut
sub compileListData {
	my ($self, $data, $dataName, %p) = @_;

	$p{'listDepth'} = 0 if not $p{'listDepth'};
	my $entry     = $self->{'contents'}->{'entry'};
	my $seperator = $self->{'contents'}->{'seperator'};
	my $noentry   = $self->{'contents'}->{'noentry'};
	my $section   = $self->{'contents'}->{'section'};
	my $sublist   = $self->{'contents'}->{'sublist'};

	# Make sure we have some data to list, limit the data to the curent
	# data scope this is to stop deepRecursions in list data.
	my $list   = $data->getArrayDatum( $dataName, maxDepth => 1 );
	my $result = '';

	if($list and $entry) {

		if(UNIVERSAL::isa($list, 'ARRAY')) {
			my $length = @{$list};
			my $depth  = 0; # NERN

			# Should we sort the data in some sort of order
			if(my $sort = $self->{'options'}->{'sort'}) {
				# We only support 'name' and 'value' for now
				# But there is scope to improve this functionality.
				if($sort eq '1') {
					if($self->{'options'}->{'numericalSort'}) {
						$list = [ sort { $a <=> $b } @{$list} ];
					} else {
						$list = [ sort { $a cmp $b } @{$list} ];
					}
				} else {
					# Loop through each and replace with hash (sorry)
					foreach my $item (@{$list}) {
						$item = $data->_makeHash( $item );
					}
					$list = [ sort { $a->{$sort} cmp $b->{$sort} } @{$list} ];
				}
			}    

			#print "FOUND LIST $length long based on ".$self->{'listName'}." and $entry\n";
			for(my $index = 0; $index < $length; $index++) {

				next if not defined $list->[$index];
				# Do not process if the entire entry isn't defined
				warn " ! Unable to List: Data disapeared midstream!\n" and next if not defined $list->[$index];

				# Create new data object with a new scope
				my $datum   = $data->_makeHash( $list->[$index] );

				# Push this entries related data
				my $odd  = $index % 2;
				my $even = not $odd;
				$datum->{''} = {
					'index' => $index,
					'count' => $index+1,
					'odd'   => $odd,
					'even'  => $even,
					'depth' => $p{'listDepth'},
				};

				my $newdata = $data->pushNew( $datum );
				
				# Create a copy of the entry for this list item
				my $copy = $entry;

				#$self->SUPER::compile( $newdata, \$copy, %p, listDepth => $p{'listDepth'} + 1 );

				# Generate any of the data required for sublists
				if($sublist and $p{'listDepth'} < 10) {
					#warn "Found sublist for $dataName > $sublist\n";
					$datum->{''}->{'sublist'} = $self->compileSubList( \$copy, $newdata, $sublist, %p );
				}
				
				# Generate entry with content and all sub-structures processed
				$self->SUPER::compile( $newdata, \$copy, %p, listDepth => $p{'listDepth'} + 1 );

				# Concaternate each of the new copies together
				$result .= $seperator if defined $seperator and $seperator ne '' and defined $result and $result ne '';
				$result .= $copy;
			}
		}
	} else {
		#warn "Ignoring List using variable ".$self->{'listName'}." ".($list ? "empty content" : "no data")."\n";
		if($noentry) {
			return $noentry;
		}
	}
	return '' if not $result;
	# Put all the entries back into the list section
	$self->setSection( \$section, $result );
	return $section;
}


=head2 I<$list>->compileSubList( $content, $data, $sublist )

  Modifies the content with the sublist tag replaces with the correctly proccessed data

=cut
sub compileSubList {
	my ($self, $content, $data, $sublist, %p) = @_;

	my $name   = $sublist->{'var'};
	my $depth  = $sublist->{'deep'} || 0;
	my $index  = $sublist->{'tagIndex'};
	my $result = '';
	
	# Because the data simply uses scope by pushing a new set of local variables onto
	# a stack each level/depth down, we can induce a deepRecursion here because it will
	# attempt to find sublists in data, even when the data has run out by using data
	# in older scopes as per the functionality of getDatum. HERE BE DRAGONS.
	
	my $object = $self->getClassParent( $depth );
	if(defined($object)) {
		$result = $object->compileListData( $data, $name, %p, listDepth => $p{'listDepth'} + 1 );
	}

	$self->setTagSection($content, $index, $result);

	return 1 if $result;
}


=head2 I<$list>->getEntryContent( $content )

  Gathers all the subtags and sorts them out into a content hash (returned)
  This content is used for all sublists as well as the current list processing.

=cut
sub getEntryContent {
	my ($self, $template) = @_;

	my $result = {};
	my ($start, $end);
	my $first;

	my $length = @{$self->allSubTags()};
	for(my $i = 0; $i < $length; $i++) {
		my ($name, $index, $data) = @{$self->allSubTags()->[$i]};
		$first = $index if not defined($first);
		if($name eq 'entry') {
			$start = $index if($name eq 'entry' and $data ne 'END');
			$end   = $index if($name eq 'entry' and $data eq 'END');
		} elsif($name eq 'sublist') {
			$result->{'sublist'} = $self->getOptions($data);
			$result->{'sublist'}->{'tagIndex'} = $index;
		} elsif($data ne 'END') {
			my $next = $i + 1 < $length ? $self->allSubTags()->[$i+1] : undef;
			$result->{$name} = $self->getAppendedSection( \$template, $self->allSubTags()->[$i], $next);
		}
	}

	if(not defined($start) or not defined($end)) {
		# This means use entire template content because entry wasn't specified
		$result->{'entry'} = $template;
		$template = '{{PH}}';
	} else {
		$result->{'entry'} = $self->getSection( \$template, $start, $end );
	}

	$result->{'section'} = $template;
	return $result;
}

=head1 AUTHOR

  Martin Owens - Copyright 2007, AGPL

=cut
1;
