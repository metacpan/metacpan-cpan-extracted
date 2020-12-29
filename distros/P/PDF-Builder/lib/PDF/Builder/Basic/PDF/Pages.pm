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
use warnings;

use base 'PDF::Builder::Basic::PDF::Dict';

our $VERSION = '3.021'; # VERSION
my $LAST_UPDATE = '3.017'; # manually update whenever code is changed

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

=head2 PDF::Builder::Basic::PDF::Pages->new($pdf, $parent)

This creates a new Pages object in a PDF. Notice that the C<$parent> here is 
not the file context for the object, but the parent pages object for these 
pages. If we are using this class to create a root node, C<$parent> should 
point to the file context, which is identified by I<not> having a Type of 
I<Pages>. C<$pdf> is the file object (or a reference to an array of I<one> 
file object [3.016 and later, or multiple file objects earlier]) in which to 
create the new Pages object.

=cut

sub new {
    my ($class, $pdf, $parent) = @_;
    $pdf //= $class->get_top()->{' parent'} if ref($class);

    # before PDF::API2 2.034/PDF::Builder 3.016, $pdf could be an array of PDFs
    if (ref($pdf) eq 'ARRAY') {
	die 'Pages: Only one PDF is supported as of version 3.016' if scalar(@$pdf) > 1;
	($pdf) = @$pdf;
    }

    $class = ref($class) if ref($class);
    my $self = $class->SUPER::new($pdf, $parent);

    $self->{'Type'} = PDFName('Pages');
    $self->{'Parent'} = $parent if defined $parent;
    $self->{'Count'} = PDFNum(0);
    $self->{'Kids'} = PDF::Builder::Basic::PDF::Array->new();

    $pdf->new_obj($self);
    unless (defined $self->{'Parent'}) {
        $pdf->{'Root'}->{'Pages'} = $self;
        $pdf->out_obj($pdf->{'Root'});

        $self->{' parent'} = $pdf;
        weaken $self->{' parent'};
    }
    weaken $self->{'Parent'} if defined $parent;

    return $self;
}

#sub init {
#    my ($self, $pdf) = @_;
#    $self->{' destination_pdfs'} = [$pdf];
#    weaken $self->{' destination_pdfs'}->[0] if defined $pdf;
#
#    return $self;
#}

#=head2 $p->out_obj($is_new)
#
#Tells all the files that this thing is destined for that they should output this
#object, come time to output. If this object has no parent, then it must be the
#root. So set as the root for the files in question and tell it to be output too.
#If C<$is_new> is set, then call C<new_obj> rather than C<out_obj> to create as 
#a new object in the file.
#
#=cut
#
#sub out_obj {
#    my ($self, $is_new) = @_;
#
#    foreach my $pdf (@{$self->{' destination_pdfs'}}) {
#        if ($is_new) { 
#	    $pdf->new_obj($self); 
#        } else { 
#	    $pdf->out_obj($self);
#        }
#
#        unless (defined $self->{'Parent'}) {
#            $pdf->{'Root'}{'Pages'} = $self;
#            $pdf->out_obj($pdf->{'Root'});
#        }
#    }
#    
#    return $self;
#}

sub _pdf {
    my ($self) = @_;
    return $self->get_top()->{' parent'};
}

=head2 $p->find_page($page_number)

Returns the given page, using the page count values in the pages tree. Pages
start at 0.

=cut

sub find_page {
    my ($self, $page_number) = @_;
    my $top = $self->get_top();

    return $top->find_page_recursively(\$page_number);
}

sub find_page_recursively {
    my ($self, $page_number_ref) = @_;

    if ($self->{'Count'}->realise()->val() <= $$page_number_ref) {
        $$page_number_ref -= $self->{'Count'}->val();
        return;
    }

    my $result;
    foreach my $kid ($self->{'Kids'}->realise()->elements()) {
        if      ($kid->{'Type'}->realise()->val() eq 'Page') {
            return $kid if $$page_number_ref == 0;
            $$page_number_ref--;
        } elsif ($result = $kid->realise()->find_page_recursively($page_number_ref)) {
            return $result;
        }
    }

    return;
}

=head2 $p->add_page($page, $page_number)

Inserts the page before the given C<$page_number>. C<$page_number> can be 
negative to count backwards from the END of the document. -1 is after the last 
page. Likewise C<$page_number> can be greater than the number of pages 
currently in the document, to append.

This method only guarantees to provide a reasonable pages tree if pages are
appended or prepended to the document. Pages inserted in the middle of the
document may simply be inserted in the appropriate leaf in the pages tree 
without adding any new branches or leaves, leaving it unbalanced (slower
performance, but still usable). 

=cut

# -- removed from end of second para:
#To tidy up such a mess, it is best 
#to call C<$p->rebuild_tree()> to rebuild the pages tree into something 
#efficient. B<Note that C<rebuild_tree> is currently a no-op!>

sub add_page {
    my ($self, $page, $page_number) = @_;
    my $top = $self->get_top();

    $page_number = -1 unless defined $page_number and $page_number <= $top->{'Count'}->val();

    my $previous_page;
    if ($page_number == -1) {
        $previous_page = $top->find_page($top->{'Count'}->val() - 1);
    } else {
        $page_number = $top->{'Count'}->val() + $page_number + 1 if $page_number < 0;
        $previous_page = $top->find_page($page_number);
    }

    my $parent;
    if (defined $previous_page->{'Parent'}) {
        $parent = $previous_page->{'Parent'}->realise();
    } else {
        $parent = $self;
    }

    my $parent_kid_count = scalar $parent->{'Kids'}->realise()->elements();

    my $page_index;
    if ($page_number == -1) {
        $page_index = -1;
    } else {
        for ($page_index = 0; 
             $page_index < $parent_kid_count; 
             $page_index++) {
       	    last if $parent->{'Kids'}{' val'}[$page_index] eq $previous_page;
        }
        $page_index = -1 if $page_index == $parent_kid_count;
    }

    $parent->add_page_recursively($page->realise(), $page_index);
    for ($parent = $page->{'Parent'}; 
         defined $parent->{'Parent'}; 
         $parent = $parent->{'Parent'}->realise()) {
        $parent->set_modified();
        $parent->{'Count'}->realise()->{'val'}++;
    }
    $parent->set_modified();
    $parent->{'Count'}->realise()->{'val'}++;

    return $page;
} # end of add_page()

sub add_page_recursively {
    my ($self, $page, $page_index) = @_;

    my $parent = $self;
    my $max_kids_per_parent = 8; # Why 8?
    if (scalar $parent->{'Kids'}->elements() >= $max_kids_per_parent and 
        $parent->{'Parent'} and 
        $page_index < 1) {
        my $grandparent = $parent->{'Parent'}->realise();
        $parent = $parent->new($parent->_pdf(), $grandparent);

        my $grandparent_kid_count = scalar $grandparent->{'Kids'}->realise()->elements();
        my $new_parent_index;
        for ($new_parent_index = 0; 
             $new_parent_index < $grandparent_kid_count; 
             $new_parent_index++) {
            last if $grandparent->{'Kids'}{' val'}[$new_parent_index] eq $self;
        }
        $new_parent_index++;
        $new_parent_index = -1 if $new_parent_index > $grandparent_kid_count;
        $grandparent->add_page_recursively($parent, $new_parent_index);
    } else {
        $parent->set_modified();
    }

    if ($page_index < 0) {
        push @{$parent->{'Kids'}->realise()->{' val'}}, $page;
    } else {
        splice @{$parent->{'Kids'}{' val'}}, $page_index, 0, $page;
    }
    $page->{'Parent'} = $parent;
    weaken $page->{'Parent'};

    return;
} # end of add_page_recursively()

sub set_modified {
    my ($self) = @_;
    $self->_pdf()->out_obj($self);
    return;
}

#=head2 $root_pages = $p->rebuild_tree([@pglist])
#
#B<WARNING: Not yet implemented. Do not attempt to use!>
#
#Rebuilds the pages tree to make a nice balanced tree that conforms to Adobe
#recommendations. If passed a C<@pglist> then the tree is built for that list of
#pages. No check is made of whether the C<@pglist> contains pages.
#
#Returns the top of the tree for insertion in the root object.
#
#=cut

# TBD where's the code?
#sub rebuild_tree {
#    my ($self, @pglist) = @_;
#    return;
#}

=head2 @objects = $p->get_pages()

Returns a list of page objects in the document, in page order.

=cut

sub get_pages {
    my ($self) = @_;

    return $self->get_top()->get_pages_recursively();
}

# Renamed for clarity. should this be deprecated?
# appears not to have been used, and was undocumented.
sub get_kids { return get_pages_recursively(@_); }

sub get_pages_recursively {
    my ($self) = @_;
    my @pages;

    foreach my $kid ($self->{'Kids'}->elements()) {
        $kid->realise();
        if ($kid->{'Type'}->val() eq 'Pages') {
       	    push @pages, $kid->get_pages_recursively();
        } else {
            push @pages, $kid;
        }
    }

    return @pages;
}

=head2 $p->find_prop($key)

Searches up through the inheritance tree to find a property (key).

=cut

sub find_prop {
    my ($self, $key) = @_;

    if      (defined $self->{$key}) {
        if (ref($self->{$key}) and 
            $self->{$key}->isa('PDF::Builder::Basic::PDF::Objind')) {
            return $self->{$key}->realise();
        } else {
            return $self->{$key};
        }
    # Per Klaus Ethgen (RT 131147), this is an alternative patch for the 
    # problem of Null objects bubbling up. If Vadim Repin's patch in ./File.pm
    # turns out to have too wide of scope, we might use this one instead.
    # comment out 1, uncomment 2, and reverse change made in ./File.pm.
    } elsif (defined $self->{'Parent'}) {
   #} elsif (defined $self->{'Parent'} and 
   #         ref($self->('Parent'}) ne 'PDF::Builder::Basic::PDF::Null') {
        return $self->{'Parent'}->find_prop($key);
    }

    return;
}

=head2 $p->add_font($pdf, $font)

Creates or edits the resource dictionary at this level in the hierarchy. If
the font is already supported, even through the hierarchy, then it is not added.

B<CAUTION:> if this method was used in older releases, the code may have 
swapped the order of C<$pdf> and C<$font>, requiring ad hoc swapping of 
parameters in user code, contrary to the POD definition above. Now the code
matches the documentation.

=cut

sub add_font {
    my ($self, $pdf, $font) = @_;

    my $name = $font->{'Name'}->val();
    my $dict = $self->find_prop('Resources');

    return $self if ($dict and 
                     defined $dict->{'Font'} and 
                     defined $dict->{'Font'}{$name});
    unless (defined $self->{'Resources'}) {
        $dict = $dict ? $dict->copy($pdf) : PDFDict();
        $self->{'Resources'} = $dict;
    } else {
        $dict = $self->{'Resources'};
    }
    $dict->{'Font'} //= PDFDict();

    my $resource = $dict->{'Font'}->val();
    $resource->{$name} //= $font;
    if (ref($dict) ne 'HASH' and $dict->is_obj($pdf)) {
        $pdf->out_obj($dict);
    }
    if (ref($resource) ne 'HASH' and $resource->is_obj($pdf)) {
        $pdf->out_obj($resource);
    }

    return $self;
} # end of add_font()

=head2 $p->bbox($xmin,$ymin, $xmax,$ymax, $param)

=head2 $p->bbox($xmin,$ymin, $xmax,$ymax)

Specifies the bounding box for this and all child pages. If the values are
identical to those inherited, no change is made. C<$param> specifies the 
attribute name so that other 'bounding box'es can be set with this method.

=cut

sub bbox {
    my ($self, @bbox) = @_;
    my $key = $bbox[4] || 'MediaBox';
    my $inherited = $self->find_prop($key);

    if ($inherited) {
        my $is_changed = 0;
        my $i = 0;
        foreach my $element ($inherited->elements()) {
            $is_changed = 1 unless $element->val() == $bbox[$i++];
        }
        return $self if $i == 4 and not $is_changed;
    }

    my $array = PDF::Builder::Basic::PDF::Array->new();
    foreach my $element (@bbox[0 .. 3]) {
        $array->add_elements(PDFNum($element));
    }
    $self->{$key} = $array;

    return $self;
}

=head2 $p->proc_set(@entries)

Ensures that the current resource contains all the entries in the proc_sets
listed. If necessary, it creates a local resource dictionary to achieve this.

=cut

sub proc_set {
    my ($self, @entries) = @_;

    my $dict = $self->find_prop('Resources');
    if ($dict and defined $dict->{'ProcSet'}) {
        my @missing = @entries;
        foreach my $element ($dict->{'ProcSet'}->elements()) { 
            @missing = grep { $_ ne $element } @missing;
        }
        return $self if scalar @missing == 0;
        @entries = @missing if defined $self->{'Resources'};
    }

    unless (defined $self->{'Resources'}) {
        $self->{'Resources'} = $dict ? $dict->copy($self->_pdf()) : PDFDict();
    }

    $self->{'Resources'}{'ProcSet'} = PDFArray() unless defined $self->{'ProcSet'};

    foreach my $element (@entries) {
        $self->{'Resources'}{'ProcSet'}->add_elements(PDFName($element)); 
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

=head2 $p->get_top()

Returns the top of the pages tree.

=cut

sub get_top {
    my ($self) = @_;

    my $top = $self;
    $top = $top->{'Parent'} while defined $top->{'Parent'};

    return $top->realise();
}

1;
