package Template::Direct::Base;

use strict;
use warnings;

=head1 NAME

Template::Direct::Base - Basic class for content sections

=head1 DESCRIPTION

  Provide the low level functions applicable to all content sections

=head1 METHODS

=cut

use Template::Direct::Conditional;
use Template::Direct::List;
use Template::Direct::SubPage;
use Template::Direct::Maths;
use Carp;

=head2 I<$class>->new( $data )

  Create a new instance object.

=cut
sub new {
    my ($class, %p) = @_;
	my $self = bless { 'subtagindex' => {}, %p }, $class;
	return $self;
}

=head2 I<$construct>->singleTag( )

  Return true if this construct will be a single tag.
  i.e [tag/]

=cut
sub singleTag { 0 }

=head2 I<$construct>->subTags( )

  Should return a list of valid child tags.

=cut
sub subTags { die "SubTags needs to be created in the parent class of: ".ref($_[0])."\n" }

=head2 I<$construct>->hasTag( $name )

  Return true if this construct has a named tag.

=cut
sub hasTag {
	my ($self, $tagName) = @_;
	return defined($self->subTags()->{$tagName})
}

=head2 I<$construct>->hasSubTag( $name )

  Return true if this construct has a named sub tag.

=cut
sub hasSubTag {
	my ($self, $name) = @_;
	return defined($self->{'subtagindex'}->{$name});
}

=head2 I<$construct>->allSubTags( )

  Return an ARRAY ref of sub tag objects.

=cut
sub allSubTags { return $_[0]->{'subtags'} || [] }

=head2 I<$construct>->addSubTag( $name, $index, $data )

  Used internally to add a sub tag element to this construct.

=cut
sub addSubTag {
	my ($self, $name, $index, $data) = @_;
	$self->{'subtags'} = [] if not defined($self->{'subtags'});
	push @{$self->{'subtags'}}, [ $name, $index, $data ];
	$self->{'subtagindex'}->{$name} = $index;
}

=head2 I<$construct>->addEndSubTag( $name, $index )

  Complete a sub tag by closing it, used internally.

=cut
sub addEndSubTag {
	my ($self, $name, $index) = @_;
	push @{$self->{'subtags'}}, [ $name, $index, 'END' ];
}

=head2 I<$construct>->endTag( )

  The tag id for the end tag of this construct.

=cut
sub endTag { $_[0]->{'endTag'}; }

=head2 I<$construct>->startTag( )

  The tag id for the start tag of this construct.

=cut
sub startTag { $_[0]->{'startTag'} }

=head2 I<$construct>->setEndTag( $index )

  Set the id of the end tag of this construct.

=cut
sub setEndTag {
	my ($self, $index) = @_;
	$self->{'endTag'} = $index;
}

=head2 I<$construct>->addChild( $object )

  Used internally to add a child construct to this one.

=cut
sub addChild {
	my ($self, $object) = @_;
	$self->{'children'} = [] if not defined($self->{'children'});
	push @{$self->{'children'}}, $object;
}

=head2 I<$construct>->setParent( $object )

  Set the parent object of this construct to $object.

=cut
sub setParent {
	my ($self, $object) = @_;
	$self->{'parent'} = $object;
	$self->{'depth'} = $object->depth() + 1;
}

=head2 I<$construct>->setClassParent( $object )

  Set the last parent which had the same class as this construct.

=cut
sub setClassParent {
	my ($self, $object) = @_;
	$self->{'classParent'} = $object;
	$self->{'classDepth'} = $object->depth() + 1;
}

=head2 I<$construct>->children( )

  Return an ARRAY ref of child constructs.

=cut
sub children    { shift->{'children'}    || [] }

=head2 I<$construct>->parent( )

  Return the parent construct (if available)

=cut
sub parent      { shift->{'parent'}      || undef }

=head2 I<$construct>->depth( )

  Return the depth number for this tag.

=cut
sub depth       { shift->{'depth'}       || 0 }

=head2 I<$construct>->classParent( )

  Return the next parent with the same class as this one.

=cut
sub classParent { shift->{'classParent'} || undef }

=head2 I<$construct>->classDepth( )

  Return the depth number for this tag counting only tags
  of the same class as this one.

=cut
sub classDepth  { shift->{'classDepth'}  || 0 }

=head2 I<$construct>->getParent( $depth )

  Get a parent at a certain depth.

=cut
sub getParent {
	my ($self, $depth) = @_;
	$depth = 0 if not $depth;
	if($depth == 0) {
		return $self;
	}
	return $self->parent($depth-1);
}

=head2 I<$construct>->getClassParent( $depth )

  Get the class parent of a certin depth.

=cut
sub getClassParent {
	my ($self, $depth) = @_;
	$depth = 0 if not $depth;
	if($depth == 0) {
		return $self;
	}
	return $self->classParent($depth-1);
}

=head2 I<$construct>->compile( $data, $content, %p )

  Used internally to cascade the compilation to all children
  and replace and variables with $data as required.

=cut
sub compile {
	my ($self, $data, $content, %p) = @_;
	$self->compileChildren( $data, $content, %p );
	$self->replaceData( $content, $data );
}

=head2 I<$construct>->compileChildren( $data, $content, %p )

  Used internally, loop through all children and compile them
  with the same data and content.

=cut
sub compileChildren {
	my ($self, $data, $content, %p) = @_;
	foreach my $child (@{$self->children()}) {
		$child->compile( $data, $content, %p );
	}
}

=head2 I<$object>->getOptions( $line )

  Returns a hash ref of name vale pairs and described as a string in line.

  The line: "var='xyz' depth=0" becomes { var => 'xyz', depth => '0' }

=cut
sub getOptions {
	my ($self, $opt) = @_;
	my $results = {};

	while($opt =~ s/(\w+)=["']([^"']*)(?<!\\)["']//) {
		$results->{$1} = $2;
	}

	foreach my $o (split(/(?<!\\)\s+/, $opt)) {
		if($o =~ /(\w+)=(.*)?/) {
			$results->{$1} = $2;
		} else {
			$results->{$o} = 1;
		}
	}

	return $results;
}

=head2 I<$object>->getSection( $content, $start, $end )

  Returns a section of a content between two tag indexes.
  Having two sections with the same tag indexes is not valid
  It's expected that code that deals with listing splits up
  it's calls to this method as a matter of structure.

=cut
sub getSection {
	my ($self, $content, $start, $end) = @_;
	my $result = '';
	if($$content =~ s/\{\{TAG$start\}\}([\w\W]*?)\{\{TAG$end\}\}/{{PH}}/) {
		$result = $1;
	}
	return $result;
}

=head2 I<$construct>->getLocation( $content, $tagIndex )

  Replaces a tag location with a temporty pointer.

=cut
sub getLocation {
	my ($self, $content, $tagindex) = @_;
	$$content =~ s/\{\{TAG$tagindex\}\}/{{PH}}/;
	return 1;
}

=head2 I<$construct>->getFullSection( $content )

  Returns getSection of the current objects start and end tags

=cut
sub getFullSection {
	my ($self, $content) = @_;
	return $self->getSection($content, $self->startTag(), $self->endTag());
}

=head2 I<$construct>->setSection( $content, $result )

  Sets the section back into the content (see getSection)

=cut
sub setSection {
    my ($self, $content, $result) = @_;
	if(defined $result) {
	    $$content =~ s/\{\{PH\}\}/$result/;
	} else {
		$$content =~ s/\{\{PH\}\}//;
	}
}

=head2 I<$construct>->setTagSection( $content, $tagIndex, $with )

  Sets the section back into the content tag directly

=cut
sub setTagSection {
    my ($self, $content, $index, $result) = @_;
    $$content =~ s/\{\{TAG$index\}\}/$result/;
}

=head2 I<$construct>->getAppendedSection( $content, $startEntry, $endEntry )

  Returns the content between start and end tags, removing the start tag but
  only removing the end tag if it's an end tag for the start tag.

=cut
sub getAppendedSection {
	my ($self, $content, $start, $end) = @_;

	my $result      = '';
	my $replaceWith = '';
	my $startIndex  = $start->[1];
	my $endIndex    = defined($end) ? $end->[1] : 'FAKEEND';

	# The start tag must be the same as the end tag and the
	# end tag must BE an offical END tag.
	if(defined($end) and ($start->[0] ne $end->[0] or $end->[2] ne 'END')) {
		# The end tag isn't related so we just put it back.
		# It's used as a marker for where the current start
		# tag ends rather than a real end tag, although I'd
		# like for people to use end tags properly and I
		# figure html gurus will as a matter of habbit.
		$replaceWith = '{{TAG'.$end->[1].'}}';
	} elsif(not defined($end)) {
		# Should also deal with tags that reach to the end of the scope.
		$$content .= '{{TAGFAKEEND}}';
	}

	if($$content =~ s/\{\{TAG$startIndex\}\}([\w\W]*?)\{\{TAG$endIndex\}\}/$replaceWith/) {
        $result = $1;
    }

	return $result;
}

=head2 I<$construct>->replaceData( \$content, $data )

 Replace all instances in content with required data

=cut
sub replaceData
{
    my ($self, $content, $data) = @_;
	# The extra 1 in getDatum forces a scalar string (no undefs or structs)
    $$content =~ s/(?<!\\)\$([\w\-_]+)/ $data->getDatum($1, forceString => 1) /eg;
    $$content =~ s/(?<!\\)\$\{([\w\-_]+)\}/ $data->getDatum($1, forceString => 1) /eg;
    return $content;
}


=head2 I<$construct>->cleanContent( \$content )

 Removes any remaining content syntax from content

=cut
sub cleanContent {
	my ($self, $content) = @_;
	# We could remove spare structures here:
	#$$content =~ s/(?<!\\)\[.+\]//g;
	# Remove variables,remove stroked variables
	$$content =~ s/(?<!\\)\$[\w\-_]+//g;
	$$content =~ s/(?<!\\)\$\{[\w\-_]+?\}//g;
	# Unescape brackets and dollar signs
	$$content =~ s/\\([\[\]\$])/$1/g;
	return $content;
}

=head1 AUTHOR

  Martin Owens - Copyright 2007, AGPL

=cut
1;
