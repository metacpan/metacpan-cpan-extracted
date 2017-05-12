package OpenTok::API::Session;

use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

OpenTok::API::Session - Session object for OpenTok::API
http://www.tokbox.com/

=head1 SUBROUTINES/METHODS

=head2 new

Creates new OpenTok::API::Session object

=cut
sub new {
    my ($class, %args) = @_;    
    my $self = {
        %args,
    };
    
    bless $self, $class;
    
    return $self;
}

=head2 getSessionId

Returns SessionID for OpenTok::API::Session object

=cut

sub getSessionId {
    return shift->{session_id};
}

=head1 AUTHOR

Maxim Nikolenko, C<< <root at zbsd.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-opentok-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenTok::API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenTok::API

You can also look for information at:

http://www.tokbox.com/opentok/api/tools/as3/documentation/overview/index.html

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenTok::API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenTok-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenTok-API>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenTok-API/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Maxim Nikolenko.

This module is released under the following license: BSD


=cut
1;