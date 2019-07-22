package Netscape::Bookmarks::Category;

=encoding utf8

=head1 NAME

Netscape::Bookmarks::Category	- manipulate, or create Netscape Bookmarks files

=head1 SYNOPSIS

  use Netscape::Bookmarks;

  #parse an existing file
  my $bookmarks = new Netscape::Bookmarks $bookmarks_file;

  #print a Netscape compatible file
  print $bookmarks->as_string;

=head1 DESCRIPTION

THIS IS AN ABANDONED MODULE. THERE IS NO SUPPORT. YOU CAN ADOPT IT
IF YOU LIKE: https://pause.perl.org/pause/query?ACTION=pause_04about#takeover

The Netscape bookmarks file has several basic components:

	title
	folders (henceforth called categories)
	links
	aliases
	separators

On disk, Netscape browsers store this information in HTML. In the browser,
it is displayed under the "Bookmarks" menu.  The data can be manipulated
through the browser interface.

This module allows one to manipulate the bookmarks file programmatically.  One
can parse an existing bookmarks file, manipulate the information, and write it
as a bookmarks file again.  Furthermore, one can skip the parsing step to create
a new bookmarks file and write it in the proper format to be used by a Netscape
browser.

The Bookmarks.pm module simply parses the bookmarks file passed to it as the
only argument to the constructor:

	my $bookmarks = new Netscape::Bookmarks $bookmarks_file;

The returned object is a Netscape::Bookmarks::Category object, since the bookmark file is
simply a collection of categories that contain any of the components listed
above.  The top level (i.e. root) category is treated specially and defines the
title of the bookmarks file.

=head1 METHODS

=over 4

=cut

use strict;

use base qw( Netscape::Bookmarks::AcceptVisitor Netscape::Bookmarks::Isa );
use subs qw();
use vars qw( $VERSION $ERROR $LAST_ID %IDS );

use constant START_LIST      => '<DL><p>';
use constant END_LIST        => '</DL><p>';
use constant START_LIST_ITEM => '<DT>';
use constant TAB             => '    ';
use constant FOLDED_TRUE     => 1;
use constant FOLDED_FALSE    => 0;
use constant TRUE            => 'true';

$VERSION = "2.304";

%IDS     = ();
$LAST_ID = -1;

=item Netscape::Bookmarks::Category-E<gt>new( \%hash )

The new method creates a Category.  It takes a hash reference
that specifies the properties of the category.  The valid keys
in that hash are

	folded			collapsed state of the category ( 1 or 0 )
	title
	add_date
	description

=cut

sub new
	{
	my $class  = shift;
	my $param  = shift;

	my $self = {};
	bless $self, $class;

	$self->{'folded'} = FOLDED_TRUE unless $param->{'folded'} == FOLDED_FALSE;
	$self->{'personal_toolbar_folder'} = TRUE if $param->{'personal_toolbar_folder'};

	unless( exists $IDS{$param->{'id'}} or $param->{'id'} =~ /\D/)
		{
		$param->{'id'} = ++$LAST_ID;
		$IDS{$LAST_ID}++;
		}

	if( defined $param->{'add_date'} and $param->{'add_date'} =~ /\D/  )
		{
		$param->{'add_date'} = 0;
		}

	$self->{'mozilla'}                 = $param->{'mozilla'};
	$self->{'title'}                   = $param->{'title'};
	$self->{'add_date'}                = $param->{'add_date'};
	$self->{'last_modified'}           = $param->{'last_modified'};
	$self->{'id'}                      = $param->{'id'};
	$self->{'description'}             = $param->{'description'};
	$self->{'thingys'}                 = [];

	$self;
	}

sub mozilla
	{
	my $self  = shift;
	my $value = shift;

	$self->{'mozilla'} = $value if defined $value;

	$self->{'mozilla'};
	}

=item $category-E<gt>add( $object )

The add() function adds an element to a category.  The element must be a Alias,
Link, Category, or Separator object.  Returns TRUE or FALSE.

=cut

sub add
	{
	my $self   = shift;
	my $thingy = shift;

	return unless
		ref $thingy eq 'Netscape::Bookmarks::Link' or
		ref $thingy eq 'Netscape::Bookmarks::Category' or
		ref $thingy eq 'Netscape::Bookmarks::Separator' or
		ref $thingy eq 'Netscape::Bookmarks::Alias';

	push @{ $self->{'thingys'} }, $thingy;
	}

=item $category-E<gt>remove_element( $object )

Removes the given object from the Category by calling the object's
remove() method.

Returns the number of objects removed from the Category.

=cut

sub remove_element
	{
	my $self   = shift;
	my $thingy = shift;

	my $old_count = $self->count;

	$self->{'thingys'} =
		[ grep { $_ ne $thingy and $_->remove } $self->elements ];

	return $old_count - $self->count;
	}

=item $category-E<gt>remove()

Performs any clean up necessary to remove this object from the
Bookmarks tree. Although this method does not recursively remove
objects which it contains, it probably should.

=cut

sub remove { 1; }

=item $category-E<gt>title( [ TITLE ] )

Returns title to the category. With a
defined argument TITLE, it replaces the current
title.

=cut

sub title
	{
	my $self = shift;

	if( defined $_[0] )
		{
		$self->{'title'} = shift;
		}

	$self->{'title'};
	}

=item $category-E<gt>id()

Returns the ID of the category. This is an arbitrary, unique number.

=cut

sub id
	{
	my $self = shift;

	$self->{'id'};
	}

=item $category-E<gt>description( [ DESCRIPTION ] )

Returns the description of the category.  With a
defined argument DESCRIPTION, it replaces the current
description.

=cut

sub description
	{
	my $self = shift;

	if( defined $_[0] )
		{
		$self->{'description'} = shift;
		}

	$self->{'description'};
	}

=item $category-E<gt>folded( $object )

Returns the folded state of the category (TRUE or FALSE).  If the category is
"folded", Netscape shows a collapsed folder for this category.

=cut

sub folded
	{
	my $self = shift;

	return $self->{'folded'} ? 1 : 0;
	}

=item $category-E<gt>add_date()

Returns the ADD_DATE attribute of the category.

=cut

sub add_date
	{
	my $self = shift;

	return $self->{'add_date'};
	}

=item $category-E<gt>last_modified()

Returns the LAST_MODIFIED attribute of the category.

=cut

sub last_modified
	{
	my $self = shift;

	return $self->{'last_modified'};
	}

=item $category-E<gt>personal_toolbar_folder()

Returns the PERSONAL_TOOLBAR_FOLDER attribute of the category.

=cut

sub personal_toolbar_folder
	{
	my $self = shift;

	return $self->{'personal_toolbar_folder'};
	}

=item $category-E<gt>elements()

In scalar context returns an array reference to the elements in
the category.  In list context returns a list of the elements in
the category.

=cut

sub elements
	{
	my $self = shift;

	if( wantarray ) { @{ $self->{'thingys'} } }
	else            {    $self->{'thingys'}   }
	}

=item $category-E<gt>count()

Returns a count of the number of objects in the Category.

=cut

sub count { scalar @{ $_[0]->{'thingys'} } }

=item $category-E<gt>categories()

Returns a list of the Category objects in the category.

=cut

sub categories
	{
	my $self = shift;

	my @list = grep ref $_ eq 'Netscape::Bookmarks::Category',
		$self->elements;

	return @list;
	}

=item $category-E<gt>links()

Returns a list of the Link objects in the category.

=cut

sub links
	{
	my $self = shift;

	my @list = grep ref $_ eq 'Netscape::Bookmarks::Link',
		 $self->elements;

	return @list;
	}

=item $category-E<gt>as_headline()

Returns an HTML string representation of the category, but not
the elements of the category.

=cut

sub as_headline
	{
	my $self = shift;

	my $folded        = $self->folded ? "FOLDED" : "";
	my $title         = $self->title;
	my $desc          = $self->description;
	my $add_date      = $self->add_date;
	my $last_modified = $self->last_modified;
	my $id            = $self->id;
	my $personal_toolbar_folder = $self->personal_toolbar_folder;

	$desc = defined $desc && $desc ne '' ? "\n<DD>$desc" : "\n";

	$folded   = $folded ? qq|FOLDED| : '';
	$add_date = $add_date ? qq|ADD_DATE="$add_date"| : '';
	$last_modified = $last_modified ? qq|LAST_MODIFIED="$last_modified"| : '';
	$personal_toolbar_folder = $personal_toolbar_folder
		? qq|PERSONAL_TOOLBAR_FOLDER="true"| : '';
	$id = $id =~ m/\D/ ? qq|ID="$id"| : '';

	my $attr = join " ", grep $_, ($folded, $add_date, $last_modified,
		$personal_toolbar_folder, $id );

	$attr = " " . $attr if $attr;
	$attr =~ s/\s+$//; # XXX: ugh

	return qq|<H3$attr>$title</H3>$desc|
	}

=item $category-E<gt>recurse( CODE, [ LEVEL ] )

This method performs a depth-first traversal of the Bookmarks
tree and executes the CODE reference at each node.

The CODE reference receives two arguments - the object on which
it should operate and its level in the tree.

=cut

sub recurse
	{
	my $self  = shift;
	my $sub   = shift;
	my $level = shift || 0;

	unless( ref $sub eq 'CODE' )
		{
		warn "Argument to recurse is not a code reference";
		return;
		}

	$sub->( $self, $level );

	++$level;
	foreach my $element ( $self->elements )
		{
		if( $element->isa( __PACKAGE__ ) )
			{
			$element->recurse( $sub, $level );
			}
		else
			{
			$sub->( $element, $level );
			}
		}
	--$level;

	}

=item $category-E<gt>introduce( VISITOR, [ LEVEL ] )

This method performs a depth-first traversal of the Bookmarks
tree and introduces the visitor object to each object.

This is different from recurse() which only calls its
CODEREF on nodes.  The VISITOR operates on nodes and
vertices.  The VISITOR must have a visit() method
recognizable by can().  This method does not trap
errors in the VISITOR.

See L<Netscape::Bookmarks::AcceptVisitor> for details on
Visitors.

=cut

sub introduce
	{
	my $self      = shift;
	my $visitor   = shift;
	my $level     = shift || 0;

	unless( $visitor->can('visit') )
		{
		warn "Argument to introduce cannot visit()!";
		return;
		}

	$self->visitor( $visitor );

	++$level;
	foreach my $element ( $self->elements )
		{

		if( $element->isa( __PACKAGE__ ) )
			{
			$element->introduce( $visitor, $level );
			}
		else
			{
			$element->visitor( $visitor );
			}

		}
	--$level;

	}

=item $category-E<gt>sort_elements( [ CODE ] )

Sorts the elements in the category using the provided CODE
reference.  If you do not specify a CODE reference, the
elements are sorted by title (with the side effect of
removing Separators from the Category).

This function does not recurse, although you can use
the recurse() method to do that.

Since the built-in sort() uses the package variables
C<$a> and C<$b>, your sort subroutine has to make sure
that it is accessing the right C<$a> and C<$b>, which
are the ones in the package C<Netscape::Bookmarks::Category>.
You can start your CODE reference with a package
declaration to ensure the right thing happens:

	my $sub = sub {
		package Netscape::Bookmarks::Category;

		$b->title cmp $a->title;
		};

	$category->sort_elements( $sub );

If you know a better way to do this, please let me know. :)

=cut

sub sort_elements
	{
	my $self = shift;
	my $sub  = shift;

	if( defined $sub and not ref $sub eq 'CODE' )
		{
		warn "Second argument to sort_elements is not a CODE reference.";
		return;
		}
	elsif( not defined $sub )
		{
		$sub = sub { $a->title cmp $b->title };
		}

	local *my_sorter = $sub;

	$self->{'thingys'} = [ sort my_sorter
		grep { not $_->isa( 'Netscape::Bookmarks::Separator' ) }
			@{ $self->{'thingys'} } ];
	}

=item $category-E<gt>as_string()

Returns an HTML string representation of the category as the
top level category, along with all of the elements of the
category and the Categories that it contains, recursively.

=cut

sub as_string
	{
	my $self   = shift;

	my $title = $self->title;
	my $desc  = $self->description || "\n";

	my $meta = $self->mozilla ?
		qq|\n<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">| :
		'';

	my $str = <<"HTML";
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
It will be read and overwritten.
Do Not Edit! -->$meta
<TITLE>$title</TITLE>
<H1>$title</H1>

HTML

	$str .= "<DD>" . $desc unless( $self->mozilla and $desc eq "\n" );

	$str .= START_LIST . "\n";

	foreach my $element ( $self->elements )
		{
		$str .= $self->_as_string( $element, 1 );
		}

	$str .= END_LIST . "\n";

	return $str;
	}

# _as_string does most of the work that as_string would normally
# do.
sub _as_string
	{
	my $self   = shift;
	my $obj    = shift;
	my $level  = shift;

	my $str;
	if( ref $obj eq 'Netscape::Bookmarks::Category' )
		{
		$str .= TAB x ($level) . START_LIST_ITEM . $obj->as_headline;

		unless( $self->mozilla )
			{
			$str .= TAB x ($level-1) . START_LIST . "\n";
			}
		else
			{
			$str .= TAB x ($level) . START_LIST . "\n";
			}

		++$level;
		foreach my $ref ( $obj->elements )
			{
			$str .= $self->_as_string( $ref, $level );
			}
		--$level;

		$str .= TAB x ($level) . END_LIST . "\n";
		}
	elsif( ref $obj eq 'Netscape::Bookmarks::Link' or
		   ref $obj eq 'Netscape::Bookmarks::Alias' )
		{
		$str .= TAB x ($level) . START_LIST_ITEM
			. $obj->as_string . "\n"
		}
	elsif( ref $obj eq 'Netscape::Bookmarks::Separator' )
		{
		$str .= TAB x ($level) . $obj->as_string . "\n"
		}

	return $str;

	}

=item $obj->write_file( FILENAME )

UNIMPLEMENTED!

=cut

sub write_file
	{
	my $self     = shift;
	my $filename = shift;

	return;
	}

"if you want to beleive everything you read, so be it.";

__END__

=back

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<Netscape::Bookmarks>

=cut
