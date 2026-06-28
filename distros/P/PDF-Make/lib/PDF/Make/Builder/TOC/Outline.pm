package PDF::Make::Builder::TOC::Outline;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::TOC::Outline',
        'text:Str:required',
        'page_num:Int:required',
        'level:Int:default(1)',
        'children:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::TOC::Outline');
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::TOC::Outline - TOC entry data class for PDF::Make

=head1 SYNOPSIS

    my $entry = PDF::Make::Builder::TOC::Outline->new(
        text     => 'Chapter 1',
        page_num => 3,
        level    => 1,
    );

=head1 DESCRIPTION

A pure data class representing a single entry in the table of contents.  Has
no methods beyond its accessors.

=head1 PROPERTIES

=over 4

=item B<text> (Str, required)

The display text of the TOC entry.

=item B<page_num> (Int, required)

The page number this entry points to.

=item B<level> (Int, default 1)

The heading depth level (1 = top-level).

=item B<children> (ArrayRef, default C<[]>)

Nested child outline entries.

=back

=head1 SEE ALSO

L<PDF::Make::Builder::TOC>

=cut
