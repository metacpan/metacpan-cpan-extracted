package PDF::Make::Builder::Text::H6;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Text::H6',
        extends => 'PDF::Make::Builder::Text',
        'toc:Bool:default(0)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Text::H6');
}

sub add {
    my ($self, $builder) = @_;
    my $f = font $self // {};
    $f->{size}        //= 15;
    $f->{line_height} //= 19;
    font $self, $f;

    if ($self->toc && $builder->toc) {
        $builder->toc->outline($builder, 6,
            text => PDF::Make::Builder::Text::text($self),
            page_num => $builder->page->num,
        );
    }

    return $self->SUPER::add($builder);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Text::H6 - Level-6 heading preset for PDF::Make

=head1 SYNOPSIS

    $builder->add_h6(text => 'Minor Heading', toc => 1);

=head1 DESCRIPTION

Extends L<PDF::Make::Builder::Text> with heading-level-6 font defaults:
size 15, line_height 13.

=head1 PROPERTIES

Inherits all properties from L<PDF::Make::Builder::Text>, plus:

=over 4

=item B<toc> (Bool, default 0)

When true, automatically adds this heading to the document's table of contents.

=back

=head1 SEE ALSO

L<PDF::Make::Builder::Text>, L<PDF::Make::Builder::TOC>

=cut
