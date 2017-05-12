package Orze::Sources::Markdown;

use strict;
use warnings;

use base "Orze::Sources";

use Text::Markdown 'markdown';

=head1 NAME

Orze::Sources::Markdown - Load a Markdown file and render it as a html
fragment using L<Text::Markdown>.

=head1 DESCRIPTION

Load the file given in the C<file> attribute and render it.

=head1 METHOD

=head2 evaluate

=cut

sub evaluate {
    my ($self) = @_;

    my $page = $self->{page};
    my $var  = $self->{var};
    my $file = $self->file();

    if (-r $file) {
        open FILE, $file;
        my @lines = <FILE>;
        close FILE;

        my $src = join("", @lines);
        my $html = markdown($src);
        return $html;
    }
    else {
        $self->warning("unable to read file " . $file);
    }
}

1;
