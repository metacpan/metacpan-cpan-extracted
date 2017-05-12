package RDF::Trine::AllegroGraph;

use strict;
use warnings;

=head1 NAME

RDF::Trine::AllegroGraph - Compatibility layer between RDF::Trine and AllegroGraph

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RDF::Trine::Store;
    my $store = RDF::Trine::Store->new_with_string( "AllegroGraph;$AG4_SERVER/cat23/repo34" );
    use RDF::Trine::Model;
    my $model = RDF::Trine::Model->new ($store);

    # start to use the model according to RDF::Trine::Model

     my $query = RDF::Query->new( 'SELECT * WHERE ...' );
     my $iterator = $query->execute( $model );
     while (my $row = $iterator->next) {
         # $row is a HASHref containing variable name -> RDF Term bindings
         print $row->{ 'var' }->as_string;
     }

=head1 DESCRIPTION

@@@@

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-trine-allegrograph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Trine-AllegroGraph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<RDF::Trine::Store::AllegroGraph>

=head1 ACKNOWLEDGEMENTS

The development of this package was supported by Franz Inc.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
