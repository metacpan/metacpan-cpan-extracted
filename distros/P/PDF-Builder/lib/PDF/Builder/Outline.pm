package PDF::Builder::Outline;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.017'; # VERSION
my $LAST_UPDATE = '3.016'; # manually update whenever code is changed

use Carp qw(croak);
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Outline - Manage PDF outlines (a.k.a. I<bookmarks>)

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

    return $self;
}

# unused?
sub parent {
    my $self = shift();
    $self->{'Parent'} = shift() if defined $_[0];
    return $self->{'Parent'};
}

# internal routine
sub prev {
    my $self = shift();
    $self->{'Prev'} = shift() if defined $_[0];
    return $self->{'Prev'};
}

# internal routine
sub next {
    my $self = shift();
    $self->{'Next'} = shift() if defined $_[0];
    return $self->{'Next'};
}

# internal routine
sub first {
    my $self = shift();

    $self->{'First'} = $self->{' children'}->[0] 
        if defined $self->{' children'} and defined $self->{' children'}->[0];
    return $self->{'First'};
}

# internal routine
sub last {
    my $self = shift();

    $self->{'Last'} = $self->{' children'}->[-1] 
        if defined $self->{' children'} and defined $self->{' children'}->[-1];
    return $self->{'Last'};
}

# internal routine
sub count {
    my $self = shift();

    my $count = scalar @{$self->{' children'} || []};
    $count += $_->count() for @{$self->{' children'}};
    $self->{'Count'} = PDFNum($self->{' closed'}? -$count: $count) if $count > 0;
    return $count;
}

# internal routine
sub fix_outline {
    my ($self) = @_;

    $self->first();
    $self->last();
    $self->count();
    return;
}

=item $outline->title($text)

Set the title of the outline.

=cut

sub title {
    my ($self, $text) = @_;
    $self->{'Title'} = PDFString($text, 'o');
    return $self;
}

=item $outline->closed()

Set the status of the outline to closed (i.e., collapsed).

=cut

sub closed {
    my $self = shift();
    $self->{' closed'} = 1;
    return $self;
}

=item $outline->open()

Set the status of the outline to open (i.e., expanded).

=cut

sub open {
    my $self = shift();
    delete $self->{' closed'};
    return $self;
}

=item $child_outline = $parent_outline->outline()

Returns a new sub-outline (nested outline).

=cut

sub outline {
    my $self = shift();

    my $child = PDF::Builder::Outline->new($self->{' api'}, $self);
    if (defined $self->{' children'}) {
        $child->prev($self->{' children'}->[-1]);
        $self->{' children'}->[-1]->next($child);
    }
    push @{$self->{' children'}}, $child;
    $self->{' api'}->{'pdf'}->new_obj($child) 
        unless $child->is_obj($self->{' api'}->{'pdf'});

    return $child;
}

=item $outline->dest($page_object, %position)

=item $outline->dest($page_object)

Sets the destination page and optional position of the outline.

%position can be any of the following:

=over

=item -fit => 1

Display the page designated by C<$page>, with its contents magnified just enough
to fit the entire page within the window both horizontally and vertically. If 
the required horizontal and vertical magnification factors are different, use 
the smaller of the two, centering the page within the window in the other 
dimension.

=item -fith => $top

Display the page designated by C<$page>, with the vertical coordinate C<$top> 
positioned at the top edge of the window and the contents of the page magnified 
just enough to fit the entire width of the page within the window.

=item -fitv => $left

Display the page designated by C<$page>, with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page magnified
just enough to fit the entire height of the page within the window.

=item -fitr => [$left, $bottom, $right, $top]

Display the page designated by C<$page>, with its contents magnified just enough
to fit the rectangle specified by the coordinates C<$left>, C<$bottom>, 
C<$right>, and C<$top> entirely within the window both horizontally and 
vertically. If the required horizontal and vertical magnification factors are 
different, use the smaller of the two, centering the rectangle within the window
in the other dimension.

=item -fitb => 1

Display the page designated by C<$page>, with its contents magnified just
enough to fit its bounding box entirely within the window both horizontally and
vertically. If the required horizontal and vertical magnification factors are
different, use the smaller of the two, centering the bounding box within the
window in the other dimension.

=item -fitbh => $top

Display the page designated by C<$page>, with the vertical coordinate C<$top>
positioned at the top edge of the window and the contents of the page magnified
just enough to fit the entire width of its bounding box within the window.

=item -fitbv => $left

Display the page designated by C<$page>, with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page
magnified just enough to fit the entire height of its bounding box within the
window.

=item -xyz => [$left, $top, $zoom]

Display the page designated by C<$page>, with the coordinates C<[$left, $top]> 
positioned at the top-left corner of the window and the contents of the page 
magnified by the factor C<$zoom>. A zero (0) value for any of the parameters 
C<$left>, C<$top>, or C<$zoom> specifies that the current value of that 
parameter is to be retained unchanged.

This is the B<default> fit setting, with position (left and top) and zoom
the same as the calling page's.

=back

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

=item $outline->url($url)

Defines the outline as launch-url with url C<$url>.

=cut

sub url {
    my ($self, $url) = @_;

    delete $self->{'Dest'};
    $self->{'A'}          = PDFDict();
    $self->{'A'}->{'S'}   = PDFName('URI');
    $self->{'A'}->{'URI'} = PDFString($url, 'u');

    return $self;
}

=item $outline->file($file)

Defines the outline as launch-file with filepath C<$file>.

=cut

sub file {
    my ($self, $file) = @_;

    delete $self->{'Dest'};
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('Launch');
    $self->{'A'}->{'F'} = PDFString($file, 'f');

    return $self;
}

=item $outline->pdf_file($pdffile, $page_number, %position)

=item $outline->pdf_file($pdffile, $page_number)

Defines the destination of the outline as a PDF-file with filepath 
C<$pdffile>, on page C<$pagenum> (default 0), and position C<%position> 
(same as dest()).

The old name, I<pdfile>, is still available but is B<deprecated> and will be
removed at some time in the future.

=cut

# to be removed no earlier than October, 2020
sub pdfile {
    my ($self, $file, $page_number, %position) = @_;
    warn "use pdf_file() method instead of pdfile()";
    return $self->pdf_file($file, $page_number, %position);
}

sub pdf_file {
    my ($self, $file, $page_number, %position) = @_;

    delete $self->{'Dest'};
    $self->{'A'}        = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoToR');
    $self->{'A'}->{'F'} = PDFString($file, 'f');
    $self->{'A'}->{'D'} = $self->_fit(PDFNum($page_number // 0), %position);
    
    return $self;
}

=back

=cut

# process destination, including position setting, with default of -xyz undef*3
sub _fit {
    my ($self, $destination, %position) = @_;

    if      (defined $position{'-fit'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('Fit'));
    } elsif (defined $position{'-fith'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitH'), PDFNum($position{'-fith'}));
    } elsif (defined $position{'-fitb'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitB'));
    } elsif (defined $position{'-fitbh'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitBH'), PDFNum($position{'-fitbh'}));
    } elsif (defined $position{'-fitv'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitV'), PDFNum($position{'-fitv'}));
    } elsif (defined $position{'-fitbv'}) {
        $self->{'Dest'} = PDFArray($destination, PDFName('FitBV'), PDFNum($position{'-fitbv'}));
    } elsif (defined $position{'-fitr'}) {
        croak "Insufficient parameters to -fitr => []) " unless scalar @{$position{'-fitr'}} == 4;
        $self->{'Dest'} = PDFArray($destination, PDFName('FitR'), map {PDFNum($_)} @{$position{'-fitr'}});
    } elsif (defined $position{'-xyz'}) {
        croak "Insufficient parameters to -xyz => []) " unless scalar @{$position{'-xyz'}} == 3;
        $self->{'Dest'} = PDFArray($destination, PDFName('XYZ'), map {defined $_? PDFNum($_): PDFNull()} @{$position{'-xyz'}});
    } else {
        # no "fit" option found. use default.
        $position{'-xyz'} = [undef,undef,undef];
        $self->{'Dest'} = PDFArray($destination, PDFName('XYZ'), map {defined $_? PDFNum($_): PDFNull()} @{$position{'-xyz'}});
    }

    return $self;
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

1;
