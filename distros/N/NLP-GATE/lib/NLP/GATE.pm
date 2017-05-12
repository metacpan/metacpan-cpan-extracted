package NLP::GATE;

use 5.008_001;

use warnings;
use strict;

use NLP::GATE::Annotation;
use NLP::GATE::AnnotationSet;
use NLP::GATE::Document;

=head1 NAME

NLP::GATE - Handle GATE documents and annotations

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

    use NLP::GATE;

    my $doc = NLP::GATE::Document->new();
    $doc->setText($text);
    $ann = NLP::GATE::Annotation->new();
    ...

=head1 DESCRIPTION

This is the container module for various modules that make it possible
to create and handle GATE documents from the NLP tool GATE (http://gate.ac.uk)

This module does not do anything by itself, it just pulls in the
modules for monipulating documents, annotation sets and annotations.
For more information on those see:

=over 4

=item NLP::GATE::Document

=item NLP::GATE::AnnotationSet

=item NLP::GATE::Annotation

=back

=cut


=head1 AUTHOR

Johann Petrak, C<< <firstname.lastname-at-jpetrak-dot-com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gate-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NLP::GATE>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc NLP::GATE

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/~JOHANNP/NLP-GATE/>

=item * CPAN Ratings

L<http://cpanratings.perl.org/rate/?distribution=NLP-GATE>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=NLP-GATE>

=item * Search CPAN

L<http://search.cpan.org/~johannp/NLP-GATE/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Johann Petrak, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of NLP::GATE
