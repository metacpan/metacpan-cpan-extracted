package PDF::Builder::Outline;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.012'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Outline - Manage PDF outlines (a.k.a. I<bookmarks>)

=head1 METHODS

=over

=item $otl = PDF::Builder::Outline->new($api, $parent, $prev)

Returns a new outline object (called from $otls->outline()).

=cut

sub new {
    my ($class, $api, $parent, $prev) = @_;

    my $self = $class->SUPER::new();
    $self->{' apipdf'} = $api->{'pdf'};
    $self->{' api'} = $api;
    weaken $self->{' apipdf'};
    weaken $self->{' api'};
    $self->{'Parent'} = $parent if defined $parent;
    $self->{'Prev'} = $prev if defined $prev;
    return $self;
}

# unused?
sub parent {
    my $self = shift;

    if (defined $_[0]) {
        $self->{'Parent'} = shift;
    }
    return $self->{'Parent'};
}

# internal routine
sub prev {
    my $self = shift;

    if (defined $_[0]) {
        $self->{'Prev'} = shift;
    }
    return $self->{'Prev'};
}

# internal routine
sub next {
    my $self = shift;

    if (defined $_[0]) {
        $self->{'Next'} = shift;
    }
    return $self->{'Next'};
}

# internal routine
sub first {
    my $self = shift;

    $self->{'First'} = $self->{' childs'}->[0] 
         if defined $self->{' childs'} && defined $self->{' childs'}->[0];
    return $self->{'First'};
}

# internal routine
sub last {
    my $self = shift;

    $self->{'Last'} = $self->{' childs'}->[-1] 
         if defined $self->{' childs'} && defined $self->{' childs'}->[-1];
    return $self->{'Last'};
}

# internal routine
sub count {
    my $self = shift;

    my $cnt = scalar @{$self->{' childs'} || []};
    map { $cnt += $_->count();} @{$self->{' childs'}};
    $self->{'Count'} = PDFNum($self->{' closed'}? -$cnt: $cnt) if $cnt > 0;
    return $cnt;
}

# internal routine
sub fix_outline {
    my ($self) = @_;

    $self->first();
    $self->last();
    $self->count();
    return;
}

=item $otl->title($text)

Set the title of the outline.

=cut

sub title {
    my ($self, $txt) = @_;

    $self->{'Title'} = PDFStr($txt);
    return $self;
}

=item $otl->closed()

Set the status of the outline to closed.

=cut

sub closed {
    my $self = shift;

    $self->{' closed'} = 1;
    return $self;
}

=item $otl->open()

Set the status of the outline to open.

=cut

sub open {
    my $self = shift;

    delete $self->{' closed'};
    return $self;
}

=item $sotl=$otl->outline()

Returns a new sub-outline.

=cut

sub outline {
    my $self = shift;

    my $obj = PDF::Builder::Outline->new($self->{' api'}, $self);
    if (defined $self->{' childs'}) {
        $obj->prev($self->{' childs'}->[-1]);
        $self->{' childs'}->[-1]->next($obj);
    }
    push(@{$self->{' childs'}}, $obj);
    $self->{' api'}->{'pdf'}->new_obj($obj) 
        if !$obj->is_obj($self->{' api'}->{'pdf'});
    return $obj;
}

=item $otl->dest($pageobj, %opts)

=item $otl->dest($pageobj)

Sets the destination page of the outline.

  B<Example:> $otl->dest($page, -fit => 1)

Display the page designated by C<$page>, with its contents magnified just enough
to fit the entire page within the window both horizontally and vertically. If 
the required horizontal and vertical magnification factors are different, use 
the smaller of the two, centering the page within the window in the other 
dimension.

=item $otl->dest($page, -fith => $top)

Display the page designated by C<$page>, with the vertical coordinate C<$top> 
positioned at the top edge of the window and the contents of the page magnified 
just enough to fit the entire width of the page within the window.

=item $otl->dest($page, -fitv => $left)

Display the page designated by C<$page>, with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page magnified
just enough to fit the entire height of the page within the window.

=item $otl->dest($page, -fitr => [$left, $bottom, $right, $top])

Display the page designated by C<$page>, with its contents magnified just enough
to fit the rectangle specified by the coordinates C<$left>, C<$bottom>, 
C<$right>, and C<$top> entirely within the window both horizontally and 
vertically. If the required horizontal and vertical magnification factors are 
different, use the smaller of the two, centering the rectangle within the window
in the other dimension.

=item $otl->dest($page, -fitb => 1)

Display the page designated by C<$page>, with its contents magnified just
enough to fit its bounding box entirely within the window both horizontally and
vertically. If the required horizontal and vertical magnification factors are
different, use the smaller of the two, centering the bounding box within the
window in the other dimension.

=item $otl->dest($page, -fitbh => $top)

Display the page designated by C<$page>, with the vertical coordinate C<$top>
positioned at the top edge of the window and the contents of the page magnified
just enough to fit the entire width of its bounding box within the window.

=item $otl->dest($page, -fitbv => $left)

Display the page designated by C<$page>, with the horizontal coordinate C<$left>
positioned at the left edge of the window and the contents of the page
magnified just enough to fit the entire height of its bounding box within the
window.

=item $otl->dest($page, -xyz => [$left, $top, $zoom])

Display the page designated by C<$page>, with the coordinates C<[$left, $top]> 
positioned at the top-left corner of the window and the contents of the page 
magnified by the factor C<$zoom>. A zero (0) value for any of the parameters 
C<$left>, C<$top>, or C<$zoom> specifies that the current value of that 
parameter is to be retained unchanged.

=item $otl->dest($name)

(PDF 1.2) Connect the Outline to a "Named Destination" defined elsewhere.

=cut

sub dest {
    my ($self, $page, %opts) = @_;

    if (ref $page) {
        $opts{'-xyz'} = [undef,undef,undef] if scalar(keys %opts) < 1;

        if      (defined $opts{'-fit'}) {
            $self->{'Dest'} = PDFArray($page, PDFName('Fit'));
        } elsif (defined $opts{'-fith'}) {
            $self->{'Dest'} = PDFArray($page, PDFName('FitH'), PDFNum($opts{'-fith'}));
        } elsif (defined $opts{'-fitb'}) {
            $self->{'Dest'} = PDFArray($page, PDFName('FitB'));
        } elsif (defined $opts{'-fitbh'}) {
            $self->{'Dest'} = PDFArray($page, PDFName('FitBH'), PDFNum($opts{'-fitbh'}));
        } elsif (defined $opts{'-fitv'}) {
            $self->{'Dest'} = PDFArray($page, PDFName('FitV'), PDFNum($opts{'-fitv'}));
        } elsif (defined $opts{'-fitbv'}) {
            $self->{'Dest'} = PDFArray($page, PDFName('FitBV'), PDFNum($opts{'-fitbv'}));
        } elsif (defined $opts{'-fitr'}) {
            die "Insufficient parameters to ->dest(page, -fitr => []) " unless scalar @{$opts{'-fitr'}} == 4;
            $self->{'Dest'} = PDFArray($page, PDFName('FitR'), map {PDFNum($_)} @{$opts{'-fitr'}});
        } elsif (defined $opts{'-xyz'}) {
            die "Insufficient parameters to ->dest(page, -xyz => []) " unless scalar @{$opts{'-xyz'}} == 3;
            $self->{'Dest'} = PDFArray($page, PDFName('XYZ'), map {defined $_? PDFNum($_): PDFNull()} @{$opts{'-xyz'}});
        }
    } else {
        $self->{'Dest'} = PDFStr($page);
    }
    return $self;
}

=item $otl->url($url, %opts)

=item $otl->url($url)

Defines the outline as launch-url with url C<$url>.

=cut

sub url {
    my ($self, $url, %opts) = @_;

    delete $self->{'Dest'};
    $self->{'A'} = PDFDict();
    $self->{'A'}->{'S'} = PDFName('URI');
    $self->{'A'}->{'URI'} = PDFStr($url);
    return $self;
}

=item $otl->file($file, %opts)

=item $otl->file($file)

Defines the outline as launch-file with filepath C<$file>.

=cut

sub file {
    my ($self, $file, %opts) = @_;

    delete $self->{'Dest'};
    $self->{'A'} = PDFDict();
    $self->{'A'}->{'S'} = PDFName('Launch');
    $self->{'A'}->{'F'} = PDFStr($file);
    return $self;
}

=item $otl->pdf_file($pdffile, $pagenum, %opts)

=item $otl->pdf_file($pdffile, $pagenum)

Defines the destination of the outline as a PDF-file with filepath 
C<$pdffile>, on page C<$pagenum>, and options %opts (same as dest()).

The old name, I<pdfile>, is still available but is B<deprecated> and will be
removed at some time in the future.

=cut

# to be removed no earlier than October, 2020
sub pdfile {
    my ($self, $file, $pnum, %opts) = @_;
    warn "use pdf_file() method instead of pdfile()";
    return $self->pdf_file($file, $pnum, %opts);
}

sub pdf_file {
    my ($self, $file, $pnum, %opts) = @_;

    delete $self->{'Dest'};
    $self->{'A'} = PDFDict();
    $self->{'A'}->{'S'} = PDFName('GoToR');
    $self->{'A'}->{'F'} = PDFStr($file);
    if      (defined $opts{'-fit'}) {
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('Fit'));
    } elsif (defined $opts{'-fith'}) {
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('FitH'), PDFNum($opts{'-fith'}));
    } elsif (defined $opts{'-fitb'}) {
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('FitB'));
    } elsif (defined $opts{'-fitbh'}) {
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('FitBH'), PDFNum($opts{'-fitbh'}));
    } elsif (defined $opts{'-fitv'}) {
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('FitV'), PDFNum($opts{'-fitv'}));
    } elsif (defined $opts{'-fitbv'}) {
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('FitBV'), PDFNum($opts{'-fitbv'}));
    } elsif (defined $opts{'-fitr'}) {
        die "Insufficient parameters to ->dest(page, -fitr => []) " unless scalar @{$opts{'-fitr'}} == 4;
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('FitR'), map {PDFNum($_)} @{$opts{'-fitr'}});
    } elsif (defined $opts{'-xyz'}) {
        die "Insufficient parameters to dest(page, -xyz => []) " unless scalar @{$opts{'-fitr'}} == 3;
        $self->{'A'}->{'D'} = PDFArray(PDFNum($pnum), PDFName('XYZ'), map {PDFNum($_)} @{$opts{'-xyz'}});
    }
    return $self;
}

sub out_obj {
    my ($self, @param) = @_;

    $self->fix_outline();
    return $self->SUPER::out_obj(@param);
}

sub outobjdeep {
    my ($self, @param) = @_;

    $self->fix_outline();
    foreach my $k (qw/ api apipdf apipage /) {
        $self->{" $k"} = undef;
        delete($self->{" $k"});
    }
    my @ret = $self->SUPER::outobjdeep(@param);
    foreach my $k (qw/ First Parent Next Last Prev /) {
        $self->{$k} = undef;
        delete($self->{$k});
    }
    return @ret;
}

=back

=cut

1;
