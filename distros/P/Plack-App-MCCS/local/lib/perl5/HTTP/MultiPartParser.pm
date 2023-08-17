package HTTP::MultiPartParser;
use strict;
use warnings;

BEGIN {
    our $VERSION = '0.02';
}

use Carp         qw[];
use Scalar::Util qw[];

my $_mk_parser;

# RFC2046
my $ValidBoundary = qr<\A [0-9A-Za-z'()+_,-./:=?]+ \z>x;

sub new {
    my ($class, %params) = @_;

    my $self = {
        on_error          => \&Carp::croak,
        max_header_size   => 32 * 1024,
        max_preamble_size => 32 * 1024,
        on_header_as      => 'lines',
    };

    while (my ($p, $v) = each %params) {
        if ($p eq 'boundary') {
            Carp::croak(q/Parameter 'boundary' is not a valid boundary value/)
              unless ref \$v eq 'SCALAR' && defined $v && $v =~ $ValidBoundary;
            $self->{boundary} = $v;
        }
        elsif (   $p eq 'on_header'
               || $p eq 'on_body'
               || $p eq 'on_error') {
            Carp::croak(qq/Parameter '$p' is not a CODE reference/)
              unless ref $v eq 'CODE';
            $self->{$p} = $v;
        }
        elsif (   $p eq 'max_header_size'
               || $p eq 'max_preamble_size') {
            Carp::croak(qq/Parameter '$p' is not a positive integer/)
              unless ref \$v eq 'SCALAR' && defined $v && $v =~ /\A [1-9][0-9]* \z/x;
            $self->{$p} = $v;
        }
        elsif ($p eq 'on_header_as') {
            Carp::croak(q/Parameter 'on_header_as' must be either 'unparsed' or 'lines'/)
              unless ref \$v eq 'SCALAR' && defined $v && $v =~ /\A (?: unparsed | lines) \z/x;
            $self->{on_header_as} = $v;
        }
        else {
            Carp::croak(qq/Unknown parameter '$p' passed to constructor/);
        }
    }

    for my $p (qw(boundary on_header on_body)) {
        Carp::croak(qq/Mandatory parameter '$p' is missing/)
          unless exists $self->{$p};
    }

    bless $self, $class;
    $self->{parser} = $_mk_parser->($self);
    return $self;
}

sub parse {
    @_ == 2 || Carp::croak(q/Usage: $parser->parse($octets)/);
    return $_[0]->{parser}->($_[1]);
}

sub finish {
    @_ == 1 || Carp::croak(q/Usage: $parser->finish()/);
    return $_[0]->{parser}->('', 1);
}

sub reset {
    @_ == 1 || Carp::croak(q/Usage: $parser->reset()/);
    $_[0]->{parser}  = $_mk_parser->($_[0]);
    $_[0]->{aborted} = !!0;
}

sub is_aborted {
    @_ == 1 || Carp::croak(q/Usage: $parser->is_aborted()/);
    return $_[0]->{aborted};
}

sub CRLF  () { "\x0D\x0A" }
sub TRUE  () { !!1 }
sub FALSE () { !!0 }

sub STATE_PREAMBLE () { 1 }
sub STATE_BOUNDARY () { 2 }
sub STATE_HEADER   () { 3 }
sub STATE_BODY     () { 4 }
sub STATE_EPILOGUE () { 5 }

$_mk_parser = sub {
    Scalar::Util::weaken(my $self = $_[0]);

    # RFC 2616 3.7.2 Multipart Types
    # The message body is itself a protocol element and MUST therefore use only
    # CRLF to represent line breaks between body-parts.
    my $boundary           = $self->{boundary};
    my $boundary_preamble  =        '--' . $boundary;
    my $boundary_delimiter = CRLF . '--' . $boundary;

    my $chunk   = '';
    my $buffer  = '';
    my $state   = STATE_PREAMBLE;
    my $finish  = FALSE;
    my $aborted = FALSE;
    
    my $on_header = $self->{on_header};
    my $on_body   = $self->{on_body};
    my $on_error  = sub {
        $aborted = $self->{aborted} = TRUE;
        goto $self->{on_error};
    };
    
    if ($self->{on_header_as} eq 'lines') {
        $on_header = sub {
            my @headers;
            for (split /\x0D\x0A/, $_[0]) {
                if (/\A [^\x00-\x1F\x7F:]+ : /x) {
                    push @headers, $_;
                }
                elsif (s/\A [\x09\x20]+ //x) {
                    if (!@headers) {
                        $on_error->(q/Continuation line seen before first header/);
                        return;
                    }
                    next unless length;
                    $headers[-1] .= ' ' unless $headers[-1] =~ /[\x09\x20]\z/;
                    $headers[-1] .= $_;
                }
                else {
                    $on_error->(q/Malformed header line/);
                    return;
                }
            }
            $self->{on_header}->(\@headers);
        };
    }
    
    return sub {
        $buffer .= $_[0];
        $finish  = $_[1];

        while (!$aborted) {
            if ($state == STATE_PREAMBLE) {
                my $pos = index($buffer, $boundary_preamble);
                if ($pos < 0) {
                    if (length $buffer > $self->{max_preamble_size}) {
                        $on_error->(q/Size of preamble exceeds maximum allowed/);
                        last;
                    }
                    $finish && $on_error->(q/End of stream encountered while parsing preamble/);
                    last;
                }
                substr($buffer, 0, $pos + 2 + length $boundary, '');
                $state = STATE_BOUNDARY;
            }
            elsif ($state == STATE_BOUNDARY) {
                if (length $buffer < 2) {
                    $finish && $on_error->(q/End of stream encountered while parsing boundary/);
                    last;
                }
                elsif (substr($buffer, 0, 2) eq CRLF) {
                    substr($buffer, 0, 2, '');
                    $state = STATE_HEADER;
                }
                elsif (substr($buffer, 0, 2) eq '--') {
                    if (length $buffer < 4) {
                        $finish && $on_error->(q/End of stream encountered while parsing closing boundary/);
                        last;
                    }
                    elsif (substr($buffer, 2, 2) eq CRLF) {
                        substr($buffer, 0, 4, '');
                        $state = STATE_EPILOGUE;
                    }
                    else {
                        $on_error->(q/Closing boundary does not terminate with CRLF/);
                        last;
                    }
                }
                else {
                    $on_error->(q/Boundary does not terminate with CRLF or hyphens/);
                    last;
                }
            }
            elsif ($state == STATE_HEADER) {
                my $pos = index($buffer, CRLF . CRLF);
                if ($pos < 0) {
                    if (length $buffer > $self->{max_header_size}) {
                        $on_error->(q/Size of part header exceeds maximum allowed/);
                        last;
                    }
                    $finish && $on_error->(q/End of stream encountered while parsing part header/);
                    last;
                }

                $chunk = substr($buffer, 0, $pos + 4, '');
                $state = STATE_BODY;
                $on_header->($chunk);
            }
            elsif ($state == STATE_BODY) {
                my $take = index($buffer, $boundary_delimiter);
                if ($take < 0) {
                    $take = length($buffer) - (6 + length $boundary);
                    if ($take <= 0) {
                        $finish && $on_error->(q/End of stream encountered while parsing part body/);
                        last;
                    }
                }
                else {
                    $state = STATE_BOUNDARY;
                }

                $chunk = substr($buffer, 0, $take, '');

                if ($state == STATE_BOUNDARY) {
                    substr($buffer, 0, 4 + length $boundary, '');
                }

                $on_body->($chunk, $state == STATE_BOUNDARY);
            }
            # RFC 2616 3.7.2 Multipart Types
            # Unlike in RFC 2046, the epilogue of any multipart message MUST be
            # empty; HTTP applications MUST NOT transmit the epilogue (even if the
            # original multipart contains an epilogue). These restrictions exist in
            # order to preserve the self-delimiting nature of a multipart message-
            # body, wherein the "end" of the message-body is indicated by the
            # ending multipart boundary.
            elsif ($state == STATE_EPILOGUE) {
                (length $buffer == 0)
                  || $on_error->(q/Nonempty epilogue/);
                last;
            }
            else {
                Carp::croak(qq/panic: unknown state: $state/);
            }
        }
        return !$aborted;
    };
};

1;
