package Pod::PseudoPod::DOM::App::ToPML;
# ABSTRACT: helper functions for bin/ppdom2html

use strict;
use warnings;
use autodie;

use Pod::PseudoPod::DOM;
use Pod::PseudoPod::DOM::Corpus;

use Pod::PseudoPod::DOM::App qw( open_fh );

sub process_files_with_output
{
    my @docs;
    my %anchors;
    my $corpus = Pod::PseudoPod::DOM::Corpus->new;

    for my $file (@_)
    {
        my ($source, $output) = @$file;

        my $parser = Pod::PseudoPod::DOM->new(
            formatter_role => 'Pod::PseudoPod::DOM::Role::PML',
            formatter_args => { add_body_tags => 1, anchors => \%anchors },
            filename       => $output,
        );

        my $PMLOUT = open_fh( $output, '>' );
        $parser->output_fh($PMLOUT);

        die "Unable to open file ($source)\n" unless -e $source;
        $parser->parse_file( open_fh( $source ) );

        $corpus->add_document( $parser->get_document, $parser );
    }

    $corpus->write_documents;
    $corpus->write_index;
    $corpus->write_toc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::App::ToPML - helper functions for bin/ppdom2html

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
