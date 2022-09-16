package PDF::Builder::Outline;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

use Carp qw(croak);
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Outline - Manage PDF outlines (a.k.a. I<bookmarks>)

=head1 SYNOPSIS

    # Get/create the top-level outline tree
    my $outlines = $pdf->outline();

    # Add an entry
    my $item = $outlines->outline();
    $item->title('First Page');
    $item->destination($pdf->open_page(1)); # or dest(...)

=head1 METHODS

=over

=item $outline = PDF::Builder::Outline->new($api, $parent, $prev)

Returns a new outline object (called from $outlines->outline()).

=cut

sub new {
    my ($class, $api, $parent, $prev) = @_;
    my $self = $class->SUPER::new();

    $self->{'Parent'} = $parent if defined $parent;
    $self->{'Prev'}   = $prev   if defined $prev;
    $self->{' api'}   = $api;
    weaken $self->{' api'};
    weaken $self->{'Parent'} if defined $parent;
   #weaken $self->{'Prev'} if defined $prev;   # not in API2

    return $self;
}

=back

=head2 Examine the Outline Tree

=over

=item $boolean = $outline->has_children()

Return true if the current outline item has children (child items).

=cut

sub has_children {
    my $self = shift();

    # Opened by PDF::Builder
    return 1 if exists $self->{'First'};

    # Created by PDF::Builder
    return @{$self->{' children'}} > 0 if exists $self->{' children'};

    return;
}

=item $integer = $outline->count()

Return the number of descendants that are visible when the current outline item
is open (expanded).

=cut

sub count {
    my $self = shift();

    # Set count to the number of descendant items that will be visible when the
    # current item is open.
    my $count = 0;
    if ($self->has_children()) {
        $self->_load_children() unless exists $self->{' children'};
        $count += @{$self->{' children'}};
        foreach my $child (@{$self->{' children'}}) {
            next unless $child->has_children();
            next unless $child->is_open();
            $count += $child->count();
        }
    }

    if ($count) {
        $self->{'Count'} = PDFNum($self->is_open() ? $count : -$count);
    }

    return $count;
}
#sub count {  # older version
#    my $self = shift();
#
#    my $count = scalar @{$self->{' children'} || []};
#    $count += $_->count() for @{$self->{' children'}};
#    $self->{'Count'} = PDFNum($self->{' closed'}? -$count: $count) if $count > 0;
#    return $count;
#}

sub _load_children {
    my $self = shift();
    my $item = $self->{'First'};
    return unless $item;
    $item->realise();
    bless $item, __PACKAGE__;

    push @{$self->{' children'}}, $item;
    while ($item->next()) {
        $item = $item->next();
        $item->realise();
        bless $item, __PACKAGE__;
        push @{$self->{' children'}}, $item;
    }
    return $self;
}

=item $child = $outline->first()

Return the first child of the current outline level, if one exists.

=cut

sub first {
    my $self = shift();
    if (defined $self->{' children'} and defined $self->{' children'}->[0]) {
        $self->{'First'} = $self->{' children'}->[0];
    }
   #weaken $self->{'First'};   # not in API2
    return $self->{'First'};
}

=item $child = $outline->last()

Return the last child of the current outline level, if one exists.

=cut

sub last {
    my $self = shift();
    if (defined $self->{' children'} and defined $self->{' children'}->[-1]) {
        $self->{'Last'} = $self->{' children'}->[-1];
    }
   #weaken $self->{'Last'};   # not in API2
    return $self->{'Last'};
}

=item $parent = $outline->parent()

Return the parent of the current item, if not at the top level of the outline
tree.

=cut

sub parent {
    my $self = shift();
    $self->{'Parent'} = shift() if defined $_[0];
   #weaken $self->{'Parent'}; # not in API2
    return $self->{'Parent'};
}

=item $sibling = $outline->prev()

Return the previous item of the current level of the outline tree.

=cut

sub prev {
    my $self = shift();
    $self->{'Prev'} = shift() if defined $_[0];
   #weaken $self->{'Prev'};  # not in API2
    return $self->{'Prev'};
}

=item $sibling = $outline->next()

Return the next item of the current level of the outline tree.

=cut

sub next {
    my $self = shift();
    $self->{'Next'} = shift() if defined $_[0];
   #weaken $self->{'Next'};   # not in API2
    return $self->{'Next'};
}

=back

=head2 Modify the Outline Tree

=over 

=item $child_outline = $parent_outline->outline()

Returns a new sub-outline (nested outline) added at the end of the
current outline's children.

=cut

sub outline {
    my $self = shift();

    my $child = PDF::Builder::Outline->new($self->{' api'}, $self);
    $self->{' children'} //= [];
    # it's not clear whether self->{children} will change by prev() call,
    # so leave as done in PDF::API2
    $child->prev($self->{' children'}->[-1]) if @{ $self->{' children'} };
    $self->{' children'}->[-1]->next($child) if @{ $self->{' children'} };
    push @{$self->{' children'}}, $child;
    $self->{' api'}->{'pdf'}->new_obj($child) 
        unless $child->is_obj($self->{' api'}->{'pdf'});

    return $child;
}

=item $sibling = $outline->insert_after()

Add an outline item immediately following the current item.

=cut

sub insert_after {
    my $self = shift();

    my $sibling = PDF::Builder::Outline->new($self->{' api'}, $self->parent());
    $sibling->next($self->next());
    $self->next->prev($sibling) if $self->next();
    $self->next($sibling);
    $sibling->prev($self);
    unless ($sibling->is_obj($self->{' api'}->{'pdf'})) {
        $self->{' api'}->{'pdf'}->new_obj($sibling);
    }
    $self->parent->_reset_children();
    return $sibling;
}

=item $sibling = $outline->insert_before()

Add an outline item immediately preceding the current item.

=cut

sub insert_before {
    my $self = shift();

    my $sibling = PDF::Builder::Outline->new($self->{' api'}, $self->parent());
    $sibling->prev($self->prev());
    $self->prev->next($sibling) if $self->prev();
    $self->prev($sibling);
    $sibling->next($self);
    unless ($sibling->is_obj($self->{' api'}->{'pdf'})) {
        $self->{' api'}->{'pdf'}->new_obj($sibling);
    }
    $self->parent->_reset_children();
    return $sibling;
}

sub _reset_children {
    my $self = shift();
    my $item = $self->first();
    $self->{' children'} = [];
    return unless $item;

    push @{$self->{' children'}}, $item;
    while ($item->next()) {
        $item = $item->next();
        push @{$self->{' children'}}, $item;
    }
    return $self;
}

=item $outline->delete()

Remove the current outline item from the outline tree. If the item has any
children, they will effectively be deleted as well, since they will no longer 
be linked.

=cut

sub delete {
    my $self = shift();

    my $prev = $self->prev();
    my $next = $self->next();
    $prev->next($next) if defined $prev;
    $next->prev($prev) if defined $next;

    my $siblings = $self->parent->{' children'};
    @$siblings = grep { $_ ne $self } @$siblings;
    delete $self->parent->{' children'} unless $self->parent->has_children();

    return;
}

=item $boolean = $outline->is_open() # Get

=item $outline = $outline->is_open($boolean) # Set

Get/set whether the outline is expanded (open) or collapsed (closed).

=cut

sub is_open {
    my $self = shift();

    # Get
    unless (@_) {
        # Created by PDF::Builder
        return $self->{' closed'} ? 0 : 1 if exists $self->{' closed'};

        # Opened by PDF::Builder
        return $self->{'Count'}->val() > 0 if exists $self->{'Count'};

        # Default
        return 1;
    }

    # Set
    my $is_open = shift();
    $self->{' closed'} = (not $is_open);

    return $self;
}

=item $outline->open()

Set the status of the outline to open (i.e., expanded).

This is an B<alternate> method to using is_open(true).

=cut

# deprecated in API2
sub open {
    my $self = shift();
    delete $self->{' closed'};
    return $self;
}

=item $outline->closed()

Set the status of the outline to closed (i.e., collapsed).

This is an B<alternate> method to using is_open(false).

=cut

# deprecated in API2
sub closed {
    my $self = shift();
    $self->{' closed'} = 1;
    return $self;
}

=back

=head2 Set Outline Attributes

=over

=item $title = $outline->title() # Get

=item $outline = $outline->title($text) # Set

Get/set the title of the outline item.

=cut

sub title {
    my $self = shift();

    # Get
    unless (@_) {
        return unless $self->{'Title'};
        return $self->{'Title'}->val();
    }

    # Set
    my $text = shift();
    $self->{'Title'} = PDFString($text, 'o');
    return $self;
}

=item $outline->dest($page_object, %position)

=item $outline->dest($page_object)

Sets the destination page and optional position of the outline.

%position can be any of those listed in L<PDF::Builder::Docs/Page Fit Options>.

"xyz" is the B<default> fit setting, with position (left and top) and zoom
the same as the calling page's.

=item $outline->dest($name, %position)

=item $outline->dest($name)

Connect the Outline to a "Named Destination" defined elsewhere,
and optional positioning as described above.

=cut

sub dest {
    my ($self, $page, %position) = @_;
    delete $self->{'A'};

    if (ref($page)) {
        $self = $self->_fit($page, %position);
    } else {
        $self->{'Dest'} = PDFString($page, 'n');
    }

    return $self;
}

# process destination, including position setting, with default of xyz undef*3
 
sub _fit {
    my ($self, $destination, %position) = @_;
    # copy dashed names over to preferred non-dashed names
    if (defined $position{'-fit'} && !defined $position{'fit'}) { $position{'fit'} = delete($position{'-fit'}); }
    if (defined $position{'-fith'} && !defined $position{'fith'}) { $position{'fith'} = delete($position{'-fith'}); }
    if (defined $position{'-fitb'} && !defined $position{'fitb'}) { $position{'fitb'} = delete($position{'-fitb'}); }
    if (defined $position{'-fitbh'} && !defined $position{'fitbh'}) { $position{'fitbh'} = delete($position{'-fitbh'}); }
    if (defined $position{'-fitv'} && !defined $position{'fitv'}) { $position{'fitv'} = delete($position{'-fitv'}); }
    if (defined $position{'-fitbv'} && !defined $position{'fitbv'}) { $position{'fitbv'} = delete($position{'-fitbv'}); }
    if (defined $position{'-fitr'} && !defined $position{'fitr'}) { $position{'fitr'} = delete($position{'-fitr'}); }
    if (defined $position{'-xyz'} && !defined $position{'xyz'}) { $position{'xyz'} = delete($position{'-xyz'}); }

    if      (defined $position{'fit'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('Fit'));
    } elsif (defined $position{'fith'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitH'), PDFNum($position{'fith'}));
    } elsif (defined $position{'fitb'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitB'));
    } elsif (defined $position{'fitbh'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitBH'), PDFNum($position{'fitbh'}));
    } elsif (defined $position{'fitv'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitV'), PDFNum($position{'fitv'}));
    } elsif (defined $position{'fitbv'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitBV'), PDFNum($position{'fitbv'}));
    } elsif (defined $position{'fitr'}) {
        croak "Insufficient parameters to fitr => []) " unless scalar @{$position{'fitr'}} == 4;
        $self->{'Dest'} = PDFArray($destination, PDFName('FitR'), map {PDFNum($_)} @{$position{'fitr'}});
    } elsif (defined $position{'xyz'}) {
        croak "Insufficient parameters to xyz => []) " unless scalar @{$position{'xyz'}} == 3;
        $self->{'Dest'} = PDFArray($destination, PDFName('XYZ'), map {defined $_? PDFNum($_): PDFNull()} @{$position{'xyz'}});
    } else {
        # no "fit" option found. use default.
        $position{'xyz'} = [undef,undef,undef];
        $self->{'Dest'} = PDFArray($destination, PDFName('XYZ'), map {defined $_? PDFNum($_): PDFNull()} @{$position{'xyz'}});
    }

    return $self;
}

=item $outline = $outline->destination($destination, $location, @args)

Set the destination page and optional position of the outline.  C<$location> and
C<@args> are as defined in L<PDF::Builder::NamedDestination/"destination">.

C<$destination> can optionally be the name of a named destination defined
elsewhere.

This is an B<alternative method> for changes made in PDF::API2; it maintains
compatibility with the new PDF::API2 version.

=cut

sub _destination {
    require PDF::Builder::NamedDestination;
    return PDF::Builder::NamedDestination::_destination(@_);
}

sub destination {
    my ($self, $destination, $location, @args) = @_;

    # Remove an existing action dictionary
    delete $self->{'A'};

    if (ref($destination)) {
        # Page Destination
        $self->{'Dest'} = _destination($destination, $location, @args);
    }
    else {
        # Named Destination
        $self->{'Dest'} = PDFStr($destination);
    }

    return $self;
}

=back

=head2 Destination targets

=over

=item $outline->uri($url)

Defines the outline as launch-url with url C<$url>, typically a web page.

B<Alternate name:> C<url>

Either C<uri> or C<url> may be used; C<uri> is for compatibility with PDF::API2.

=cut

sub url { return uri(@_); }  # alternate name

sub uri {
    my ($self, $url) = @_;

    delete $self->{'Dest'};
    $self->{'A'}          = PDFDict();
    $self->{'A'}->{'S'}   = PDFName('URI');
    $self->{'A'}->{'URI'} = PDFString($url, 'u');

    return $self;
}

=item $outline->launch($file)

Defines the outline as launch-file with filepath C<$file>. This is typically
a local application or file.

B<Alternate name:> C<file>

Either C<launch> or C<file> may be used; C<launch> is for compatibility with PDF::API2.

=cut

sub file { return launch(@_); } # alternate name

sub launch {
    my ($self, $file) = @_;

    delete $self->{'Dest'};
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('Launch');
    $self->{'A'}->{'F'} = PDFString($file, 'f');

    return $self;
}

=item $outline->pdf($pdffile, $page_number, %position, %args)

=item $outline->pdf($pdffile, $page_number)

Defines the destination of the outline as a PDF-file with filepath 
C<$pdffile>, on page C<$pagenum> (default 0), and position C<%position> 
(same as dest()).

B<Alternate names:> C<pdf_file> and C<pdfile>

Either C<pdf> or C<pdf_file> (or the older C<pdfile>) may be used; C<pdf> is 
for compatibility with PDF::API2. B<Note> that PDF::API2 now uses a string name 
for the location, and an array of dimensions, etc., rather than the old hash
element name => dimensions (as still used here in PDF::Builder).

=cut

sub pdf_file { return pdf(@_); } # alternative method
sub pdfile   { return pdf(@_); } # alternative method (older)

sub pdf {
    my ($self, $file, $page_number, %position) = @_;

    delete $self->{'Dest'};
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoToR');
    $self->{'A'}->{'F'} = PDFString($file, 'f');
    $self->{'A'}->{'D'} = $self->_fit(PDFNum($page_number // 0), %position);
    
    return $self;
}

# internal routine
sub fix_outline {
    my ($self) = @_;

    $self->first();
    $self->last();
    $self->count();
    return;
}

#sub out_obj {
#    my ($self, @param) = @_;
#
#    $self->fix_outline();
#    return $self->SUPER::out_obj(@param);
#}

sub outobjdeep {
#   my ($self, @param) = @_;
#
#   $self->fix_outline();
#   foreach my $k (qw/ api apipdf apipage /) {
#       $self->{" $k"} = undef;
#       delete($self->{" $k"});
#   }
#   my @ret = $self->SUPER::outobjdeep(@param);
#   foreach my $k (qw/ First Parent Next Last Prev /) {
#       $self->{$k} = undef;
#       delete($self->{$k});
#   }
#   return @ret;
    my $self = shift();
    $self->fix_outline();
    return $self->SUPER::outobjdeep(@_);
}

=back

=cut

1;
