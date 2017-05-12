package SWISH::Prog::Test::Indexer;
use strict;
use warnings;
use base 'SWISH::Prog::Indexer';

our $VERSION = '0.75';

sub test_mode {1}
sub start     { }
sub finish    { }

1;

__END__

=pod

=head1 NAME

SWISH::Prog::Test::Indexer - test indexer class

=head1 SYNOPSIS

 use SWISH::Prog::Test::Indexer;
 
 my $spider = SWISH::Prog::Aggregator::Spider->new(
    indexer => SWISH::Prog::Test::Indexer->new()
 );
 $spider->crawl('http://localhost/foo');

=head1 DESCRIPTION

SWISH::Prog::Test::Indexer is for testing other
components of SWISH::Prog where no index is desired.
For example, testing aggregator features without any need
to store the documents aggregated.

=head1 METHODS

These methods are overridden as no-ops.

=head2 test_mode

=head2 start

=head2 finish


=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
