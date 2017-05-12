package URI::poe;

use strict;
use warnings;

use POEx::URI;

use vars qw( @ISA );

@ISA = qw( POEx::URI );

1;
__END__

=head1 NAME

URI::poe - URI extension for POE urls

=head1 SYNOPSIS

    use URI;
    my $uri = URI->new( "poe://kernelID/session/event" );


=head1 DESCRIPTION

Please see L<POEx::URI> for description.

=head1 SEE ALSO

L<URI>, L<POEx::URI>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
