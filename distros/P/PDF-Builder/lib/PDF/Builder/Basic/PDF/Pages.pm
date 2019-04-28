#=======================================================================
#
#   THIS IS A REUSED PERL MODULE, FOR PROPER LICENCING TERMS SEE BELOW:
#
#   Copyright Martin Hosken <Martin_Hosken@sil.org>
#
#   No warranty or expression of effectiveness, least of all regarding
#   anyone's safety, is implied in this software or documentation.
#
#   This specific module is licensed under the Perl Artistic License.
#
#=======================================================================
package PDF::Builder::Basic::PDF::Pages;

use strict;
no warnings qw[ deprecated recursion uninitialized ];

use base 'PDF::Builder::Basic::PDF::Dict';

our $VERSION = '3.014'; # VERSION
my $LAST_UPDATE = '3.014'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Array;
use PDF::Builder::Basic::PDF::Dict;
use PDF::Builder::Basic::PDF::Utils;

use Scalar::Util qw(weaken);

our %inst = map {$_ => 1} qw(Parent Type);

=head1 NAME

PDF::Builder::Basic::PDF::Pages - a PDF pages hierarchical element. 
Inherits from L<PDF::Builder::Basic::PDF::Dict>

=head1 DESCRIPTION

A Pages object is the parent to other pages objects or to page objects
themselves.

=head1 METHODS

=head2 PDF::Builder::Basic::PDF::Pages->new($pdfs, $parent)

This creates a new Pages object. Notice that C<$parent> here is not the
file context for the object but the parent pages object for this
pages. If we are using this class to create a root node, then C<$parent>
should point to the file context, which is identified by not having a
Type of Pages. C<$pdfs> is the file object (or objects) in which to
create the new Pages object.

=cut

sub new {
    my ($class, $pdfs, $parent) = @_;

    my ($self);

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdfs, $parent);
    $self->{'Type'} = PDFName("Pages");
    $self->{'Parent'} = $parent if defined $parent;
    $self->{'Count'} = PDFNum(0);
    $self->{'Kids'} = PDF::Builder::Basic::PDF::Array->new();
    $self->{' outto'} = ref $pdfs eq 'ARRAY' ? $pdfs : [$pdfs];
    $self->out_obj(1);

    weaken $_ for @{$self->{' outto'}};
    weaken $self->{'Parent'} if defined $parent;

    return $self;
}

sub init {
    my ($self, $pdf) = @_;
    $self->{' outto'} = [$pdf];
    weaken $self->{' outto'}->[0] if defined $pdf;
    return $self;
}

=head2 $p->out_obj($isnew)

Tells all the files that this thing is destined for that they should output this
object come time to output. If this object has no parent, then it must be the
root. So set as the root for the files in question and tell it to be output too.
If C<$isnew> is set, then call C<new_obj> rather than C<out_obj> to create as 
a new object in the file.

=cut

sub out_obj {
    my ($self, $isnew) = @_;

    foreach (@{$self->{' outto'}}) {
        if ($isnew) { 
	    $_->new_obj($self); 
        } else { 
	    $_->out_obj($self);
        }

        unless (defined $self->{'Parent'}) {
            $_->{'Root'}{'Pages'} = $self;
            $_->out_obj($_->{'Root'});
        }
    }
    return $self;
}

=head2 $p->find_page($pnum)

Returns the given page, using the page count values in the pages tree. Pages
start at 0.

=cut

sub find_page {
    my ($self, $pnum) = @_;

    my ($top) = $self->get_top();

    return $top->find_page_recurse(\$pnum);
}

sub find_page_recurse {
    my ($self, $rpnum) = @_;

    my $res;

    if ($self->{'Count'}->realise()->val() <= $$rpnum) {
        $$rpnum -= $self->{'Count'}->val();
        return;
    }

    foreach my $k ($self->{'Kids'}->realise()->elementsof()) {
        if      ($k->{'Type'}->realise()->val() eq 'Page') {
            return $k if ($$rpnum == 0);
            $$rpnum--;
        } elsif ($res = $k->realise()->find_page_recurse($rpnum)) {
            return $res;
        }
    }
    return;
}

=head2 $p->add_page($page, $pnum)

Inserts the page before the given C<$pnum>. C<$pnum> can be negative to count 
from the END of the document. -1 is after the last page. Likewise C<$pnum> can 
be greater than the number of pages currently in the document, to append.

This method only guarantees to provide a reasonable pages tree if pages are
appended or prepended to the document. Pages inserted in the middle of the
document may simply be inserted in the appropriate leaf in the pages tree 
without adding any new branches or leaves. To tidy up such a mess, it is best 
to call C<$p->rebuild_tree()> to rebuild the pages tree into something 
efficient. B<Note that C<rebuild_tree> is currently a no-op!>

=cut

sub add_page {
    my ($self, $page, $pnum) = @_;

    my ($top) = $self->get_top();
    my ($ppage, $ppages, $pindex, $ppnum);

    $pnum = -1 unless (defined $pnum && $pnum <= $top->{'Count'}->val());
    if ($pnum == -1) {
        $ppage = $top->find_page($top->{'Count'}->val() - 1);
    } else {
        $pnum = $top->{'Count'}->val() + $pnum + 1 if $pnum < 0;
        $ppage = $top->find_page($pnum);
    }

    if (defined $ppage->{'Parent'}) {
        $ppages = $ppage->{'Parent'}->realise();
    } else {
        $ppages = $self;
    }

    $ppnum = scalar $ppages->{'Kids'}->realise()->elementsof();

    if ($pnum == -1) {
        $pindex = -1;
    } else {
        for ($pindex = 0; $pindex < $ppnum; $pindex++) {
       	    last if ($ppages->{'Kids'}{' val'}[$pindex] eq $ppage);
        }
        $pindex = -1 if ($pindex == $ppnum);
    }

    $ppages->add_page_recurse($page->realise(), $pindex);
    for ($ppages = $page->{'Parent'}; 
	 defined $ppages->{'Parent'}; 
	 $ppages = $ppages->{'Parent'}->realise()) {
        $ppages->out_obj()->{'Count'}->realise()->{'val'}++;
    }
    $ppages->out_obj()->{'Count'}->realise()->{'val'}++;
    return $page;
} # end of add_page()

sub add_page_recurse {
    my ($self, $page, $index) = @_;
    my ($newpages, $ppages, $pindex, $ppnum);

    if (scalar $self->{'Kids'}->elementsof() >= 8 && 
	 $self->{'Parent'} && 
	 $index < 1) {
        $ppages = $self->{'Parent'}->realise();
        $newpages = $self->new($self->{' outto'}, $ppages);
        if ($ppages) {
            $ppnum = scalar $ppages->{'Kids'}->realise()->elementsof();
            for ($pindex = 0; $pindex < $ppnum; $pindex++) {
                last if $ppages->{'Kids'}{' val'}[$pindex] eq $self;
            }
            $pindex++ if $index == -1;
            $ppages->add_page_recurse($newpages, $pindex);
        }
    } else {
        $newpages = $self->out_obj();
    }

    if ($index < 0) {
        push (@{$newpages->{'Kids'}->realise()->{' val'}}, $page);
    } else {
        splice (@{$newpages->{'Kids'}{' val'}}, $index, 0, $page);
    }
    $page->{'Parent'} = $newpages;
    weaken $page->{'Parent'};
    return;
} # end of add_page_recurse()

=head2 $root_pages = $p->rebuild_tree([@pglist])

B<WARNING: Not yet implemented. Do not attempt to use!>

Rebuilds the pages tree to make a nice balanced tree that conforms to Adobe
recommendations. If passed a C<@pglist> then the tree is built for that list of
pages. No check is made of whether the C<@pglist> contains pages.

Returns the top of the tree for insertion in the root object.

=cut

# TBD where's the code?
sub rebuild_tree {
    my ($self, @pglist) = @_;
    return;
}

=head2 @pglist = $p->get_pages()

Returns a list of page objects in the document in page order

=cut

sub get_pages {
    my ($self) = @_;

    return $self->get_top()->get_kids();
}

# only call this on the top level or anything you want pages below
sub get_kids {
    my ($self) = @_;

    my @pglist;

    foreach my $pgref ($self->{'Kids'}->elementsof()) {
        $pgref->realise();
        if ($pgref->{'Type'}->val() =~ m/^Pages$/oi) {
       	    push (@pglist, $pgref->get_kids());
        } else {
	    push (@pglist, $pgref);
        }
    }
    return @pglist;
}

=head2 $p->find_prop($key)

Searches up through the inheritance tree to find a property.

=cut

sub find_prop {
    my ($self, $prop) = @_;

    if (defined $self->{$prop}) {
        if (ref $self->{$prop} && 
	    $self->{$prop}->isa("PDF::Builder::Basic::PDF::Objind")) {
	    return $self->{$prop}->realise();
        } else {
	    return $self->{$prop};
        }
    } elsif (defined $self->{'Parent'}) {
        return $self->{'Parent'}->find_prop($prop);
    }
    return;
}

=head2 $p->add_font($pdf, $font)

Creates or edits the resource dictionary at this level in the hierarchy. If
the font is already supported even through the hierarchy, then it is not added.

=cut

sub add_font {
    my ($self, $font, $pdf) = @_;

    my ($name) = $font->{'Name'}->val();
    my ($dict) = $self->find_prop('Resources');
    my ($rdict);

    return $self if ($dict ne "" && 
	             defined $dict->{'Font'} && 
		     defined $dict->{'Font'}{$name});
    unless (defined $self->{'Resources'}) {
        $dict = $dict ne "" ? $dict->copy($pdf) : PDFDict();
        $self->{'Resources'} = $dict;
    } else {
	$dict = $self->{'Resources'};
    }
    $dict->{'Font'} = PDFDict() unless defined $self->{'Resources'}{'Font'};
    $rdict = $dict->{'Font'}->val();
    $rdict->{$name} = $font unless ($rdict->{$name});
    if (ref $dict ne 'HASH' && $dict->is_obj($pdf)) { 
	$pdf->out_obj($dict);
    }
    if (ref $rdict ne 'HASH' && $rdict->is_obj($pdf)) {
        $pdf->out_obj($rdict);
    }
    return $self;
} # end of add_font()

=head2 $p->bbox($xmin,$ymin, $xmax,$ymax, [$param])

Specifies the bounding box for this and all child pages. If the values are
identical to those inherited then no change is made. $param specifies the 
attribute name so that other 'bounding box'es can be set with this method.

=cut

sub bbox {
    my ($self, @bbox) = @_;

    my ($str) = $bbox[4] || 'MediaBox';
    my ($inh) = $self->find_prop($str);
    my ($test, $i);

    if ($inh ne "") {
        $test = 1; 
	$i = 0;
        foreach my $e ($inh->elementsof()) { 
            $test &= $e->val() == $bbox[$i++];
        }
        return $self if $test && $i == 4;
    }

    $inh = PDF::Builder::Basic::PDF::Array->new();
    foreach my $e (@bbox[0..3]) {
        $inh->add_elements(PDFNum($e));
    }
    $self->{$str} = $inh;
    return $self;
}

=head2 $p->proc_set(@entries)

Ensures that the current resource contains all the entries in the proc_sets
listed. If necessary it creates a local resource dictionary to achieve this.

=cut

sub proc_set {
    my ($self, @entries) = @_;

    my (@temp) = @entries;
    my $dict;

    $dict = $self->find_prop('Resource');
    if ($dict ne "" && defined $dict->{'ProcSet'}) {
        foreach my $e ($dict->{'ProcSet'}->elementsof()) { 
	    @temp = grep($_ ne $e, @temp);  ## no critic
        }
        return $self if (scalar @temp == 0);
        @entries = @temp if defined $self->{'Resources'};
    }

    unless (defined $self->{'Resources'}) { 
        $self->{'Resources'} = $dict ne "" ? $dict->copy : PDFDict();
    }

    $self->{'Resources'}{'ProcSet'} = PDFArray() unless defined $self->{'ProcSet'};

    foreach my $e (@entries) { 
	$self->{'Resources'}{'ProcSet'}->add_elements(PDFName($e)); 
    }
    return $self;
} # end of proc_set()

sub empty {
    my ($self) = @_;

    my $parent = $self->{'Parent'};

    $self->SUPER::empty();
    if (defined $parent) {
        $self->{'Parent'} = $parent;
        weaken $self->{'Parent'};
    }
    return $self;
}

sub dont_copy {
   return $inst{$_[1]} || $_[0]->SUPER::dont_copy($_[1]);
}

=head2 $p->get_top()

Returns the top of the pages tree

=cut

sub get_top {
    my ($self) = @_;

    my ($p);

    for ($p = $self; defined $p->{'Parent'}; $p = $p->{'Parent'})
    { } # simply looping until run out of Parents. equivalent:  ;

    return $p->realise();
}

1;
