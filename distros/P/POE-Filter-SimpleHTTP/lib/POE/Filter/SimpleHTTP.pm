package POE::Filter::SimpleHTTP;
our $VERSION = '0.091710';

use 5.010;
use Moose;
extends('Exporter', 'Moose::Object');

use Moose::Util::TypeConstraints;

use Scalar::Util('blessed', 'reftype');

use HTTP::Status;
use HTTP::Response;
use HTTP::Request;
use URI;
use Compress::Zlib;

use POE::Filter::SimpleHTTP::Regex;
use POE::Filter::SimpleHTTP::Error;

use UNIVERSAL::isa;

use bytes;

our @EXPORT = qw/PFSH_CLIENT PFSH_SERVER/;
our $DEBUG = 0;

use constant
{
    PARSE_START         => 0,
    PREAMBLE_COMPLETE   => 1,
    HEADER_COMPLETE     => 2,
    CONTENT_COMPLETE    => 3,
    PFSH_CLIENT         => 0,
    PFSH_SERVER         => 1,
};

subtype 'ParseState'
    => as 'Int'
    => where { -1 < $_  && $_ < 4 }
    => message { 'Incorrect ParseState' };

subtype 'FilterMode'
    => as 'Int'
    => where { $_ == 0 || $_ == 1 }
    => message { 'Incorrect FilterMode' };

subtype 'Uri'
    => as 'Str'
    => where { /$POE::Filter::SimpleHTTP::Regex::URI/ }
    => message { 'Invalid URI string' };

subtype 'HttpStatus'
    => as 'Int'
    => where { is_info($_) || is_success($_) || is_redirect($_) || is_error($_) }
    => message { 'Invalid HTTP status code'};

subtype 'HttpProtocol'
    => as 'Str'
    => where { /$POE::Filter::SimpleHTTP::Regex::PROTOCOL/ }
    => message { 'Invalid HTTP protocol string' };

subtype 'HttpMethod'
    => as 'Str'
    => where { /$POE::Filter::SimpleHTTP::Regex::METHOD/ }
    => message { 'Invalid HTTP method' };

has raw => 
(
    is => 'rw', 
    isa => 'ArrayRef[Str]', 
    default => sub {[]},
    clearer => 'clear_raw',
    lazy => 1
);

has preamble => 
( 
    is => 'rw', 
    isa => 'ArrayRef[Str]', 
    default => sub {[]},
    clearer => 'clear_preamble',
    lazy => 1
);

has header => 
( 
    is => 'rw', 
    isa => 'ArrayRef[Str]', 
    default => sub {[]},
    clearer => 'clear_header',
    lazy => 1
);

has content => 
( 
    is => 'rw', 
    isa => 'ArrayRef[Str]', 
    default => sub {[]},
    clearer => 'clear_content',
    lazy => 1
);

has state => 
( 
    is => 'rw', 
    isa => 'ParseState',
    default => 0,
    clearer => 'clear_state',
    lazy => 1
);

has mode => 
( 
    is => 'rw', 
    isa => 'FilterMode',
    default => 0,
    lazy => 1
);

has uri => 
( 
    is => 'rw', 
    isa => 'Uri', 
    default => '/',
    lazy => 1
);

has useragent => 
( 
    is => 'rw', 
    isa => 'Str', 
    default => __PACKAGE__ . '/' . $VERSION,
    lazy => 1
);

has host => 
( 
    is => 'rw', 
    isa => 'Str', 
    default => 'localhost',
    lazy => 1
);

has server => 
( 
    is => 'rw', 
    isa => 'Str', 
    default => __PACKAGE__ . '/' . $VERSION,
    lazy => 1
);

has mimetype =>
(
    is => 'rw',
    isa => 'Str',
    default => 'text/plain',
    lazy => 1
);

has status =>
(
    is => 'rw',
    isa => 'HttpStatus',
    default => 200,
    lazy => 1
);

has protocol =>
(
    is => 'rw',
    isa => 'HttpProtocol',
    default => 'HTTP/1.1',
    lazy => 1
);

has 'method' =>
(
    is => 'rw',
    isa => 'HttpMethod',
    default => 'GET',
    lazy => 1
);

sub clone()
{
    my ($self, %params) = @_;
    return $self->meta->clone_object($self, %params);
}

sub isa()
{
    my ($self, $arg) = (shift(@_), shift(@_));
    if($arg eq 'POE::Filter')
    {
        return 1;
    }
    else
    {
        return $self->SUPER::isa($arg);
    }
}

sub reset()
{
	my ($self) = @_;
    $self->clear_raw();
    $self->clear_preamble();
    $self->clear_header();
    $self->clear_content();
    $self->clear_state();
}

sub get_one()
{
	my ($self) = @_;
	
	my $buffer = '';

	while(defined(my $raw = shift(@{$self->raw()})) || length($buffer))
	{
		$buffer .= $raw if defined($raw);
        my $state = $self->state();


		if($state < +PREAMBLE_COMPLETE)
		{
            if($buffer =~ /^\x0D\x0A/)
            {
                # skip the blank lines at the beginning if we have them
                substr($buffer, 0, 2, '');
                next;
            }
				
            if($buffer =~ $POE::Filter::SimpleHTTP::Regex::REQUEST
                or $buffer =~ $POE::Filter::SimpleHTTP::Regex::RESPONSE)
            {
                push(@{$self->preamble()}, $self->get_chunk(\$buffer));
                $self->state(+PREAMBLE_COMPLETE);

            } else {
                
                return 
                [
                    POE::Filter::SimpleHTTP::Error->new
                    (
                        {
                            error => +UNPARSABLE_PREAMBLE,
                            context => $buffer
                        }
                    )
                ];
            }

		} elsif($state < +HEADER_COMPLETE) {
			
			if($buffer =~ /^\x0D\x0A/)
			{
				substr($buffer, 0, 2, '');
				$self->state(+HEADER_COMPLETE);
			
			} else {
				
				#gather all of the headers from this chunk
				while($buffer =~ $POE::Filter::SimpleHTTP::Regex::HEADER 
					and $buffer !~ /^\x0D\x0A/)
				{
					push(@{$self->header()}, $self->get_chunk(\$buffer));
				}

			}

		} elsif($state < +CONTENT_COMPLETE) {
			
			if($buffer =~ /^\x0D\x0A/)
			{
				substr($buffer, 0, 2, '');
				$self->state(+CONTENT_COMPLETE);

			} else {
				
                push(@{$self->content}, $self->get_chunk(\$buffer));
			}

            if(!@{$self->raw} && !length($buffer))
            {
                $self->state(+CONTENT_COMPLETE);
            }

		} else {
            
            if($buffer =~ /^\x0D\x0A$/)
            {
                # skip the blank lines at the end if we have them
                substr($buffer, 0, 2, '');
                next;
            }

            return
            [
                POE::Filter::SimpleHTTP::Error->new
                (
                    {
                        error => +TRAILING_DATA,
                        context => $buffer
                    }
                )
            ];
		}
	}
		
	if($self->state() == +CONTENT_COMPLETE)
	{
		my $ret = [$self->build_message()];
        $self->reset();
        return $ret;
	}
	else
	{
		warn Dumper($self) if $DEBUG;
		return [];
	}
};

sub get_one_start()
{
	my ($self, $data) = @_;
	
	if(!ref($data))
	{
		$data = [$data];
	}

	push(@{$self->raw()}, @$data);
	
};

sub put()
{
	my ($self, $content) = @_;
	
    my $ret = [];

    while(@$content)
    {
        my $check = shift(@$content);

        if(blessed($check) && $check->isa('HTTP::Message'))
        {
            push(@$ret, $check);
            next;
        }

        unshift(@$content, $check);

        my $http;

        if($self->mode() == +PFSH_SERVER)
        {
            my $response;
            
            $response = HTTP::Response->new($self->status());
            $response->content_type($self->mimetype());
            $response->server($self->server());
            
            while(@$content)
            {
                $response->add_content(shift(@$content));
            }

            $http = $response;

        } else {

            my $request = HTTP::Request->new();

            $request->method($self->method());
            $request->uri($self->uri());
            $request->user_agent($self->useragent()); 
            $request->content_type($self->mimetype());

            while(@$content)
            {
                $request->add_content(shift(@$content));
            }
            
            $http = $request;
        }

        $http->protocol($self->protocol());
        push(@$ret, $http);
	}

    return $ret;
};


sub get_chunk()
{
	my ($self, $buffer) = @_;

	#find the break
	my $break = index($$buffer, "\x0D\x0A");
	
	my $match;

	if($break < 0)
	{
		#pullout the whole string
		$match = substr($$buffer, 0, length($$buffer), '');
	
	} elsif($break > -1) {
		
		#pull out string until newline
		$match = substr($$buffer, 0, $break, '');
		
		#remove the CRLF from the buffer
		substr($$buffer, 0, 2, '');
	}

	return $match;
}

sub build_message()
{
	my ($self) = @_;
	
	my $message;

	my $preamble = shift(@{$self->preamble()});

	if($preamble =~ $POE::Filter::SimpleHTTP::Regex::REQUEST)
	{
		my ($method, $uri) = ($1, $2);

		$message = HTTP::Request->new($method, $uri);
	
	} elsif($preamble =~ $POE::Filter::SimpleHTTP::Regex::RESPONSE) {
	
		my ($code, $text) = ($2, $3);

		$message = HTTP::Response->new($code, $text);
	}


	foreach my $line (@{$self->header()})
	{
		if($line =~ $POE::Filter::SimpleHTTP::Regex::HEADER)
		{
			$message->header($1, $2);
		}
	}

	# If we have a transfer encoding, we need to decode it 
	# (ie. unchunkify, decompress, etc)
	if($message->header('Transfer-Encoding'))
	{
		warn 'INSIDE TE' if $DEBUG;
		my $te_raw = $message->header('Transfer-Encoding');
		my $te_s = 
		[ 
			(
				map 
				{ 
					my ($token) = split(/;/, $_); $token; 
				} 
				(reverse(split(/,/, $te_raw)))
			)
		];
		
		my $buffer = '';
		my $subbuff = '';
		my $size = 0;
        my $content = '';
$DB::single=1;
		while(defined(my $content_line = shift(@{$self->content()})) )
		{
			# Start of a new chunk
			if($size == 0)
			{
				if($content_line =~ /^([\dA-Fa-f]+)(?:\x0D\x0A)*/)
				{
					warn "CHUNK SIZE IN HEX: $1" if $DEBUG;
					$size = hex($1);
				}
				
				# If we got a zero size, it means time to process trailing 
				# headers if enabled
				if($size == 0)
				{
                    warn "SIZE ZERO HIT" if $DEBUG;
					if($message->header('Trailer'))
					{
						while( my $tline = shift(@{$self->content()}) )
						{
							if($tline =~ $POE::Filter::SimpleHTTP::Regex::HEADER)
							{
								my ($key, $value) = ($1, $2);
								$message->header($key, $value);
							}
						}
					}
					return $message;
				}
			}
			
			while($size > 0)
			{
				warn "SIZE: $size" if $DEBUG;
				my $subline = shift(@{$self->content()});
				while(length($subline))
				{
                    warn 'LENGTH OF SUBLINE: ' . length($subline) if $DEBUG;
					my $buff = substr($subline, 0, 4069, '');
					$size -= length($buff);
					$subbuff .= $buff;
				}
			}

			$buffer .= $subbuff;
            warn 'BUFFER LENGTH: ' .length($buffer) if $DEBUG;

			$subbuff = '';
		}
		
		my $chunk = shift(@$te_s);
		if($chunk !~ /chunked/)
		{
			warn 'CHUNKED ISNT LAST' if $DEBUG;
            
            return POE::Filter::SimpleHTTP::Error->new
            (
                {
                    error => +CHUNKED_ISNT_LAST,
                    context => join(' ',($chunk, @$te_s))
                }
            );
		}
        
        if(!scalar(@$te_s))
        {
            $content = $buffer;
        }

		foreach my $te (@$te_s)
		{
			if($te =~ /deflate/)
			{
				my ($inflate, $status) = Compress::Zlib::inflateInit();
				if(!defined($inflate))
				{
					warn 'INFLATE FAILED TO INIT' if $DEBUG;
                    return POE::Filter::SimpleHTTP::Error->new
                    (
                        {
                            error => +INFLATE_FAILED_INIT,
                            context => $status
                        }
                    );
				}
				else
				{
                    warn 'BUFFER LENGTH BEFORE INFLATE: '. length($buffer) if $DEBUG;
					my ($content, $status) = $inflate->inflate(\$buffer);
                    warn "DECOMPRESSED CONTENT: $content" if $DEBUG && $content;
					if($status != +Z_OK or $status != +Z_STREAM_END)
					{
						warn 'INFLATE FAILED TO DECOMPRESS' if $DEBUG;
						return POE::Filter::SimpleHTTP::Error->new
                        (
                            {
                                error => +INFLATE_FAILED_INFLATE,
                                context => $status
                            }
                        );
					}
				}
			
			} elsif($te =~ /compress/) {

				$content = Compress::Zlib::uncompress(\$buffer);
				if(!defined($content))
				{
					warn 'UNCOMPRESS FAILED' if $DEBUG;
					return POE::Filter::SimpleHTTP::Error->new
                    (
                        {
                            error => +UNCOMPRESS_FAILED
                        }
                    );
				}

			} elsif($te =~ /gzip/) {

                warn 'BUFFER LENGTH BEFORE GUNZIP: '. length($buffer) if $DEBUG;
				$content = Compress::Zlib::memGunzip(\$buffer);
                warn "DECOMPRESSED CONTENT: $content" if $DEBUG;
				if(!defined($content))
				{
					warn 'GUNZIP FAILED' if $DEBUG;
					return POE::Filter::SimpleHTTP::Error->new
                    (
                        {
                            error => +GUNZIP_FAILED
                        }
                    );
				}
			
			} else {
                
                warn 'UNKNOWN TRANSFER ENCOODING' if $DEBUG;
                return POE::Filter::SimpleHTTP::Error->new
                (
                    {
                        error => +UNKNOWN_TRANSFER_ENCODING,
                        context => $te
                    }
                );
			}
		}

		$message->content_ref(\$content);
	
	} else {

		$message->add_content($_) for @{$self->content()};
	}

	# We have the type, the headers, and the content. Return the object
	return $message;
}

=pod

=head1 NAME

POE::Filter::SimpleHTTP - A simple client/server suitable HTTP filter

=head1 VERSION

version 0.091710

=head1 SYNOPSIS

use POE::Filter::SimpleHTTP;
use HTTP::Request;
use HTTP::Respose;
use HTTP::Status;

my $filter = POE::Filter::SimpleHTTP->new
(
    {
        mode        => +PFSH_CLIENT,
        useragent   => 'Whizbang Client/0.01',
        host        => 'remote.server.com',
        method      => 'POST'
    }
);

my $post = $filter->put([qw|id=123& data=Here is some data|])->[0];

=head1 DESCRIPTION

POE::Filter::SimpleHTTP is a filter designed to be used in either a client or 
a server context with the ability to switch the mode at runtime. In fact, a lot
of the behaviors can be altered at runtime. Which means you can put() just your
data into the filter and out the other side will be appropriate HTTP::Messages.

=head1 PUBLIC ACCESSORS

=over 4

=item mode

Use this access to change how the filter operates for put() if raw data is 
passed in. In +PFSH_CLIENT mode, an HTTP::Request will be constructed using 
data stored in other attributes of the filter. The obverse, if +PFSH_SERVER is 
set, then HTTP::Responses will be built. Regardless of mode, all HTTP::Messages
passed to put() will be passed through without any modification. It defaults to
+PFSH_CLIENT.

=item uri

This accessor is used to change the URI part of the HTTP::Request objects built
in put() if raw data is passed. It can either be full on HTTP URI or an 
absolute path. It defaults to '/'

=item useragent

Use this to change the user agent header on constructed HTTP::Request objects. 
It defaults to __PACKAGE__ . '/' . $VERSION.

=item host

Use this to change the host header on constructed HTTP::Requests. It defaults 
to 'localhost'

=item status

Use this to set the status codes for constructed HTTP::Responses. It defaults 
to 200 (aka, HTTP_OK).

=item method

This accessor is used to change the method on constructed HTTP::Requests. It
defaults to 'GET'.

=item mimetype

This accessor is for the Content-Type header on constructed HTTP::Messages.
Regardless of mode(), constructed Requests and Responses will use this value.
It defaults to 'text/plain'

=back

=head1 PUBLIC METHODS

This filter is based on POE::Filter and so only the differences in public API
will be mentioned below

=over 4

=item new()

The constructor can be called with no arguments in which all of the defaults 
mentioned above in the accessors will be used, or a hash or hashref may be 
passed in with the keys corresponding to the accessors. Returns a new filter
instance.

=item reset()

This method will clear all of the internal buffers of the filter (but leave the
values provided to the accessors or constructor alone) back to their default 
state. 

=item put()

put() can accept either HTTP::Message based objects or raw data. If a Message
based object (ie. blessed($obj) && $obj->isa('HTTP::Message')) is passed in, 
it will be passed out exactly as is, untouched. 

But if raw data is passed in, depending on mode(), it will construct a suitable
HTTP::Message (Request or Response) using the various values stored in the
above accessors, and return it.

=back

=head1 NOTES

This is a simple filter in name and in implementation. Regardless of mode() the
get_one_start()/get_one() interface can accept both Responses and Requests. If 
for whatever reason there is an error in parsing the data an Error object will
be returned with an particular constant, and a snippet of context (if available
at the time the error occurred). See POE::Filter::SimpleHTTP::Error for details
on what the objects look like.

This filter should confrom to HTTP/0.9-HTTP/1.1 with regards to transfer 
encodings (chunked, compressed, etc), in which case the data will be unchunked
and uncompressed and stored in the content() of the Message. Note that this 
does not include Content-Encoding which HTTP::Message should handle for you.

=head1 AUTHOR

Copyright 2007 - 2009 Nicholas Perez.
Licensed and distributed under the GPL.

=cut

__PACKAGE__->meta->make_immutable();
no Moose;

1;