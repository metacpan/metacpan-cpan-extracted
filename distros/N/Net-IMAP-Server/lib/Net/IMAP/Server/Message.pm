package Net::IMAP::Server::Message;

use warnings;
use strict;
use bytes;

use Email::Address;
use Email::MIME;
use Email::MIME::ContentType;
use Regexp::Common qw/balanced/;
use DateTime;

use DateTime::Format::Strptime;
use DateTime::Format::Mail;
use constant INTERNALDATE_PARSER => DateTime::Format::Strptime->new(pattern => "%e-%b-%Y %T %z");
use constant HEADERDATE_PARSER => DateTime::Format::Mail->new->loose;

# Canonical capitalization
my %FLAGS;
$FLAGS{ lc $_ } = $_ for qw(\Answered \Flagged \Deleted \Seen \Draft);

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(
    qw(sequence mailbox uid _flags mime expunged));

=head1 NAME

Net::IMAP::Server::Message - Represents a message stored in a user's mailbox

=head1 METHODS

=head2 new STR

Creates a new message, from an RFC2822 string.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->mime( Email::MIME->new(@_) ) if @_;
    $self->internaldate( DateTime->now( time_zone => 'local' ) );
    $self->_flags( {} );
    return $self;
}

=head2 mailbox [MAILBOX]

Gets or sets the L<Net::IMAP::Server::Mailbox> that this message is
in.

=head2 sequence [INTEGER]

Gets or sets the sequence number of this message in its mailbox.
Note, however, that due to the semi-transactional nature of IMAP,
different connections may see a message as having different sequence
numbers!  The sequence number stored on the message is the sequence
number that a new connection would see; to find out what a connection
believes the sequence number of a message to be, use
L<Net::IMAP::Server::Connection/sequence>.

=head2 uid [INTEGER]

Gets or sets the UID of the message.  This, paired with the name and
UIDVALIDITY of its mailbox, is a unique designator of the message.

=head2 internaldate [STRING or DATETIME]

Gets or sets the string representing when the message was received by
the server.  According to RFC specification, this must be formatted as
C<01-Jan-2008 15:42:00 -0500> if it is a C<STRING>.

=cut

sub internaldate {
    my $self = shift;
    return $self->{internaldate} unless @_;
    my $value = shift;

    my $dt = ref $value ? $value : $self->INTERNALDATE_PARSER->parse_datetime($value);
    return undef unless $dt;

    $self->{internaldate} = $dt->strftime("%e-%b-%Y %T %z");
    $dt->truncate( to => "day" );
    $dt->set_time_zone( "floating" );
    $dt->set_time_zone( "UTC" );
    $self->{epoch_day_utc} = $dt->epoch;
    return $self->{internaldate};
}

=head2 epoch_day_utc

Returns the epoch time of the L</internaldate>, ignoring times and
time zones.  This is almost certainly only useful for C<SEARCH BEFORE>
and friends.

=cut

sub epoch_day_utc {
    my $self = shift;
    return $self->{epoch_day_utc};
}

=head2 date

Returns the Date header of the message, as a L<DateTime> object.
Returns undef if the date cannot be parsed.

=cut

sub date {
    my $self = shift;
    my $date = $self->mime_header->header("Date");
    return unless $date;

    return eval {
        $self->HEADERDATE_PARSER->parse_datetime(
            $date
        )
    };
}

=head2 date_day_utc

Similar to L</epoch_day_utc>, but for the L</date> header.  That is,
it returns the Date header, having stripped off the timezone and time.
Returns undef if the Date header cannot be parsed.

=cut

sub date_day_utc {
    my $self = shift;
    my $date = $self->date;
    return unless $date;

    $date->truncate( to => "day" );
    $date->set_time_zone( "floating" );
    $date->set_time_zone( "UTC" );
    return $date;
}

=head2 expunge

Marks the message as expunged -- this is called by
L<Net::IMAP::Server::Mailbox/expunge>, which deals with actually
removing the message from the appropriate places..

=cut

sub expunge {
    my $self = shift;
    $self->expunged(1);
}

=head2 expunged

Returns true if the message has been marked as "to be expunged" by
L</expunge>.

=head2 copy_allowed MAILBOX

Returns true if copying this message to the given
L<Net::IMAP::Server::Mailbox> C<MAILBOX> is allowed.  By default,
always returns true;

=cut

sub copy_allowed {
    return 1;
}

=head2 copy MAILBOX

Copies the message into the given L<Net::IMAP::Server::Mailbox>
C<MAILBOX>, and returns the new message.

=cut

sub copy {
    my $self    = shift;
    my $mailbox = shift;

    my $clone = bless {}, ref $self;
    $clone->mime( $self->mime );    # This leads to sharing the same MIME
                                    # object, but since they're
                                    # immutable, I don't think we care
    $clone->internaldate( $self->internaldate );    # Ditto for the date
    $clone->_flags( {} );
    $clone->set_flag( $_, 1 ) for ( '\Recent', $self->flags );

    $mailbox->add_message($clone);

    return $clone;
}

=head2 session_flags

Returns the names of flags that are stored per-session.  Defaults to
only the C<\Recent> flag.

=cut

sub session_flags {
    return ('\Recent');
}

sub _session_flags {
    my $self = shift;
    my $conn = Net::IMAP::Server->connection;
    return {} unless $conn;
    return $conn->_session_flags->{$self} ||= {};
}

=head2 set_flag FLAG [, SILENT]

Sets the given flag on the message; if a true value is passed for
C<SILENT>, mailboxes will not send notification of the change to the
client.  Returns the old value.

=cut

sub set_flag {
    my $self = shift;
    my ( $flag, $silent ) = @_;
    $flag = $FLAGS{ lc $flag } || $flag;

    my $hash = (grep $flag eq $_, $self->session_flags) ? $self->_session_flags : $self->_flags;

    my $old = exists $hash->{$flag};
    $hash->{$flag} = 1;

    my $changed = not $old;
    if ( $changed and not $silent ) {
        for my $c (
            Net::IMAP::Server->concurrent_mailbox_connections(
                $self->mailbox
            )
            )
        {
            $c->_unsent_fetch->{ $c->sequence($self) }{FLAGS}++
                unless $c->ignore_flags;
        }
    }

    return $changed;
}

=head2 clear_flag FLAG [, SILENT]

Clears the given flag on the message; if a true value is passed for
C<SILENT>, mailboxes will not send notification of the change to the
client.  Returns the old value.

=cut

sub clear_flag {
    my $self = shift;
    my ( $flag, $silent ) = @_;
    $flag = $FLAGS{ lc $flag } || $flag;

    my $hash = (grep $flag eq $_, $self->session_flags) ? $self->_session_flags : $self->_flags;

    my $old = exists $hash->{$flag};
    delete $hash->{$flag};

    my $changed = $old;
    if ( $changed and not $silent ) {
        for my $c (
            Net::IMAP::Server->concurrent_mailbox_connections(
                $self->mailbox
            )
            )
        {
            $c->_unsent_fetch->{ $c->sequence($self) }{FLAGS}++
                unless $c->ignore_flags;
        }
    }

    return $changed;
}

=head2 has_flag FLAG

Returns true if the message has the given flag set.

=cut

sub has_flag {
    my $self = shift;
    my $flag = shift;
    $flag = $FLAGS{ lc $flag } || $flag;

    my $hash = (grep $flag eq $_, $self->session_flags) ? $self->_session_flags : $self->_flags;

    return exists $hash->{$flag};
}

=head2 flags

Returns the list of flags which are set on the message.

=cut

sub flags {
    my $self = shift;
    my %flags = ( %{ $self->_flags }, %{ $self->_session_flags } );
    return sort keys %flags;
}

=head2 store STRING FLAGS

Sets the given C<FLAGS>, which should be an array reference, on the
message.  C<STRING> should be C<+FLAGS>, C<-FLAGS>, or C<FLAGS>; the
first sets the set of flags, the second unsets the set of flags, and
the third changes the message's flags to exactly match the given set.

=cut

sub store {
    my $self = shift;
    my ( $what, $flags ) = @_;
    my @flags = @{$flags};
    if ( $what =~ /^-/ ) {
        $self->clear_flag($_) for grep { $self->has_flag($_) } @flags;
    } elsif ( $what =~ /^\+/ ) {
        $self->set_flag($_) for grep { not $self->has_flag($_) } @flags;
    } else {
        $self->set_flag($_) for grep { not $self->has_flag($_) } @flags;
        $self->clear_flag($_) for grep {
            $a = $_;
            not grep { lc $a eq lc $_ } @flags
        } $self->flags;
    }
}

=head2 mime_header

Returns the L<Email::Simple::Header> of the message.

=cut

sub mime_header {
    my $self = shift;
    return $self->mime->header_obj;
}

=head2 mime [OBJ]

Gets or sets the L<Email::MIME> object for this message.

=cut

=head2 fetch SPEC

Takes C<SPEC>, which is either a string or an array reference of
strings, and returns a list of strings or data structures which match
the specification.  The specification is defined by section 7.4.2 of
RFC 3501.

=cut

sub fetch {
    my $self = shift;
    my $spec = shift;

    $spec = [qw/FLAGS INTERNALDATE RFC822.SIZE ENVELOPE/]
        if uc $spec eq "ALL";
    $spec = [qw/FLAGS INTERNALDATE RFC822.SIZE/] if uc $spec eq "FAST";
    $spec = [qw/FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY/]
        if uc $spec eq "FULL";

    my @parts = ref $spec ? @{$spec} : $spec;

    # Look if this will change the \Seen flag
    if ( grep { $_ =~ /^BODY\[/i } @parts and not $self->has_flag('\Seen') ) {

        # If so, update, and possibly also inform the user; do it
        # "silently" because we'll report the FLAGS change ourselves
        $self->set_flag('\Seen', 1);
        unshift @parts, "FLAGS" if not grep { uc $_ eq "FLAGS" } @parts;
    }

    my @out;
    for my $part (@parts) {
        push @out, \( uc $part );

        # Now that we've split out the right tag, do some aliasing
        if ( uc $part eq "RFC822" ) {
            $part = "BODY[]";
        } elsif ( uc $part eq "RFC822.HEADER" ) {
            $part = "BODY.PEEK[HEADER]";
        } elsif ( uc $part eq "RFC822.TEXT" ) {
            $part = "BODY[TEXT]";
        }

        if ( uc $part eq "UID" ) {
            push @out, $self->uid;
        } elsif ( uc $part eq "INTERNALDATE" ) {
            push @out, $self->internaldate;
        } elsif ( $part
            =~ /^BODY(?:\.PEEK)?\[(.*?)(?:\s+\((.*?)\))?\](?:<(\d+)(?:\.(\d+))>)?$/i
            )
        {
            push @out,
                $self->mime_select( [ split /\./, $1 ],
                $3, $4, [ split ' ', ( $2 || "" ) ] );
            ${ $out[-2] } =~ s/^BODY\.PEEK/BODY/i;
        } elsif ( uc $part eq "FLAGS" ) {
            push @out, [ map { \$_ } $self->flags ];
        } elsif ( uc $part eq "RFC822.SIZE" ) {
            push @out, length $self->mime_select( [], undef, undef );
        } elsif ( uc $part eq "BODY" ) {
            push @out, $self->mime_bodystructure( 0 );
        } elsif ( uc $part eq "BODYSTRUCTURE" ) {
            push @out, $self->mime_bodystructure( 1 );
        } elsif ( uc $part eq "ENVELOPE" ) {
            push @out, $self->mime_envelope;
        } else {
            pop @out;
        }
    }
    return @out;
}

=head2 mime_select SECTIONS [, START [, END [, EXTRA]]]

This method is generally only used internally by L</fetch>.

C<SECTIONS> should be an array reference of indexes into MIME parts,
or pulled from the set of strings: C<HEADER>, C<MIME>, C<FIELDS>,
C<TEXT>.  C<START> and C<END> determine which bytes of the resulting
content to send.  C<EXTRA> is used only for C<FIELDS>, and supplies
the names of headers to fetch.

=cut

sub mime_select {
    my $self = shift;
    my ( $sections, $start, $end, $extras ) = @_;

    my $mime;

    my @sections = @{$sections || []};
    my $result;
    $result = $self->mime->as_string unless @sections;
    for (@sections) {
        if ( uc $_ eq "HEADER" or uc $_ eq "MIME" ) {
            $result = ( $mime ? $mime->header_obj : $self->mime_header )
                ->as_string . "\r\n";
        } elsif ( uc $_ eq "FIELDS" ) {
            my %case;
            my $mime_header = $mime ? $mime->header_obj : $self->mime_header;
            $case{ uc $_ } = $_ for $mime_header->header_names;
            my $copy = Email::Simple::Header->new("");
            for my $h ( @{$extras || []} ) {
                $copy->header_set( $case{$h}
                        || $h => $mime_header->header_raw($h) );
            }
            $result = $copy->as_string ? $copy->as_string . "\r\n" : "";
        } elsif ( uc $_ eq "TEXT" ) {
            $mime ||= $self->mime;
            $result = $mime->body_raw;
        } elsif ( $_ =~ /^\d+$/i ) {
            $mime ||= $self->mime;
            my @parts = $mime->parts;
            $mime   = $parts[ $_ - 1 ];
            $result = $mime->body_raw;
        }
    }

    return $result unless defined $start;
    return "" if $start > length $result;
    return substr( $result, $start ) unless defined $end;
    return substr( $result, $start, $end );
}

=head2 mime_bodystructure [LONG [, MIME]]

Returns a string describing the MIME body structure of the message.

=cut

sub mime_bodystructure {
    my $self = shift;
    my ( $long, $mime ) = @_;
    $mime ||= $self->mime;
    my $mime_header = $mime->header_obj;

    # Grab the content type
    my $data = parse_content_type( $mime->content_type );

    # And the content disposition
    my $dis_header = $mime_header->header("Content-Disposition");
    my ( $attrs, $disposition );
    if ($dis_header) {

        # Ugly hack.  Culled from Email::MIME::Modifier
        ($disposition) = ( $dis_header =~ /^([^;]+)/ );
        $dis_header =~ s/^$disposition(?:;\s*)?//;
        $attrs = Email::MIME::ContentType::_parse_attributes($dis_header);
    }

    if ( $data->{discrete} eq "multipart" ) {

        # The first element is a bunch of lists, which looks like
        # (...)(...) -- note the lack of space!  RFC 3501, how do we
        # hate thee.  Make the mime structures, hack them into the
        # IMAP format, concat them, and insert their reference so they
        # get spat out as-is.
        my @parts = $mime->parts;
        @parts = () if @parts == 1 and $parts[0] == $mime;
        my $parts = join '', map {
            Net::IMAP::Server::Command->data_out(
                $self->mime_bodystructure( $long, $_ ) )
        } @parts;

        return [
            $parts ? \$parts : undef,
            $data->{composite},
            (   $long
                ? ( (   %{ $data->{attributes} }
                        ? [ %{ $data->{attributes} } ]
                        : undef
                    ),
                    (   $disposition
                        ? [ $disposition,
                            ( $attrs && %{$attrs} ? [ %{$attrs} ] : undef ),
                            ]
                        : undef
                    ),
                    scalar $mime_header->header_raw("Content-Language"),
                    scalar $mime_header->header_raw("Content-Location"),
                    )
                : ()
            ),
        ];
    } else {
        my $lines;
        my $body = $mime->body_raw;
        if ( lc $data->{discrete} eq "text" ) {
            $lines = 0;
            $lines++ while $body =~ /\n/g;
        }
        return [
            $data->{discrete},
            $data->{composite},
            (   %{ $data->{attributes} }
                ? [ %{ $data->{attributes} } ]
                : undef
            ),
            scalar $mime_header->header_raw("Content-ID"),
            scalar $mime_header->header_raw("Content-Description"),
            ( scalar $mime_header->header_raw("Content-Transfer-Encoding") or "7BIT" ),
            length $body,
            (   defined $lines
                ? ( $lines, )
                : ()
            ),
            (   $long
                ? ( scalar $mime_header->header_raw("Content-MD5"),
                    (   $disposition
                        ? [ $disposition,
                            ( $attrs && %{$attrs} ? [ %{$attrs} ] : undef ),
                            ]
                        : undef
                    ),
                    scalar $mime_header->header_raw("Content-Language"),
                    scalar $mime_header->header_raw("Content-Location"),
                    )
                : ()
            ),
        ];
    }
}

=head2 address_envelope HEADER

Returns a data structure defining the email addresses listed in the
given C<HEADER>.  This is used internally by L</mime_envelope>.

=cut

sub address_envelope {
    my $self   = shift;
    my $header = shift;
    my $mime_header = $self->mime_header;

    return undef unless $mime_header->header($header);
    return [
        map {
            [   { type => "string", value => $_->name },
                undef,
                { type => "string", value => $_->user },
                { type => "string", value => $_->host }
            ]
            } Email::Address->parse( $mime_header->header_raw($header) )
    ];
}

=head2 mime_envelope

Returns a data structure defining properties of significant header
fields.  This is used internally by L</fetch>.

=cut

sub mime_envelope {
    my $self = shift;
    my $mime_header = $self->mime_header;

    return [
        scalar $mime_header->header_raw("Date"),
        scalar $mime_header->header_raw("Subject"),

        $self->address_envelope("From"),
        $self->address_envelope(
            $mime_header->header("Sender") ? "Sender" : "From"
        ),
        $self->address_envelope(
            $mime_header->header("Reply-To") ? "Reply-To" : "From"
        ),
        $self->address_envelope("To"),
        $self->address_envelope("Cc"),
        $self->address_envelope("Bcc"),

        scalar $mime_header->header_raw("In-Reply-To"),
        scalar $mime_header->header_raw("Message-ID"),
    ];
}

=head2 prep_for_destroy

Called by the mailbox before the message is torn down; breaks down any
circular references.

=cut

sub prep_for_destroy {
    my $self = shift;
    $self->mailbox(undef);
}

1;
