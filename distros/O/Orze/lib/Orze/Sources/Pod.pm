package Orze::Sources::Pod;

use strict;
use warnings;

use base "Orze::Sources";

use Pod::Simple::XHTML;

=head1 NAME

Orze::Sources::Pod - Load a Pod file and render it as a html fragment

=head1 DESCRIPTION

Take the file given in the C<file> attribute, append C<.pod> suffix,
load it and render it as a html fragment usable in your template.

You can use LZ<><> to refer to other pages of your website.

=head1 METHOD

=head2 evaluate

=cut

sub evaluate {
    my ($self) = @_;

    my $page = $self->{page};
    my $var  = $self->{var};
    my $file = $self->file("pod");

    if (-r $file) {
        my $output;
        my $parser = Pod::Simple::XHTML->new();
        $parser->output_string(\$output);
        $parser->html_header("");
        $parser->html_footer("");
        $parser->perldoc_url_prefix("");
        $parser->parse_file($file);
        return $output;
    }
    else {
        $self->warning("unable to read file " . $file);
    }
}

1;
