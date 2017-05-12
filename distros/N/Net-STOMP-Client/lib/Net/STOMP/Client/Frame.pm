#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/Frame.pm                                              #
#                                                                              #
# Description: Frame support for Net::STOMP::Client                            #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::Frame;
use 5.005; # need the four-argument form of substr()
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Encode qw();
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::Log qw(log_debug);
use Params::Validate qw(validate validate_pos :types);

#
# constants
#

use constant I_COMMAND => 0;
use constant I_HEADERS => 1;
use constant I_BODY    => 2; # stored as reference

#
# global variables
#

our(
    # public
    $DebugBodyLength, # the maximum length of body that will be debugged
    $StrictEncode,    # true if encoding/decoding operations should be strict
    # private
    $_HeaderNameRE,   # regular expression matching a header name (STOMP 1.0)
    %_EncMap1,        # map to \-encode some chars in the header (STOMP 1.1)
    %_DecMap1,        # map to \-decode some chars in the header (STOMP 1.1)
    $_EncSet1,        # set of chars to encode in the header (STOMP 1.1)
    %_EncMap2,        # map to \-encode some chars in the header (STOMP >= 1.2)
    %_DecMap2,        # map to \-decode some chars in the header (STOMP >= 1.2)
    $_EncSet2,        # set of chars to encode in the header (STOMP >= 1.2)
);

# public
$DebugBodyLength = 256;
$StrictEncode = undef;

# private
$_HeaderNameRE = q/[_a-zA-Z0-9\-\.]+/;
%_EncMap1 = %_EncMap2 = (
    "\r" => "\\r",
    "\n" => "\\n",
    ":"  => "\\c",
    "\\" => "\\\\",
);
delete($_EncMap1{"\r"}); # \r encoding is only for STOMP >= 1.2
%_DecMap1 = reverse(%_EncMap1);
$_EncSet1 = "[".join("", map(sprintf("\\x%02x", ord($_)), keys(%_EncMap1)))."]";
%_DecMap2 = reverse(%_EncMap2);
$_EncSet2 = "[".join("", map(sprintf("\\x%02x", ord($_)), keys(%_EncMap2)))."]";

#+++############################################################################
#                                                                              #
# helpers                                                                      #
#                                                                              #
#---############################################################################

#
# helper to guess the encoding to use from the content type header
#

sub _encoding ($) {
    my($type) = @_;

    if ($type) {
        if ($type =~ /^text\/[\w\-]+$/) {
            return("UTF-8");
        } elsif (";$type;" =~ /\;\s*charset=\"?([\w\-]+)\"?\s*\;/) {
            return($1);
        } else {
            return(undef);
        }
    } else {
        return(undef);
    }
}

#
# debugging helpers
#

sub _debug_command ($$) {
    my($what, $command) = @_;

    log_debug("%s %s frame", $what, $command);
}

sub _debug_header ($) {
    my($header) = @_;
    my($offset, $length, $line, $char);

    $length = length($header);
    $offset = 0;
    while ($offset < $length) {
        $line = "";
        while (1) {
            $char = ord(substr($header, $offset, 1));
            $offset++;
            if ($char == 0x0a) {
                last;
            } elsif (0x20 <= $char and $char <= 0x7e and $char != 0x25) {
                $line .= sprintf("%c", $char);
            } else {
                $line .= sprintf("%%%02x", $char);
            }
            last if $offset == $length;
        }
        log_debug(" H %s", $line);
    }
}

sub _debug_body ($) {
    my($body) = @_;
    my($offset, $length, $line, $ascii, $char);

    $length = length($body);
    if ($DebugBodyLength and $length > $DebugBodyLength) {
        substr($body, $DebugBodyLength, $length - $DebugBodyLength, "");
        $length = $DebugBodyLength;
    }
    $offset = 0;
    while ($length > 0) {
        $line = sprintf("%04x", $offset);
        $ascii = "";
        foreach my $index (0 .. 15) {
            if (($index & 3) == 0) {
                $line  .= " ";
                $ascii .= " ";
            }
            if ($index < $length) {
                $char = ord(substr($body, $index, 1));
                $line  .= sprintf("%02x", $char);
                $ascii .= sprintf("%c", (0x20 <= $char && $char <= 0x7e) ?
                                  $char : 0x2e);
            } else {
                $line  .= "  ";
                $ascii .= " ";
            }
        }
        log_debug(" B %s %s", $line, $ascii);
        $offset += 16;
        $length -= 16;
        substr($body, 0, 16, "");
    }
}

#+++############################################################################
#                                                                              #
# object oriented interface                                                    #
#                                                                              #
#---############################################################################

#
# constructor
#
# notes:
#  - $self->[I_COMMAND] defaults to SEND so it's always defined
#  - $self->[I_HEADERS] defaults to {} so it's always set to a hash ref
#  - $self->[I_BODY] defaults to \"" so it's always set to a scalar ref
#

my %new_options = (
    "command" => {
        optional => 1,
        type     => SCALAR,
        regex    => qr/^[A-Z]{2,16}$/,
    },
    "headers" => {
        optional => 1,
        type     => HASHREF,
    },
    "body_reference" => {
        optional => 1,
        type     => SCALARREF,
    },
    "body" => {
        optional => 1,
        type     => SCALAR,
    },
);

sub new : method {
    my($class, %option, $object);

    if ($Net::STOMP::Client::NoParamsValidation) {
        ($class, %option) = @_;
    } else {
        $class = shift(@_);
        %option = validate(@_, \%new_options) if @_;
    }
    if (defined($option{"body"})) {
        # handle the convenient body option
        dief("options body and body_reference are " .
             "mutually exclusive") if $option{"body_reference"};
        $option{"body_reference"} = \ delete($option{"body"});
    }
    $option{"command"} ||= "SEND";
    $option{"headers"} ||= {};
    $option{"body_reference"} ||= \ "";
    $object = [ @option{ qw(command headers body_reference) } ];
    return(bless($object, $class));
}

#
# standard getters and setters
#

sub command : method {
    my($self, $value);

    $self = shift(@_);
    return($self->[I_COMMAND]) if @_ == 0;
    $value = $_[0];
    if (@_ == 1 and defined($value) and ref($value) eq ""
        and $value =~ $new_options{"command"}{"regex"}) {
        $self->[I_COMMAND] = $value;
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, $new_options{"command"});
}

sub headers : method {
    my($self, $value);

    $self = shift(@_);
    return($self->[I_HEADERS]) if @_ == 0;
    $value = $_[0];
    if (@_ == 1 and ref($value) eq "HASH") {
        $self->[I_HEADERS] = $value;
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, $new_options{"headers"});
}

sub body_reference : method {
    my($self, $value);

    $self = shift(@_);
    return($self->[I_BODY]) if @_ == 0;
    $value = $_[0];
    if (@_ == 1 and ref($value) eq "SCALAR") {
        $self->[I_BODY] = $value;
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, $new_options{"body_reference"});
}

#
# convenient body getter and setter
#

sub body : method {
    my($self, $value);

    $self = shift(@_);
    return(${ $self->[I_BODY] }) if @_ == 0;
    $value = $_[0];
    if (@_ == 1 and defined($value) and ref($value) eq "") {
        $self->[I_BODY] = \$value;
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, $new_options{"body"});
}

#
# convenient individual header getter and setter:
#  - $frame->header($key): get
#  - $frame->header($key, $value): set
#  - $frame->header($key, undef): delete
#

my @header_options = (
    { optional => 0, type => SCALAR },
    { optional => 1, type => SCALAR|UNDEF },
);

sub header : method {
    my($self, $key, $value);

    $self = shift(@_);
    $key = $_[0];
    if (defined($key) and ref($key) eq "") {
        if (@_ == 1) {
            # get
            return($self->[I_HEADERS]{$key});
        } elsif (@_ == 2) {
            $value = $_[1];
            if (defined($value)) {
                if (ref($value) eq "") {
                    # set
                    $self->[I_HEADERS]{$key} = $value;
                    return($self);
                }
            } else {
                # delete
                delete($self->[I_HEADERS]{$key});
                return($self);
            }
        }
    }
    # otherwise complain...
    validate_pos(@_, @header_options);
}

#+++############################################################################
#                                                                              #
# parsing                                                                      #
#                                                                              #
#---############################################################################

#
# parse the given buffer reference and return a hash of pointers to frame parts
# if the frame is complete or false otherwise; an optional hash can be given to
# represent state information from a previous parse on the exact same buffer
#
# note: for STOMP <1.2, we may miss a final \r in command or header as it would
# be part of the eol; up to the caller to be strict and check for its presence
# or to simply ignore this corner case for the sake of simplicity
#

my %parse_options = (
    state => { optional => 1, type => HASHREF },
);

sub parse ($@) {  ## no critic 'ProhibitExcessComplexity'
    my($bufref, %option, $state, $index, $buflen, $eol, $tmp);

    #
    # setup
    #
    if ($Net::STOMP::Client::NoParamsValidation) {
        ($bufref, %option) = @_;
    } else {
        validate_pos(@_, { type => SCALARREF }) unless ref($_[0]) eq "SCALAR";
        $bufref = shift(@_);
        %option = validate(@_, \%parse_options) if @_;
    }
    $state = $option{state} || {};
    #
    # before: allow 0 or more end-of-line characters
    # (note: we allow \n and \r\n but also \r as EOL, this should not be a
    #  problem in practice)
    #
    unless (exists($state->{before_len})) {
        return(0) unless ${$bufref} =~ /^[\r\n]*[^\r\n]/g;
        $state->{before_len} = pos(${$bufref}) - 1;
    }
    #
    # command: everything up to the first EOL
    #
    unless (exists($state->{command_len})) {
        $state->{command_idx} = $state->{before_len};
        $index = index(${$bufref}, "\n", $state->{command_idx});
        return(0) if $index < 0;
        $state->{command_len} = $index - $state->{command_idx};
        if (substr(${$bufref}, $index - 1, 1) eq "\r") {
            $state->{command_len}--;
            $state->{command_eol} = 2;
        } else {
            $state->{command_eol} = 1;
        }
    }
    #
    # header: everything up to the first double EOL
    #
    unless (exists($state->{header_len})) {
        $state->{header_idx} = $state->{command_idx} + $state->{command_len};
        $eol = $state->{command_eol};
        $tmp = $state->{header_idx} + $eol;
        while (1) {
            $index = index(${$bufref}, "\n", $tmp);
            return(0) if $index < 0;
            if ($index == $tmp) {
                $state->{header_eol} = $eol + 1;
                last;
            } elsif ($index == $tmp + 1
                     and substr(${$bufref}, $tmp, 1) eq "\r") {
                $state->{header_eol} = $eol + 2;
                last;
            }
            $eol = substr(${$bufref}, $index - 1, 1) eq "\r" ? 2 : 1;
            $tmp = $index + 1;
        }
        $index -= $state->{header_eol} - 1;
        if ($index == $state->{header_idx}) {
            # empty header
            $state->{header_len} = 0;
        } else {
            # non-empty header
            $state->{header_idx} += $state->{command_eol};
            $state->{header_len} = $index - $state->{header_idx};
            $tmp = substr(${$bufref}, $state->{header_idx} - 1,
                          $state->{header_len} + 3);
            $state->{content_length} = $1
                if $tmp =~ /\ncontent-length *: *(\d+) *\r?\n/;
        }
    }
    #
    # body: everything up to content-length bytes or the first NULL byte
    #
    $buflen = length(${$bufref});
    $state->{body_idx} = $state->{header_idx} + $state->{header_len}
        + $state->{header_eol};
    if (exists($state->{content_length})) {
        # length is known
        return(0)
            if $buflen < $state->{body_idx} + $state->{content_length} + 1;
        $state->{body_len} = $state->{content_length};
        $tmp = substr(${$bufref}, $state->{body_idx} + $state->{body_len}, 1);
        dief("missing NULL byte at end of frame") unless $tmp eq "\0";
    } else {
        # length is not known
        $index = index(${$bufref}, "\0", $state->{body_idx});
        return(0) if $index < 0;
        $state->{body_len} = $index - $state->{body_idx};
    }
    #
    # after: allow 0 or more end-of-line characters
    # (note: we allow \n and \r\n but also \r as EOL, this should not be a
    #  problem in practice)
    #
    $state->{after_idx} = $state->{body_idx} + $state->{body_len} + 1;
    $state->{after_len} = 0;
    while ($buflen > $state->{after_idx} + $state->{after_len}) {
        $tmp = substr(${$bufref}, $state->{after_idx} + $state->{after_len}, 1);
        last unless $tmp eq "\r" or $tmp eq "\n";
        $state->{after_len}++;
    }
    $state->{total_len} = $state->{after_idx} + $state->{after_len};
    # so far so good ;-)
    return($state);
}

#+++############################################################################
#                                                                              #
# decoding                                                                     #
#                                                                              #
#---############################################################################

#
# decode the given string reference and return a frame object if the frame is
# complete or false otherwise; take the same options as parse() plus debug
# and version
#
# side effect: in case a frame is successfully decoded, the given string is
# _modified_ to remove the corresponding encoded frame
#

my %decode_options = (
    debug   => { optional => 1, type => UNDEF|SCALAR },
    state   => { optional => 1, type => HASHREF },
    strict  => { optional => 1, type => BOOLEAN },
    version => { optional => 1, type => SCALAR, regex => qr/^1\.\d$/ },
);

sub decode ($@) {  ## no critic 'ProhibitExcessComplexity'
    my($bufref, %option, $check, $state, $key, $val, $errors, $tmp, %frame);

    #
    # setup
    #
    if ($Net::STOMP::Client::NoParamsValidation) {
        ($bufref, %option) = @_;
    } else {
        validate_pos(@_, { type => SCALARREF }) unless ref($_[0]) eq "SCALAR";
        $bufref = shift(@_);
        %option = validate(@_, \%decode_options) if @_;
    }
    $option{debug} ||= "";
    $state = $option{state} || {};
    $option{strict} = $StrictEncode unless defined($option{strict});
    $option{version} ||= "1.0";
    $check = $option{strict} ? Encode::FB_CROAK : Encode::FB_DEFAULT;
    #
    # frame parsing
    #
    {
        local $Net::STOMP::Client::NoParamsValidation = 1;
        $tmp = parse($bufref, state => $state);
    }
    return(0) unless $tmp;
    #
    # frame debugging
    #
    if ($option{debug} =~ /\b(command|all)\b/) {
        $tmp = substr(${$bufref}, $state->{command_idx}, $state->{command_len});
        _debug_command("decoding", $tmp);
    }
    if ($option{debug} =~ /\b(header|all)\b/) {
        $tmp = substr(${$bufref}, $state->{header_idx}, $state->{header_len});
        _debug_header($tmp);
    }
    if ($option{debug} =~ /\b(body|all)\b/) {
        $tmp = substr(${$bufref}, $state->{body_idx}, $state->{body_len});
        _debug_body($tmp);
    }
    #
    # frame decoding (command)
    #
    $frame{"command"} =
        substr(${$bufref}, $state->{command_idx}, $state->{command_len});
    dief("invalid command: %s", $frame{"command"})
        unless $frame{"command"} =~ $new_options{"command"}{"regex"};
    #
    # frame decoding (headers)
    #
    if ($state->{header_len}) {
        $frame{"headers"} = {};
        $tmp = substr(${$bufref}, $state->{header_idx}, $state->{header_len});
        if ($option{version} ge "1.1") {
            # STOMP >=1.1 behavior: the header is assumed to be UTF-8 encoded
            $tmp = Encode::decode("UTF-8", $tmp, $check);
        }
        if ($option{version} eq "1.0") {
            # STOMP 1.0 behavior:
            #  - we arbitrarily restrict the header name as a safeguard
            #  - space surrounding the comma and at end of line is not significant
            #  - last header wins (not specified explicitly but reasonable default)
            foreach my $line (split(/\n/, $tmp)) {
                if ($line =~ /^($_HeaderNameRE)\s*:\s*(.*?)\s*$/o) {
                    $frame{"headers"}{$1} = $2;
                } else {
                    dief("invalid header: %s", $line);
                }
            }
        } elsif ($option{version} eq "1.1") {
            # STOMP 1.1 behavior:
            #  - header names and values can contain any byte except \n or :
            #  - space is significant
            #  - only the first header entry should be used
            #  - handle backslash escaping
            foreach my $line (split(/\n/, $tmp)) {
                if ($line =~ /^([^\n\:]+):([^\n\:]*)$/) {
                    ($key, $val, $errors) = ($1, $2, 0);
                } else {
                    dief("invalid header: %s", $line);
                }
                $key =~ s/(\\.)/$_DecMap1{$1}||$errors++/eg;
                $val =~ s/(\\.)/$_DecMap1{$1}||$errors++/eg;
                dief("invalid header: %s", $line) if $errors;
                $frame{"headers"}{$key} = $val
                    unless exists($frame{"headers"}{$key});
            }
        } else {
            # STOMP 1.2 behavior:
            #  - header names and values can contain any byte except \r or \n or :
            #  - space is significant
            #  - only the first header entry should be used
            #  - handle backslash escaping
            foreach my $line (split(/\r?\n/, $tmp)) {
                if ($line =~ /^([^\r\n\:]+):([^\r\n\:]*)$/) {
                    ($key, $val, $errors) = ($1, $2, 0);
                } else {
                    dief("invalid header: %s", $line)
                }
                $key =~ s/(\\.)/$_DecMap2{$1}||$errors++/eg;
                $val =~ s/(\\.)/$_DecMap2{$1}||$errors++/eg;
                dief("invalid header: %s", $line) if $errors;
                $frame{"headers"}{$key} = $val
                    unless exists($frame{"headers"}{$key});
            }
        }
    }
    #
    # frame decoding (body)
    #
    if ($state->{body_len}) {
        $tmp = substr(${$bufref}, $state->{body_idx}, $state->{body_len});
        if ($option{version} ge "1.1" and $frame{"headers"}) {
            # STOMP >=1.1 behavior: the body may be encoded
            $val = _encoding($frame{"headers"}{"content-type"});
            if ($val) {
                $tmp = Encode::decode($val, $tmp, $check);
            }
        }
        $frame{"body_reference"} = \$tmp;
    }
    #
    # so far so good
    #
    substr(${$bufref}, 0, $state->{total_len}, "");
    %{ $state } = ();
    local $Net::STOMP::Client::NoParamsValidation = 1;
    return(__PACKAGE__->new(%frame));
}

#+++############################################################################
#                                                                              #
# encoding                                                                     #
#                                                                              #
#---############################################################################

#
# encode the given frame object and return a string reference; take the same
# options as decode() except state
#

my %encode_options = (
    debug   => { optional => 1, type => UNDEF|SCALAR },
    strict  => { optional => 1, type => BOOLEAN },
    version => { optional => 1, type => SCALAR, regex => qr/^1\.\d$/ },
);

sub encode : method {  ## no critic 'ProhibitExcessComplexity'
    my($self, %option, $check, $header, $tmp);
    my($body, $bodyref, $bodylen, $conlen, $key, $val);

    #
    # setup
    #
    if ($Net::STOMP::Client::NoParamsValidation) {
        ($self, %option) = @_;
    } else {
        $self = shift(@_);
        %option = validate(@_, \%encode_options) if @_;
    }
    $option{debug} ||= "";
    $option{strict} = $StrictEncode unless defined($option{strict});
    $option{version} ||= "1.0";
    $check = $option{strict} ? Encode::FB_CROAK : Encode::FB_DEFAULT;
    #
    # body encoding (must be done first because of the content-length header)
    #
    if ($option{version} ge "1.1") {
        $tmp = _encoding($self->[I_HEADERS]{"content-type"});
    } else {
        $tmp = undef;
    }
    if ($tmp) {
        $body = Encode::encode($tmp, ${ $self->[I_BODY] },
                               $check | Encode::LEAVE_SRC);
        $bodyref = \$body;
    } else {
        $bodyref = $self->[I_BODY];
    }
    $bodylen = length(${ $bodyref });
    #
    # content-length header handling
    #
    $tmp = $self->[I_HEADERS]{"content-length"};
    if (defined($tmp)) {
        # content-length is defined: we use it unless it is the empty string
        # (which means do not set the content-length even with a body)
        $conlen = $tmp unless $tmp eq "";
    } else {
        # content-length is not defined (default behavior): we set it to the
        # body length only if the body is not empty
        $conlen = $bodylen unless $bodylen == 0;
    }
    #
    # header encoding
    #
    $tmp = $self->[I_HEADERS];
    if ($option{version} eq "1.0") {
        # STOMP 1.0 behavior: no backslash escaping
        $header = join("\n", map($_ . ":" . $tmp->{$_},
                       grep($_ ne "content-length", keys(%{ $tmp }))), "");
    } elsif ($option{version} eq "1.1") {
        # STOMP 1.1 behavior: backslash escaping
        $header = "";
        while (($key, $val) = each(%{ $tmp })) {
            next if $key eq "content-length";
            $key =~ s/($_EncSet1)/$_EncMap1{$1}/ego;
            $val =~ s/($_EncSet1)/$_EncMap1{$1}/ego;
            $header .= $key . ":" . $val . "\n";
        }
    } else {
        # STOMP 1.2 behavior: backslash escaping
        $header = "";
        while (($key, $val) = each(%{ $tmp })) {
            next if $key eq "content-length";
            $key =~ s/($_EncSet2)/$_EncMap2{$1}/ego;
            $val =~ s/($_EncSet2)/$_EncMap2{$1}/ego;
            $header .= $key . ":" . $val . "\n";
        }
    }
    $header .= "content-length:" . $conlen . "\n" if defined($conlen);
    if ($option{version} ge "1.1") {
        # STOMP >=1.1 behavior: the header must be UTF-8 encoded
        $header = Encode::encode("UTF-8", $header, $check);
    }
    #
    # frame debugging
    #
    if ($option{debug} =~ /\b(command|all)\b/) {
        _debug_command("encoding", $self->[I_COMMAND]);
    }
    if ($option{debug} =~ /\b(header|all)\b/) {
        _debug_header($header);
    }
    if ($option{debug} =~ /\b(body|all)\b/) {
        _debug_body(${ $bodyref });
    }
    #
    # assemble all the parts
    #
    $tmp = $self->[I_COMMAND] . "\n" . $header . "\n" . ${ $bodyref } . "\0";
    # return a reference to the encoded frame
    return(\$tmp);
}

#
# FIXME: compatibility hack for Net::STOMP::Client 1.x (to be removed one day)
#

sub check : method {
    return(1);
}

#+++############################################################################
#                                                                              #
# integration with Messaging::Message                                          #
#                                                                              #
#---############################################################################

#
# transform a frame into a message
#

sub messagify : method {
    my($self) = @_;

    unless ($Messaging::Message::VERSION) {
        eval { require Messaging::Message };
        dief("cannot load Messaging::Message: %s", $@) if $@;
    }
    return(Messaging::Message->new(
        "header"   => $self->headers(),
        "body_ref" => $self->body_reference(),
        "text"     => _encoding($self->header("content-type")) ? 1 : 0,
    ));
}

#
# transform a message into a frame
#

sub demessagify ($) {
    my($message, $frame, $content_type);

    # FIXME: compatibility hack for Net::STOMP::Client 1.x (to be removed one day)
    if (@_ == 1) {
        # normal API, to become: my($message) = @_
        $message = $_[0];
    } elsif (@_ == 2 and $_[0] eq "Net::STOMP::Client::Frame") {
        # old API, was a class method
        shift(@_);
        $message = $_[0];
    }
    validate_pos(@_, { isa => "Messaging::Message" });
    $frame = __PACKAGE__->new(
        "command"        => "SEND",
        "headers"        => $message->header(),
        "body_reference" => $message->body_ref(),
    );
    # handle the text attribute wrt the content-type header
    $content_type = $frame->header("content-type");
    if (defined($content_type)) {
        # make sure the content-type is consistent with the message type
        if (_encoding($content_type)) {
            dief("unexpected text content-type for binary message: %s",
                 $content_type) unless $message->text();
        } else {
            dief("unexpected binary content-type for text message: %s",
                 $content_type) if $message->text();
        }
    } else {
        # set a text content-type if it is missing (this is needed by STOMP >=1.1)
        $frame->header("content-type", "text/unknown") if $message->text();
    }
    return($frame);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(demessagify));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__END__

=head1 NAME

Net::STOMP::Client::Frame - Frame support for Net::STOMP::Client

=head1 SYNOPSIS

  use Net::STOMP::Client::Frame qw();

  # create a connection frame
  $frame = Net::STOMP::Client::Frame->new(
      command => "CONNECT",
      headers => {
          login    => "guest",
          passcode => "guest",
      },
  );

  # get the command
  $cmd = $frame->command();

  # set the body
  $frame->body("...some data...");

  # directly get a header field
  $msgid = $frame->header("message-id");

=head1 DESCRIPTION

This module provides an object oriented interface to manipulate STOMP
frames.

A frame object has the following attributes: C<command>, C<headers> and
C<body_reference>. The C<headers> attribute must be a reference to a hash of
header key/value pairs. The body is usually manipulated by reference to
avoid string copies.

=head1 METHODS

This module provides the following methods:

=over

=item new([OPTIONS])

return a new Net::STOMP::Client::Frame object (class method); the options
that can be given (C<command>, C<headers>, C<body_reference> and C<body>)
match the accessors described below

=item command([STRING])

get/set the C<command> attribute

=item headers([HASHREF])

get/set the C<headers> attribute

=item body_reference([STRINGREF])

get/set the C<body_reference> attribute

=item header(NAME[, VALUE])

get/set the value associated with the given name in the header; if the given
value is undefined, remove the named header (this is a convenient wrapper
around the headers() method)

=item body([STRING])

get/set the body as a string (this is a convenient wrapper around the
body_reference() method)

=item encode([OPTIONS])

encode the given frame and return a reference to a binary string suitable to
be written to a TCP stream (for instance); supported options:
C<debug> (debugging flags as a string),
C<strict> (the desired strictness, overriding $StrictEncode),
C<version> (the STOMP protocol version to use)

=item check([OPTIONS])

this method is obsolete and should not be used anymore; it is left here only
to provide backward compatibility with Net::STOMP::Client 1.x

=back

=head1 FUNCTIONS

This module provides the following functions (which are B<not> exported):

=over

=item decode(STRINGREF, [OPTIONS])

decode the given string reference and return a complete frame object, if
possible or false in case there is not enough data for a complete frame;
supported options: the same as encode() plus parse()

=item parse(STRINGREF, [OPTIONS])

parse the given string reference and return true if a complete frame is
found or false otherwise; supported options: C<state> (a hash reference that
holds the parsing state); see the L<"FRAME PARSING"> section for more
information

=back

=head1 VARIABLES

This module uses the following global variables (which are B<not> exported):

=over

=item $Net::STOMP::Client::Frame::DebugBodyLength

the maximum number of bytes to dump when debugging message bodies
(default: 256)

=item $Net::STOMP::Client::Frame::StrictEncode

whether or not to perform strict character encoding/decoding
(default: false)

=back

=head1 FRAME PARSING

The parse() function can be used to parse a frame without decoding it.

It takes as input a binary string reference (to avoid string copies) and an
optional state (a hash reference). It parses the string to find out where
the different parts of the frames are and it updates its state (if given).

It returns false if the string does not hold a complete frame or a hash
reference if a complete frame is present. This hash is in fact the same
thing as the state and it contains the following keys:

=over

=item before_len

the length of what is found before the frame (only frame EOL can appear
here)

=item command_idx, command_len, command_eol

the start position, length and length of the EOL of the command

=item header_idx, header_len, header_eol

the start position, length and length of the EOL of the header

=item body_idx, body_len

the start position and length of the body

=item after_idx, after_len

the length of what is found after the frame (only frame EOL can appear here)

=item content_length

the value of the C<content-length> header (if present)

=item total_len

the total length of the frame, including before and after parts

=back

Here is how this could be used:

  $data = "... read from socket or file ...";
  $info = Net::STOMP::Client::Frame::parse(\$data);
  if ($info) {
      # extract interesting frame parts
      $command = substr($data, $info->{command_idx}, $info->{command_len});
      # remove the frame from the buffer
      substr($data, 0, $info->{total_len}) = "";
  }

=head1 CONTENT LENGTH

The C<content-length> header is special because it is sometimes used to
indicate the length of the body but also the JMS type of the message in
ActiveMQ as per L<http://activemq.apache.org/stomp.html>.

If you do not supply a C<content-length> header, following the protocol
recommendations, a C<content-length> header will be added if the frame has a
body.

If you do supply a numerical C<content-length> header, it will be used as
is. Warning: this may give unexpected results if the supplied value does not
match the body length. Use only with caution!

Finally, if you supply an empty string as the C<content-length> header, it
will not be sent, even if the frame has a body. This can be used to mark a
message as being a TextMessage for ActiveMQ. Here is an example of this:

  $stomp->send(
      "destination"    => "/queue/test",
      "body"           => "hello world!",
      "content-length" => "",
  );

=head1 ENCODING

The STOMP 1.0 specification does not define which encoding should be used to
serialize frames. So, by default, this module assumes that what has been
given by the user or by the server is a ready-to-use sequence of bytes and
it does not perform any further encoding or decoding.

If $Net::STOMP::Client::Frame::StrictEncode is true, all encoding and
decoding operations will be stricter and will report a fatal error when
given malformed input. This is done by using the Encode::FB_CROAK flag
instead of the default Encode::FB_DEFAULT.

N.B.: Perl's standard L<Encode> module is used for all encoding/decoding
operations.

=head1 MESSAGING ABSTRACTION

If the L<Messaging::Message> module is available, the following method and
function are available too:

=over

=item messagify()

transform the frame into a Messaging::Message object (method)

=item demessagify(MESSAGE)

transform the given Messaging::Message object into a
Net::STOMP::Client::Frame object (function)

=back

Here is how they could be used:

  # frame to message
  $frame = $stomp->wait_for_frames(timeout => 1);
  if ($frame) {
      $message = $frame->messagify();
      ...
  }

  # message to frame
  $frame = Net::STOMP::Client::Frame::demessagify($message);
  $stomp->send_frame($frame);

Note: in both cases, string copies are avoided so both objects will share
the same header hash and body string. Therefore modifying one may also
modify the other. Clone (copy) the objects if you do not want this behavior.

=head1 COMPLIANCE

STOMP 1.0 has several ambiguities and this module does its best to work "as
expected" in these gray areas.

STOMP 1.1 and STOMP 1.2 are much better specified and this module should be
fully compliant with these STOMP specifications with only one exception: by
default, this module is permissive and allows malformed encoded data (this
is the same default as the L<Encode> module itself); to be more strict, set
$Net::STOMP::Client::Frame::StrictEncode to true (as explained above).

=head1 SEE ALSO

L<Encode>,
L<Messaging::Message>,
L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
