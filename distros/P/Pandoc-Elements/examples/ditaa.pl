#!/usr/bin/env perl
use strict;

use Pandoc::Filter;
use Pandoc::Filter::ImagesFromCode;

pandoc_filter 'CodeBlock.ditaa' => Pandoc::Filter::ImagesFromCode->new(
    from => 'ditaa',
    to   => 'png',
    # TODO: support use of dita-eps for vector images
    run  => ['ditaa', '-o', '$infile$', '$outfile$'],
);

__END__

=head1 NAME

ditaa - process code blocks with C<.ditaa> into images

=head1 SYNOPSIS

  pandoc --filter ditaa.pl -o output.html < input.md

=head1 SEE ALSO

This is a rewrite of the standalone-script C<mdddia> originally published at
L<https://github.com/nichtich/ditaa-markdown>.

=cut
