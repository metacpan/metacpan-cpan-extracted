package TL1ng::Parser;

use strict;
use warnings;

our $VERSION = '0.07';

use Time::Local;

=pod

=head2 new

Simply creates a parser object so that the methods can be called on it.

  my $tl1_parser = new TL1ng::Parser;

=cut

sub new { bless {}, shift }

=pod

=head2 parse_string

Parses a scalar string containing the lines of a TL1 message (as returned 
by $tl1->_read_msg()) and returns a reference to a hash-based data structure 
representing the TL1 data fields for that message.

 my $msg = $self->parse_string($lines);

If the parsing fails somewhere along the line, whatever we've already done 
will be returned in the $msh hash and the 'success' hash entry will be missing. 
Also, an 'error' hash entry may be set.

=cut

sub parse_string {
    my $self        = shift;
    my $lines       = shift || return;
    my $lines_array = [];

    # Unnecessary w/ the || return above, but I may get rid of that.
    unless ($lines) {
        return { error => "Message was empty" };
    }

    # Save all non-blank lines as an array of lines.
    # Return what we got if there are no lines to work with.
    unless ( $lines_array = [ grep !/^\s*$/, split "\n", $lines ] ) {
        return { error => "Message contained no non-blank lines" };
    }

    return $self->_process_msg($lines_array);

}

=head2 parse_array

Just like parse_string(), but it's arguments are a list of strings 
containing the lines of the TL1 message. See parse_string() for more info.

 my $msg = $self->parse_array(@lines);


=cut

sub parse_array { shift->parse_string( join( '', @_ ) ) }

=head2 parse_arrayref

Just like parse_string(), but it's argument is a reference to an array
of strings containing the lines of the TL1 message. 
See parse_string() for more info.

 my $msg = $self->parse_arrayref(\@lines);


=cut

sub parse_arrayref { shift->parse_string( join( '', @{ +shift } ) ) }

=pod

=head2 _process_msg

See parse_string() and parse_array() above. Is called by those methods.
It's argument should be a reference to an array of strings.

 my $msg = $self->_process_msg($msg);


=cut

sub _process_msg {
    my $self = shift;
    my $msg  = {};

    $msg->{lines} = shift;

    # Use the first line of the message to determine the message type.
    # Return what we got if something's funny.
    unless ( $msg->{type} = $self->_match_msg_type( $msg->{lines} ) ) {
        $msg->{error} = "Error trying to determine message type";
        return $msg;
    }

    # Process the data depending on the type.
    my $stat;    # Not used, but may be nice to have someday.
    $stat = $self->_process_unk_msg($msg) if $msg->{type} eq 'UNK';
    $stat = $self->_process_ack_msg($msg) if $msg->{type} eq 'ACK';
    $stat = $self->_process_cmd_msg($msg) if $msg->{type} eq 'CMD';
    $stat = $self->_process_aut_msg($msg) if $msg->{type} eq 'AUT';

    # If nothing went wrong in processing, success!
    $msg->{success} = 1 unless $msg->{error} or !$stat;

    # Once again, return what we got :)
    return $msg;
}

=pod

=head2 _process_ack_msg

Parses the header and any data lines of a TL1 Command Acknowledgement message 
(stored in the $msg->{lines}) to populate the appropriate fields in the 
$msg data structure.

 my $status = $self->_process_ack_msg($msg);

=cut

sub _process_ack_msg {
    my $self = shift;
    my $msg  = shift;
    if ( $msg->{lines}[0] =~ /^(\w{2}) (\S+)/ ) {
        $msg->{ack_code} = $1;
        $msg->{CTAG}     = $2;
        $msg->{header}   = $msg->{lines}[0];
    }
    else {
        $msg->{error} = "Could not parse acknowledgement message header";
        return;
    }

    # If all went well above, finish up the parsing!
    my $FISRT_DATA_LINE = 1;
    return $self->_parse_msg_data( $msg, $FISRT_DATA_LINE );
}

=pod

=head2 _process_cmd_msg

Parses the header and any data lines of a TL1 Command Response message 
(stored in the $msg->{lines}) to populate the appropriate fields in the 
$msg data structure.

 my $status = $self->_process_cmd_msg($msg);

=cut

sub _process_cmd_msg {
    my $self = shift;
    my $msg  = shift;
    $self->_parse_msg_header($msg) || return;

    # Parse message identifier line:
    if ( $msg->{lines}[1] =~ /^M  (\S+) (\S+)/ ) {
        $msg->{CTAG}          = $1;
        $msg->{response_code} = $2;
        $msg->{identifier}    = $msg->{lines}[1];
    }
    else {
        $msg->{error} = "Could not parse command response identifier line";
        return;
    }

    # If all went well above, finish up the parsing!
    my $FISRT_DATA_LINE = 2;
    return $self->_parse_msg_data( $msg, $FISRT_DATA_LINE );
}

=pod

=head2 _process_aut_msg

Parses the header and any data lines of a TL1 Autonomous Response message 
(stored in the $msg->{lines}) to populate the appropriate fields in the 
$msg data structure.

 my $status = $self->_process_aut_msg($msg);

=cut

sub _process_aut_msg {
    my $self = shift;
    my $msg  = shift;
    $self->_parse_msg_header($msg) || return;

    # Parse message identifier line:
    if ( $msg->{lines}[1] =~ /^(\S.) (\S+) (\S+)\s*(.*)/ ) {
        $msg->{alarm_code} = $1;
        $msg->{ATAG}       = $2;
        $msg->{verb}       = $3;
        $msg->{modifiers}  = [ $4 ? ( split ' ', $4 ) : '' ];

        $msg->{alarm_code} =~ s/\s//g;    # Clean up alarm code.
        $msg->{identifier} = $msg->{lines}[1];
    }
    else {
        $msg->{error} = "Could not parse autonomous response identifier line";
        return;
    }

    # If all went well above, finish up the parsing!
    my $FISRT_DATA_LINE = 2;
    return $self->_parse_msg_data( $msg, $FISRT_DATA_LINE );
}

=pod

=head2 _process_unk_msg

For messages handling where the type is unknown. Right now this method 
simply sets an error in the $msg data structure and then returns true.

 my $status = $self->_process_unk_msg($msg);

=cut

sub _process_unk_msg {
    my $self = shift;
    my $msg  = shift;
    $msg->{error} =
      "Message is an unknown type - processing is probably useless";
    return 1;
}

=pod

=head2 _parse_msg_data

Parses out the data payload and comments from a TL1 message and populates the
fields in the $msg data structure. Returns true on success. If parsing fails, 
sets an "error" field in $msg and returns false. The first parameter is a 
reference to the $msg data structure. The second is the index of the position
in the $msg->{lines} array where the headers end and the data begins. This is
done because different types of messages have a different number of header 
lines and I decided to avoid putting that intelligence in a method that could
probably be used elsewhere.

 my $FISRT_DATA_LINE = 2;
 my $status = $tl1->_parse_msg_data($msg, $FISRT_DATA_LINE);

THIS METHOD PROBABLY NEEDS WORK - IT'S MESSY AND A LITTLE CONFUSING!!!

=cut

sub _parse_msg_data {
    my $self = shift;
    my $msg  = shift;

    my $begin = shift;                     #First data line
    my $end   = @{ $msg->{lines} } - 2;    # Calculate the last data line
                                           # (-2 because of the terminator line)

    return 1 if $begin > $end;             # If this is the case, there are
                                           # no data lines to parse

    # The order of these regexes is important to get the correct result.
    # I'd bet some hacker out there could do it in a single expression,
    # But this works and I can grok it without too much effort.
    {

        # Parsing with regexes will be easier if I concatenate all the lines
        my $data = join "\n", @{ $msg->{lines} }[ $begin .. $end ];

        # Clean up leading and trailing whitespace...
        $data =~ s/^\s+|\s+$//mg;

        # Clean up any empty lines
        $data =~ s/^$//sg;

        {

            # Parse out and save comment lines
            my $com_re =
              qr/^\s*\/\*((?s)\s*(.*?)\s*)\*\/\s*$/;    # Reusable regex!
            push( @{ $msg->{comment_lines} }, $+ ) while $data =~ /$com_re/mg;

            # Since comments are now saved, delete them.
            # They don't belong in the payload.
            $data =~ s/$com_re//mg;
        }

        # Clean up escaped quoting
        $data =~ s/\\"/"/g if $data =~ s/^"(.*)"$/$1/mg;

        # Store the payload
        $msg->{payload_lines} = [ ( $self->_split_quoted( '\n', $data ) ) ];
    }

    # Split the payload data lines into sections and fields and
    # store those in the $msg
    $self->_parse_payload_lines($msg);

    return 1;

    # Perhaps the above code *would* be better by looping over the lines?
    # The world may never know, 'cause the code above works for me :)
    # However, I *do* have a strong urge to try this - I just need an excuse!
    #
    # foreach my $line (@{$msg->{lines}[$begin..$end]}) {
    #
    # }
}

=pod

=head2 _parse_payload_lines

Parse the payload data lines into 'fields' delimited by : and 'sections' 
delimited by , and save the results in an array of arrays in $msg->{payload}

The AoAoA structure reflects:
 $payload[]  = @lines
 $lines[]    = @sections
 $sections[] = @fields

Usage:

 my $status = $self->_parse_payload_lines($msg);

=cut

sub _parse_payload_lines {
    my $self = shift;
    my $msg  = shift;

    return unless @{ $msg->{payload_lines} };    # No lines available?
    my @lines;
    foreach my $line ( @{ $msg->{payload_lines} } ) {
        my @sections;

        # Split the line into "Sections", delimited by : (colon)
        #my @splitline = @{$self->_split_quoted('\:',$line)};
        foreach my $section ( $self->_split_quoted( '\:', $line ) ) {

            # Split the section into "Fields", delimited by , (comma)
            my @fields = $self->_split_quoted( ',', $section );

            # Save the parsed data to the $msg.
            push @sections, \@fields;
        }
        push @lines, \@sections;
    }
    $msg->{payload} = \@lines;
    return 1;
}

=pod

=head2 _split_quoted

Splits a line on a delimiter, but ignores delimiters inside quotes...
This is the sort of thing that is useful for parsing CSV with quoted fields 
that may contain the delimiter. Takes two scalar arguments just like split()

 my $delim = ':';
 my $string = 'FAC-14-9:CL,RAI,NSA,,,,:"Remote Alarm Indication",DS1-14';
 my @fields = $self->_split_quoted($delim, $string);

=cut

sub _split_quoted {
    my $self   = shift;
    my $d      = shift;    # Delimiter
    my $string = shift;
    
    my $regex  = qr{
          # Capture text in quoted fields,
          # ignoring escaped quotes and embedded newlines
            (?:  ((?: (?: "(?: [^"] | (?<!\\)" )*")+[^$d]*)+)(?:$d|$) )
          # OR Capture text in un-quoted fields.
              | (?: ([^$d]+)(?:$d|$) )
          # OR Capture empty, zero-width fields
          # (Returns '')
              | (?: ()(?:$d) )
        }msx;
        
    my @fields = ();
    while ( $string =~ m/$regex/g ) {
        push( @fields, $+ ); # I don't know why this doesn't work with $1 :-(
    }

    # If the string ends with the delimiter,
    # we want to capture that as well.
    (my $d_clean = $d) =~ s/\\(.)/$1/g; # Collapse escaped chars first.
    my $d_len = length $d_clean;
    push( @fields, '' )
        if substr( $string, -$d_len, $d_len ) eq $d_clean;

    return @fields;
}

=pod

=head2 _parse_msg_header

Parses the header line of CMD and AUT response messages and populates the
apropriate fields of the $msg data structure. Returns true on success.
If parsing fails, sets an "error" field in $msg and returns false.

 my $status = $tl1->_parse_msg_header($msg);

=cut

sub _parse_msg_header {
    my $self = shift;
    my $msg  = shift;
    if ( $msg->{lines}[0] =~ /^\s{3}(\S+) (\S+) (\S+)/ ) {
        $msg->{SID}  = $1;
        $msg->{date} = $2;
        $msg->{time} = $3;
        $msg->{timestamp} =
          $self->_datetime2utcunix( $msg->{date}, $msg->{time} );
        $msg->{header} = $msg->{lines}[0];
    }
    else {
        $msg->{error} = "Could not parse response message header";
        return;
    }
    return 1;
}

=pod

=head2 _match_msg_type

Parse an array of lines composing a TL1 message to determine the type.
Return values can be one of:

 ACK - Acknowledgement of receipt of a command
 CMD - Response to a command
 AUT - Autonomous message (not in response to a command)
 UNK - Unknown. Probably bogus, non-standard, or my code messed up

Returns false if the lines array is empty or the header is incomplete.

 my $msg_type = $tl1->_match_msg_type(\@lines);
 
=cut

sub _match_msg_type {
    my $self = shift;
    my $lines = shift || return;    # Make sure we *got* a message!

    return unless ref $lines eq 'ARRAY';    # Make sure it's fer realz.
    return unless $lines->[0];              # If an empty message comes in.

    # ACK have a distinctive first line (often the *only* line)
    return 'ACK' if $lines->[0] =~ /^(\w{2}) (\S+)/;

    # CMD and AUT have the same first line, are differentiated by the second.
    # Therefore, if the first line doesn't look like this, something's wrong:
    return 'UNK' unless $lines->[0] =~ /^\s{3}(\S+) (\S+) (\S+)/;

    return unless $lines->[1];              # If an incomplete message comes in.

    return 'CMD' if $lines->[1] =~ /^M  (\S+) (\S+)/;
    return 'AUT' if $lines->[1] =~ /^(\S.) (\S+) (\S+)\s*(.*)/;

    return 'UNK';                           # Nothing else matched.
}

=pod

=head2 _datetime2utcunix

Timestamps in TL1 messages are formatted for human-readability, in the
form YYYY-MM-DD HH:mm:ss (hour is 0-23, no AM/PM)<br>
<br>
This method turns those text timestamps into programmer-friendly Unix 
timestamps adjusted to UTC (number of seconds since the Epoch at GMT/UTC)<br>
<br>
The first parameter is the TL1 date in YYYY-MM-DD, and the second parameter
is the TL1 time in HH:mm:ss. By default, this is assumed to be local time and 
so the returned Unix timestamp is adjusted to UTC. To prevent that (if, for 
example, your TL1 timestamps are already using UTC,) pass a third argument as 
any true value.

 my $utc_unix_time = $tl1->_datetime2utcunix($local_tl1_date, $local_tl1_time);
 
 my $NO_ADJ_TZ=1;
 my $utc_unix_time = $tl1->_datetime2utcunix($utc_tl1_date, $utc_tl1_time, $NO_ADJ_TZ);

=cut

sub _datetime2utcunix {
    my $self      = shift;
    my $date      = shift;
    my $time      = shift;
    my @timestuff = reverse( split( '-', $date ), split( ':', $time ) );
    s/^0+(.)/$1/ for @timestuff;  # Strip leading 0s, but be sure to leave at 
                                  # least one digit. (assuming it's a digit)
    $timestuff[4]--; # The Month element should be from 0 to 11.
    return timelocal(@timestuff) unless shift;
    return timegm(@timestuff);
}

1;

