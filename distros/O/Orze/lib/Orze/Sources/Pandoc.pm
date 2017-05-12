package Orze::Sources::Pandoc;

use strict;
use warnings;

use base "Orze::Sources";

=head1 NAME

Orze::Sources::Pandoc - Load a text file and render it as a html
fragment using Pandoc.

=head1 DESCRIPTION

Load the file given in the C<file> attribute and render it. It use
L<http://johnmacfarlane.net/pandoc/> to do the actual processing.

The default source and target are Markdown and HTML, but you can
customize this behaviour using C<from> and C<to> attributes.

You can pass more options using the C<options> attribute. Defaults are
C<--reference-links> and C<--parse-raw>.

The variant of Markdown used by Pandoc is more powerful than the
standard one, read C<http://johnmacfarlane.net/pandoc/README.html>.

Obviously, you will need Pandoc, available here:
L<http://johnmacfarlane.net/pandoc/#downloads>

=head1 METHOD

=head2 evaluate

=cut

sub evaluate {
    my ($self) = @_;

    my $page = $self->{page};
    my $var  = $self->{var};
    my $file = $self->file();

    my $from = $page->att('from');
    my $to = $page->att('to');

    my $options = $page->att('options');

    if (-r $file) {
        my $cmd = 'pandoc';
        if (!$options) {
            $cmd .= ' --reference-links ' .
                '--parse-raw ';
        }
        if ($from) {
            $cmd .= ' --from ' . $from;
        }
        if ($to) {
            $cmd .= ' --to ' . $to;
        }
        my $pandoc;
        {
            no warnings;
            open $pandoc, $cmd . ' ' . $file . ' |'
                or $self->warning("can't find pandoc");
            my @lines = <$pandoc>;
            close $pandoc;
            my $html = join('', @lines);
            return $html;
        }
    }
    else {
        $self->warning('unable to read file ' . $file);
    }
}

1;
