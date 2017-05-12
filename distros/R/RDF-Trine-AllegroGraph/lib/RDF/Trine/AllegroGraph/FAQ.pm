package RDF::Trine::AllegroGraph::FAQ;

=pod

=head1 NAME

RDF::Trine::AllegroGraph::FAQ - Integrating Trine with AllegroGraph, the Quirks

=head1 FAQs

=over

=item Q: Adding statements one-by-one is slow. What can I do?

A: See whether you can use C<begin_bulk_mode> to aggregate some changes. If that still does not
help, then you will have to use the AG repository B<directly>. For that use

    my $repo = $store->{model};  # get the AGv4 repository

=item Q: How do I completely remove one repository via Trine?

A: At the moment you will have to call C<$store->_nuke> until L<RDF::Trine> provides an official
method.

=item Q: I have AGv4 running and would like to offer a SPARQL HTTP endpoint for a certain
repository. How to do that?

A: Look at the file C<t/endpoint.psgi>. The configuration of that is described in L<RDF::Endpoint>.
Once you have cloned that, you can start a L<Plack> server with

   plackup endpoint.psgi

=item Q: What about exposing not only one repository, but several?

A: I have not tested it myself (yet), but L<Plack::Builder> seems to be a viable path.


=back

=cut

our $VERSION = '0.01';

=pod

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 SEE ALSO

L<RDF::Trine::AllegroGraph>

=head1 ACKNOWLEDGEMENTS

The development of this package was supported by Franz Inc.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
