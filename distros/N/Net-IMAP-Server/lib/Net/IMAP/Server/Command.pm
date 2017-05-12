package Net::IMAP::Server::Command;

use warnings;
use strict;
use bytes;

use base 'Class::Accessor';
use Regexp::Common qw/delimited balanced/;
__PACKAGE__->mk_accessors(
    qw(server connection command_id options_str command _parsed_options _literals _pending_literal)
);

=head1 NAME

Net::IMAP::Server::Command - A command in the IMAP server

=head1 DESCRIPTION

Commands the IMAP server knows about should be subclasses of this.
They will want to override the L</validate> and L</run> methods.

=head1 METHODS

=head2 new

Called by the connection to create a new command.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->_parsed_options( [] );
    $self->_literals(       [] );
    return $self;
}

=head2 server

Gets or sets the L<Net::IMAP::Server> associated with this command.

=cut

=head2 connection

Gets or sets the L<Net::IMAP::Server::Connection> associated with this
command.

=cut

=head2 validate

Called before the command is run.  If it returns a false value, the
command is not run; it will probably want to inspect
L</parsed_options>.  If C<validate> returns a false value, it is
responsible for calling L</no_command> or L</bad_command> to notify
the client of the failure.  Handily, these return a false value.

=cut

sub validate {
    return 1;
}

=head2 run

Does the guts of the command.  The return value is ignored; the
command is in charge of eventually sending one of L</ok_command>,
L</bad_command>, or L</no_command> to the client.

The default implementation simply always response with
L</bad_command>.

=cut

sub run {
    my $self = shift;

    $self->bad_command( "command '" . uc($self->command) . "' not recognized" );
}

=head2 has_literal

Analyzes the options line, and returns true if the line has literals
(as defined in the RFC, a literal is of the form C<{42}>).  If the
line has literals, installs a L<Net::IMAP::Server::Connection/pending>
callback to continue the parsing, and returns true.

=cut

sub has_literal {
    my $self = shift;
    unless ( $self->options_str =~ /\{(\d+)(\+)?\}[\r\n]*$/ ) {
        $self->parse_options;
        return;
    }

    my $options = $self->options_str;
    my $next    = $#{ $self->_literals } + 1;
    $options =~ s/\{(\d+)(\+)?\}[\r\n]*$/{{$next}}/;
    $self->_pending_literal($1);
    $self->options_str($options);

    # Pending
    $self->connection->pending(
        sub {
            my $content = shift;
            if ( length $content <= $self->_pending_literal ) {
                $self->_literals->[$next] .= $content;
                $self->_pending_literal(
                    $self->_pending_literal - length $content );
            } else {
                $self->_literals->[$next]
                    .= substr( $content, 0, $self->_pending_literal, "" );
                $self->connection->pending(undef);
                $self->options_str( $self->options_str . $content );
                return     if $self->has_literal;
                $self->run if $self->validate;
            }
        }
    );
    $self->out("+ Continue") unless $2;
    return 1;
}

=head2 parse_options

Parses the options, and puts the results (which may be a data
structure) into L<parsed_options>.

=cut

sub parse_options {
    my $self = shift;
    my $str  = shift;

    return $self->_parsed_options
        if not defined $str and not defined $self->options_str;

    my $to_parse = defined $str ? $str : $self->options_str;

    my $token = qr/^($RE{delimited}{-delim=>'"'}{-esc=>'\\'}
                    |$RE{balanced}{-parens=>'()'}
                    |\S+$RE{balanced}{-parens=>'()[]<>'}
                    |\S+)\s*/x;

    my @parsed;
    while ($to_parse =~ s/$token//) {
        my $term = $1;
        if ( $term =~ /^$RE{delimited}{-delim=>'"'}{-esc=>'\\'}{-keep}$/ ) {
            my $value = $3;
            $value =~ s/\\([\\"])/$1/g;
            push @parsed, $value;
        } elsif ( $term =~ /^$RE{balanced}{-parens=>'()'}$/ ) {
            $term =~ s/^\((.*)\)$/$1/;
            push @parsed, [ $self->parse_options($term) ];
        } elsif ( $term =~ /^\{\{(\d+)\}\}$/ ) {
            push @parsed, $self->_literals->[$1];
        } else {
            push @parsed, $term;
        }
    }
    return @parsed if defined $str;

    $self->options_str(undef);
    $self->_parsed_options( [ @{ $self->_parsed_options }, @parsed ] );
}

=head2 command_id

Returns the (arbitrary) string that the client identified the command with.

=cut

=head2 parsed_options

Returns the list of options to the command.

=cut

sub parsed_options {
    my $self = shift;
    return @{ $self->_parsed_options(@_) };
}

=head2 options_str

Returns the flat string representation of the options the client gave.

=cut

=head2 data_out DATA

Returns a string representing the most probable IMAP string that
conveys the C<DATA>.

=over

=item *

Array references are converted into "parenthesized lists," and each
element is recursively output.

=item *

Scalar references are dereferenced and returned as-is.

=item *

C<undef> is output as C<NIL>.

=item *

Scalar values containing special characters are output as literals

=item *

Purely numerical scalar values are output with no change

=item *

All other scalar values are output within quotes.

=back

Since the IMAP specification contains nothing which is similar to a
hash, hash references are treated specially; specifically, the C<type>
key is taken to be how the C<value> key should be output.  Options for
C<type> are C<string> or C<literal>.

=cut

sub data_out {
    my $self = shift;
    my $data = shift;
    if ( ref $data eq "ARRAY" ) {
        return "(" . join( " ", map { $self->data_out($_) } @{$data} ) . ")";
    } elsif ( ref $data eq "SCALAR" ) {
        return $$data;
    } elsif ( ref $data eq "HASH" ) {
        if ( $data->{type} eq "string" ) {
            if ( $data =~ /[{"\r\n%*\\\[]/ ) {
                return "{" . ( length( $data->{value} ) ) . "}\r\n$data";
            } else {
                return '"' . $data->{value} . '"';
            }
        } elsif ( $data->{type} eq "literal" ) {
            return "{" . ( length( $data->{value} ) ) . "}\r\n$data";
        }
    } elsif ( not ref $data ) {
        if ( not defined $data ) {
            return "NIL";
        } elsif ( $data =~ /[{"\r\n%*\\\[]/ ) {
            return "{" . ( length($data) ) . "}\r\n$data";
        } elsif ( $data =~ /^\d+$/ ) {
            return $data;
        } else {
            return qq{"$data"};
        }
    }
    return "";
}

=head2 untagged_response STRING

Sends an untagged response to the client.

=cut

sub untagged_response {
    my $self = shift;
    $self->connection->untagged_response(@_);
}

=head2 tagged_response

Sends a tagged response to the client.

=cut

sub tagged_response {
    my $self = shift;
    $self->untagged_response( uc( $self->command ) . " $_" )
        for grep defined, @_;
}

=head2 poll_after

Returns a true value if the command should send untagged updates about
the selected mailbox after the command completes.  Defaults to always
true.

=cut

sub poll_after {1}

=head2 send_untagged

Sends untagged updates about the currently selected inbox to the
client using L<Net::IMAP::Server::Connection/send_untagged>, but only
if the command has a true L</poll_after>.

=cut

sub send_untagged {
    my $self = shift;
    $self->connection->send_untagged(@_) if $self->poll_after;
}

=head2 ok_command MESSAGE [, RESPONSECODE => STRING, ...]

Sends untagged OK responses for any C<RESPONSECODE> pairs, then
outputs untagged messages via L</send_untagged>, then sends a tagged
OK with the given C<MESSAGE>.

=cut

sub ok_command {
    my $self            = shift;
    my $message         = shift;
    my %extra_responses = (@_);
    for ( keys %extra_responses ) {
        $self->untagged_response(
            "OK [" . uc($_) . "] " . $extra_responses{$_} );
    }
    $self->send_untagged;
    $self->out( $self->command_id . " OK $message" );
    return 1;
}

=head2 ok_completed [RESPONSECODE => STRING]

Sends an C<OK COMPLETED> tagged response to the client.

=cut

sub ok_completed {
    my $self            = shift;
    my %extra_responses = (@_);
    $self->ok_command( uc( $self->command ) . " COMPLETED",
        %extra_responses );
}

=head2 no_command MESSAGE [, RESPONSECODE => STRING, ...]

Sends untagged NO responses for any C<RESPONSECODE> pairs, then
outputs untagged messages via L</send_untagged>, then sends a tagged
OK with the given C<MESSAGE>.

=cut

sub no_command {
    my $self            = shift;
    my $message         = shift;
    my %extra_responses = (@_);
    for ( keys %extra_responses ) {
        $self->untagged_response(
            "NO [" . uc($_) . "] " . $extra_responses{$_} );
    }
    $self->out( $self->command_id . " NO $message" );
    return 0;
}

=head2 bad_command REASON

Sends any untagged updates to the client using L</send_untagged>, then
sends a tagged C<BAD> response with the given C<REASON>.

=cut

sub bad_command {
    my $self   = shift;
    my $reason = shift;
    $self->send_untagged;
    $self->out( $self->command_id . " BAD $reason" );
    return 0;
}

=head2 valid_mailbox NAME

Returns false and calls L</bad_command> if the given C<NAME> is a valid
name for a mailbox.  This only checks that is passes UTF-7 encoding
checks, and that it contains no 8-bit characters.  If the name is valid,
simply returns 1.

=cut

sub valid_mailbox {
    my $self = shift;
    my ($name) = @_;

    # Check for high-bit characters
    return $self->bad_command("Mailbox name contains 8-bit data")
        if $name =~ /[\x80-\xFF]/;

    # This both ensures that the mailbox path is valid UTF-7, and that
    # there aren't bogusly encoded characters (like '/' -> '&AC8-')
    my $roundtrip = eval {
        Encode::encode( 'IMAP-UTF-7',
            Encode::decode( 'IMAP-UTF-7', $name ) );
    };
    return $self->bad_command("Invalid UTF-7 encoding")
        unless defined $roundtrip and $roundtrip eq $name;

    return 1;
}

=head2 log SEVERITY, MESSAGE

Defers to L<Net::IMAP::Server::Connection/log>.

=cut

sub log {
    my $self = shift;
    $self->connection->log(@_);
}

=head2 out MESSAGE

Identical to L<Net::IMAP::Server::Connection/out>.

=cut

sub out {
    my $self = shift;
    $self->connection->out(@_);
}

1;
