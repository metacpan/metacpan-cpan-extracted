package Museum::Rijksmuseum::Object::Harvester;

use strictures 2;

use Carp;
use HTTP::OAI;
use Moo;
use Time::HiRes qw( sleep );
use URI;
use URI::QueryParam;

use Museum::Rijksmuseum::Object;

use namespace::clean;

=head1 NAME

Museum::Rijksmuseum::Object::Harvester - Bulk-fetching of Rijksmuseum data via the OAI-PMH interface

=head1 VERSION

See L<Museum::Rijksmuseum::Object>

=cut

our $VERSION = $Museum::Rijksmuseum::Object::VERSION;

=head1 SYNOPSIS

Does a bulk fetch of the Rijksmuseum collection database using the OAI-PMH
interface. For each record a callback will be called with the data. Note that
the format of this data won't necessarily be the same as returned by the
L<Museum::Rijksmuseum::Object> calls, as it's coming from a different endpoint.

    use Museum::Rijksmuseum::Object::Harvester;

    my $h      = Museum::Rijksmuseum::Object::Harvester->new( key => 'abc123xyz' );
    my $status = $h->harvest(
        set      => 'subject:PublicDomainImages',
        from     => '2023-01-01',
        type     => 'identifiers',
        callback => \&process_record,
    );
    if ( $status->{error} ) {
        die "Error: $status->{error}\nLast resumption token: $status->{resumptionToken}\n";
    }
    if ( $status->{resumptionToken} ) {
        print "Finished, token: $status->{resumptionToken}\n";
    }

=head1 SUBROUTINES/METHODS

=head2 new

    my $h = Museum::Rijksmuseum::Object::Harvester->new( key => 'abc123xyz' );

Create a new instance of the harvester. C<key> is required.

=cut

=head2 harvest

    my $status = $h->harvest(
        set             => 'subject:PublicDomainImages',
        from            => '2023-01-01',
        to              => '2023-01-31',
        resumptionToken => $last_token_you_saw,
        delay           => 1_000, # 1 second
        type            => 'identifiers',
        callback        => \&process_record,
    );
    
Begins harvesting the records from the Rijksmuseum. The only required fields
are C<callback> and C<type>, but the default delay is 10 seconds so you
probably want to think about putting something sensible in there (or leave it
at 10 seconds if you don't mind being very polite.) If you have a resumption
token, perhaps you're recovering from a previous failure, you can supply that.
C<from> and C<to> are not defined in the API documentation, so it's uncertain
what they refer to.  Latest update time maybe?

C<type> can in theory be C<identifiers> or C<records> (mapping to
C<ListIdenifiers> and C<ListRecords> internally), but C<records> is currently
unsupported as at writing time I don't need it and it's a fair bit of work to
do right.

C<callback> will be called for every identifier or record, in the case of
identifers it'll eceive a hashref containing C<identifier> and C<datestamp>.
If the callback returns a non-false value (i.e. any value), we quietly shut down.
Due to the way resumption tokens work (i.e. they can be the same for subsequent
requests), even if you request a shutdown, you'll still be fed the rest of the
batch. This helps avoid missing records.

The return value is a hashref that contains C<error> if something went wrong,
and possibly a C<resumptionToken> to let you know how to pick up again.

=cut

sub harvest {
    my ( $self, %args ) = @_;

    my $params = {
        $args{set}             ? ( set             => $args{set} )             : (),
        $args{from}            ? ( from            => $args{from} )            : (),
        $args{until}           ? ( until           => $args{until} )           : (),
        $args{resumptionToken} ? ( resumptionToken => $args{resumptionToken} ) : (),
    };

    my $delay = $args{delay} // 10_000;
    if ( !$args{type} || $args{type} ne 'identifiers' ) {
        croak 'Only type "identifiers" is currently supported, but you still have to say it';
    }
    my $verb     = 'ListIdentifiers';
    my $callback = $args{callback};
    croak 'A "callback" parameter is required.' unless $callback;

    my $url  = sprintf( 'https://www.rijksmuseum.nl/api/oai/%s', $self->key );
    my $harv = HTTP::OAI::Harvester->new( baseURL => $url );
    # We'll handle resume ourselves, because I think the default way
    # wants to load _everything_ all in one go, or something. It's weird
    # and not useful anyway.
    $harv->resume(0);

    $params->{metadataPrefix} = 'edm_dc';
    my $last_resumption_token = undef;
    my ( $li, $shutdown );
    do {
        $li = $harv->ListIdentifiers(%$params);
        my $retries = 10;
        my $backoff_delay = 1;
        while (ref($li) ne 'HTTP::OAI::Response') {
            # TODO it'd be nice to put some proper logging in here.
            sleep($backoff_delay);
            if (--$retries <= 0) {
                die "Error connecting to API server, all retries used up: " . $li->status_line . "\n";
            }
            $backoff_delay *= 1.5; # poor man's exponential backoff
            $li = $harv->ListIdentifiers(%$params);
        }

        while ( my $rec = $li->next ) {
            my $sd = $callback->($rec);
            $shutdown ||= $sd;
        }
        if ( $li->is_error ) {
            return {
                $last_resumption_token ? ( resumptionToken => $last_resumption_token ) : (),
                error => $li->message,
            };
        } elsif ( !$shutdown ) {
            $last_resumption_token = $li->resumptionToken;
            $params                = { resumptionToken => $last_resumption_token->resumptionToken };
            sleep( $delay / 1000.0 ) unless !$delay || !$last_resumption_token;
        }
    } while ( !$shutdown && $li->is_success && $last_resumption_token );

    return {
        resumptionToken => $last_resumption_token ? $last_resumption_token->resumptionToken : undef,
        shutdownRequested => $shutdown,
    };
}

=head1 ATTRIBUTES

=head2 key

The API key provided by the Rijksmuseum.

=cut

has key => (
    is       => 'rw',
    required => 1,
);

=head1 AUTHOR

Robin Sheat, C<< <rsheat at cpan.org> >>

=head1 TODO

=over 4

=item Handle the ListRecords verb

This'll require writing a parser for EDM-DC or similar.

=back

=cut

=head1 BUGS

Please report any bugs or feature requests to C<bug-museum-rijksmuseum-object at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Museum-Rijksmuseum-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Alternately, use the tracker on the repository page at L<https://gitlab.com/eythian/museum-rijksmuseum-object>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Museum::Rijksmuseum::Object::Harvester


You can also look for information at:

=over 4

=item * Repository page (report bugs here)

L<https://gitlab.com/eythian/museum-rijksmuseum-object>

=item * RT: CPAN's request tracker (or here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Museum-Rijksmuseum-Object>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Museum-Rijksmuseum-Object>

=item * Search CPAN

L<https://metacpan.org/release/Museum-Rijksmuseum-Object>


=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Robin Sheat.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
