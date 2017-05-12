package Net::PMP::AuthToken;
use Moose;
use Carp;

has 'access_token'     => ( is => 'rw', isa => 'Str', required => 1, );
has 'token_type'       => ( is => 'rw', isa => 'Str', required => 1, );
has 'token_issue_date' => ( is => 'rw', isa => 'Str', required => 1, );
has 'token_expires_in' => ( is => 'rw', isa => 'Int', required => 1, );

use overload
    '""'     => sub { $_[0]->as_string; },
    'bool'   => sub {1},
    fallback => 1;

__PACKAGE__->meta->make_immutable();

our $VERSION = '0.006';

sub expires_in { shift->token_expires_in(@_) }

sub as_string { return shift->access_token }

1;

__END__

=head1 NAME

Net::PMP::AuthToken - authorization token for Net::PMP::Client

=head1 SYNOPSIS

 use Net::PMP::Client;
 
 my $host = 'https://api-sandbox.pmp.io';
 my $client_id = 'i-am-a-client';
 my $client_secret = 'i-am-a-secret';

 # instantiate a client
 my $client = Net::PMP::Client->new(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ) or die "Can't connect to server $host: " . $Net::PMP::Client::Error;

 # authenticate
 my $token = $client->get_token();
 if ($token->expires_in() < 10) {
     die "Access token expires too soon. Not enough time to make a request. Mayday, mayday!";
 }
 printf("PMP token is: %s\n, $token->as_string());

=head1 DESCRIPTION

Net::PMP::AuthToken is the object representation of an authorization token.

=head1 METHODS

=head2 access_token

=head2 token_type

=head2 token_issue_date

=head2 token_expires_in

=head2 expires_in

Alias for B<token_expires_in>.

=head2 as_string

Returns the B<access_token>. Objects are overloaded to stringify with as_string().

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::AuthToken


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
