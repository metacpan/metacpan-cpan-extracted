package Plasp::Response;

use Plasp::Exception::Code;
use Plasp::Exception::End;
use Plasp::Exception::Redirect;

use CGI::Simple::Cookie;
use Data::Dumper;
use HTML::FillInForm::ForceUTF8;
use HTTP::Date qw(str2time time2str);
use List::Util qw(all);
use Scalar::Util qw(blessed);
use Tie::Handle;

use Moo;
use Sub::HandlesVia;
use Types::Standard qw(
    InstanceOf Str Int Bool HashRef ArrayRef ScalarRef CodeRef
);
use namespace::clean;

has 'asp' => (
    is       => 'ro',
    isa      => InstanceOf ['Plasp'],
    required => 1,
    weak_ref => 1,
);

has '_flushed_offset' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

# Keep track of if headers have been written out
has '_headers_written' => (
    is          => 'rw',
    isa         => Bool,
    default     => 0,
    handles_via => 'Bool',
    handles     => {
        _set_headers_written => 'set',
    },
);

=head1 NAME

Plasp::Response - $Response Object

=head1 SYNOPSIS

  use Plasp::Response;

  my $resp = Plasp::Response->new(asp => $asp);
  $resp->Write('<h1>Hello World!</h1>');
  my $body = $resp->Output;

=head1 DESCRIPTION

This object manages the output from the ASP Application and the client web
browser. It does not store state information like the $Session object but does
have a wide array of methods to call.

=cut

=head1 ATTRIBUTES

=over

=item $Response->{BinaryRef}

API extension. This is a perl reference to the buffered output of the
C<$Response> object, and can be used in the C<Script_OnFlush> F<global.asa>
event to modify the buffered output at runtime to apply global changes to
scripts output without having to modify all the scripts. These changes take
place before content is flushed to the client web browser.

  sub Script_OnFlush {
    my $ref = $Response->{BinaryRef};
    $$ref =~ s/\s+/ /sg; # to strip extra white space
  }

=cut

has 'BinaryRef' => (
    is      => 'rw',
    isa     => ScalarRef,
    default => sub { \( shift->Output ) }
);

# Store the buffered output as a Str attritube
has 'Output' => (
    is          => 'rw',
    isa         => Str,
    default     => '',
    clearer     => 'clear_Output',
    handles_via => 'String',
    handles     => {
        OutputLength => 'length',
        OutputSubstr => 'substr',
        Write        => 'append',
    },
);

# This attribute has no effect output will always be buffered, even in cases
# of streaming response.
has 'Buffer' => (
    is      => 'ro',
    default => 1,
);

=item $Response->{CacheControl}

Default C<"private">, when set to public allows proxy servers to cache the
content. This setting controls the value set in the HTTP header C<Cache-Control>

=cut

has 'CacheControl' => (
    is      => 'rw',
    isa     => Str,
    default => 'private',
);

before 'CacheControl' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting CacheControl has no effect!'
    ) if scalar( @_ ) && $self->_headers_written;
};

=item $Response->{Charset}

This member when set appends itself to the value of the Content-Type HTTP
header.  If C<< $Response->{Charset} = 'ISO-LATIN-1' >> is set, the
corresponding header would look like:

  Content-Type: text/html; charset=ISO-LATIN-1

=cut

has 'Charset' => (
    is      => 'rw',
    isa     => Str,
    default => '',
);

before 'Charset' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting Charset has no effect!'
    ) if scalar( @_ ) && $self->_headers_written;
};

# This attribute has no effect
has 'Clean' => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

=item $Response->{ContentType}

Default C<"text/html">. Sets the MIME type for the current response being sent
to the client. Sent as an HTTP header.

=cut

has 'ContentType' => (
    is      => 'rw',
    isa     => Str,
    default => 'text/html',
);

before 'ContentType' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting ContentType has no effect!'
    ) if scalar( @_ ) && $self->_headers_written;
};

=item $Response->{Expires}

Sends a response header to the client indicating the $time in SECONDS in which
the document should expire.  A time of C<0> means immediate expiration. The
header generated is a standard HTTP date like: "Wed, 09 Feb 1994 22:23:32 GMT".

=cut

has 'Expires' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

before 'Expires' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting Expires has no effect!'
    ) if scalar( @_ ) && $self->_headers_written;
};

=item $Response->{ExpiresAbsolute}

Sends a response header to the client with $date being an absolute time to
expire. Formats accepted are all those accepted by HTTP::Date::str2time(),
e.g.

=cut

has 'ExpiresAbsolute' => (
    is  => 'rw',
    isa => sub {
        die "$_[0] is not a supported date format!"
            if $_[0] && Str->check( $_[0] ) && !str2time $_[0];
    },
    default => '',
);

before 'ExpiresAbsolute' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting ExpiresAbsolute has no effect!'
    ) if scalar( @_ ) && $self->_headers_written;
};

=item $Response->{FormFill}

If true, HTML forms generated by the script output will be auto filled with
data from $Request->Form. This feature requires HTML::FillInForm to be
installed. Please see the FormFill CONFIG for more information.

This setting overrides the FormFill config at runtime for the script execution
only.

=cut

has 'FormFill' => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->asp->FormFill },
);

=item $Response->{IsClientConnected}

This is a carryover from Apache::ASP. However, Plack won't be able to detect
this so we will assume that the client is always connected. This will just
be true always for compatibility.

=cut

has 'IsClientConnected' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

# This attribute has no effect
has 'PICS' => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

=item $Response->{Status}

Sets the status code returned by the server. Can be used to set messages like
500, internal server error

=cut

has 'Status' => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

before 'Status' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting Status has no effect!'
    ) if scalar( @_ ) && $self->_headers_written;
};

sub BUILD {
    my ( $self ) = @_;

    no warnings 'redefine';
    *TIEHANDLE = sub {$self};
    $self->{BinaryRef} = \( $self->{Output} );

    # Due to problem mentioned above in the builder methods, we are calling
    # these attributes to populate the values for the hash key to be available
    $self->Cookies;
}

=back

=head1 METHODS

=over

=item $Response->AddHeader($name, $value)

Adds a custom header to a web page. Headers are sent only before any text from
the main page is sent.

=cut

has 'Headers' => (
    is          => 'rw',
    isa         => ArrayRef
        default => sub { [] },
);

sub AddHeader {
    my ( $self, $name, $value ) = @_;

    $self->asp->log->warn( sprintf(
            'Headers already written! Calling AddHeader with %s %s has no effect!',
            $name, $value
    ) ) if $self->_headers_written;

    # Don't duplicate these headers, set them for later
    if ( lc( $name ) eq 'content-type' ) {
        $self->ContentType( $value );
    } elsif ( lc( $name ) eq 'cache-control' ) {
        $self->CacheControl( $value );
    } elsif ( lc( $name ) eq 'expires' ) {
        $self->ExpiresAbsolute( $value );
    } else {
        push @{ $self->Headers }, $name => $value;
    }
}

sub PRINT { my $self = shift; $self->Write( $_ ) for @_ }

sub PRINTF {
    my ( $self, $format, @list ) = @_;
    $self->Write( sprintf( $format, @list ) );
}

=item $Response->AppendToLog($message)

Adds $message to the server log. Useful for debugging.

=cut

sub AppendToLog {
    my ( $self, $message ) = @_;
    $self->asp->log->debug( "$message\n" );
}

=item $Response->BinaryWrite($data)

Writes binary data to the client. The only difference from
C<< $Response->Write() >> is that C<< $Response->Flush() >> is called internally
first, so the data cannot be parsed as an html header. Flushing flushes the
header if has not already been written.

If you have set the C<< $Response->{ContentType} >> to something other than
C<text/html>, cgi header parsing (see CGI notes), will be automatically be
turned off, so you will not necessarily need to use C<BinaryWrite> for writing
binary data.

=cut

*BinaryWrite = *Write;

=item $Response->Clear()

Erases buffered ASP output.

=cut

sub Clear {
    my ( $self ) = @_;

    if ( $self->_content_writer ) {

        # If a _content_writer is defined, then no need to keep track of flushed
        # offset, simply clear Output buffer
        $self->clear_Output;

    } else {

        # Otherwise, keep track of last flushed offset and clear everything
        # after that point.
        defined $self->Output && $self->Output(
            $self->OutputSubstr( 0, $self->_flushed_offset )
        );
    }

    $self->{BinaryRef} = \( $self->{Output} );

    return;
}

=item $Response->Cookies($name, [$key,] $value)

Sets the key or attribute of cookie with name C<$name> to the value C<$value>.
If C<$key> is not defined, the Value of the cookie is set. ASP CookiePath is
assumed to be / in these examples.

  $Response->Cookies('name', 'value');
  # Set-Cookie: name=value; path=/

  $Response->Cookies("Test", "data1", "test value");
  $Response->Cookies("Test", "data2", "more test");
  $Response->Cookies(
    "Test", "Expires",
    HTTP::Date::time2str(time+86400)
  );
  $Response->Cookies("Test", "Secure", 1);
  $Response->Cookies("Test", "Path", "/");
  $Response->Cookies("Test", "Domain", "host.com");
  # Set-Cookie:Test=data1=test%20value&data2=more%20test; \
  #   expires=Fri, 23 Apr 1999 07:19:52 GMT;              \
  #   path=/; domain=host.com; secure

The latter use of C<$key> in the cookies not only sets cookie attributes such as
Expires, but also treats the cookie as a hash of key value pairs which can later
be accesses by

  $Request->Cookies('Test', 'data1');
  $Request->Cookies('Test', 'data2');

Because this is perl, you can (though it's not portable!) reference the cookies
directly through hash notation. The same 5 commands above could be compressed
to:

  $Response->{Cookies}{Test} = {
    Secure  => 1,
    Value   => {
      data1 => 'test value',
      data2 => 'more test'
    },
    Expires => 86400, # not portable, see above
    Domain  => 'host.com',
    Path    => '/'
  };

and the first command would be:

  # you don't need to use hash notation when you are only setting
  # a simple value
  $Response->{Cookies}{'Test Name'} = 'Test Value';

I prefer the hash notation for cookies, as this looks nice, and is quite
perl-ish. It is here to stay. The C<Cookie()> routine is very complex and does
its best to allow access to the underlying hash structure of the data. This is
the best emulation I could write trying to match the Collections functionality
of cookies in IIS ASP.

For more information on Cookies, please go to the source at
http://home.netscape.com/newsref/std/cookie_spec.html

=cut

# For some reason, for attributes that start with a capital letter, Moose seems
# to load the default value before the object is fully initialized. lazy => 1 is
# a workaround to build the defaults later
has 'Cookies' => (
    is          => 'rw',
    isa         => HashRef,
    reader      => '_get_Cookies',
    writer      => '_set_Cookies',
    lazy        => 1,
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        _get_Cookie => 'get',
        _set_Cookie => 'set',
    },
);

before '_set_Cookie' => sub {
    my $self = shift;
    $self->asp->log->warn(
        'Headers already written! Setting Cookies has no effect!'
    ) if $self->_headers_written;
};

sub Cookies {
    my ( $self, $name, @cookie ) = @_;

    if ( @cookie == 0 ) {
        return $self->_get_Cookies;
    } elsif ( @cookie == 1 ) {
        my $value = $cookie[0];
        $self->_set_Cookie( $name => { Value => $value } ) if defined $value;
        return $value;
    } else {
        my ( $key, $value ) = @cookie;
        if ( $key =~ m/secure|value|expires|domain|path|httponly/i ) {
            if ( my $existing = $self->_get_Cookie( $name ) ) {
                return $existing->{$key} = $value;
            } else {
                $self->_set_Cookie( $name => { $key => $value } );
                return $value;
            }
        } else {
            if ( my $existing = $self->_get_Cookie( $name ) ) {
                return $existing->{Value}{$key} = $value;
            } else {
                $self->_set_Cookie( $name => { Value => { $key => $value } } );
                return $value;
            }
        }
    }
}

sub CookiesHeaders {
    my ( $self ) = @_;

    my @headers;

    my $cookies = $self->_get_Cookies;
    for my $name ( keys %$cookies ) {

        # For CGI::Simple::Cookie constructor
        my %hash = ( '-name' => $name );

        my $cookie = $cookies->{$name};
        if ( ref $cookie eq 'HASH' ) {
            for my $key ( keys %$cookie ) {

                # This is really to support Apache::ASP's support for hashes
                # as a cookie value
                if ( $key =~ m/value/i && ref( $cookie->{$key} ) eq 'HASH' ) {
                    $hash{-value} = [
                        map {
                            "$_=" . $cookie->{$key}{$_}
                        } keys %{ $cookie->{$key} }
                    ];
                } else {

                    # Thankfully, don't need to make 'value' an arrayref for
                    # CGI::Simple::Cookie
                    $hash{ '-' . lc( $key ) } = $cookie->{$key};
                }
            }
        } else {
            $hash{-value} = $cookie;
        }

        push @headers,
            'Set-Cookie' => CGI::Simple::Cookie->new( %hash )->as_string;
    }

    return \@headers;
}

=item $Response->Debug(@args)

API Extension. If the Debug config option is set greater than C<0>, this routine
will write C<@args> out to server error log. Refs in C<@args> will be expanded
one level deep, so data in simple data structures like one-level hash refs and
array refs will be displayed. CODE refs like

  $Response->Debug(sub { "some value" });

will be executed and their output added to the debug output. This extension
allows the user to tie directly into the debugging capabilities of this module.

While developing an app on a production server, it is often useful to have a
separate error log for the application to catch debugging output separately.

If you want further debugging support, like stack traces in your code, consider
doing things like:

  $Response->Debug( sub { Carp::longmess('debug trace') };
  $SIG{__WARN__} = \&Carp::cluck; # then warn() will stack trace

The only way at present to see exactly where in your script an error occurred is
to set the Debug config directive to 2, and match the error line number to perl
script generated from your ASP script.

However, as of version C<0.10>, the perl script generated from the asp script
should match almost exactly line by line, except in cases of inlined includes,
which add to the text of the original script, pod comments which are entirely
yanked out, and C<< <% # comment %> >> style comments which have a C<\n> added
to them so they still work.

=cut

has 'Debug' => (
    is      => 'ro',
    default => 0,
    reader  => '_Debug',
);

sub Debug {
    my ( $self, @args ) = @_;
    local $Data::Dumper::Maxdepth = 2;
    $self->AppendToLog( Dumper( \@args ) );
}

=item $Response->End()

Sends result to client, and immediately exits script. Automatically called at
end of script, if not already called.

=cut

sub End {
    Plasp::Exception::End->throw;
}

# TODO will not implement
sub ErrorDocument {
    my ( $self, $code, $uri ) = @_;
    $self->asp->log->warn(
        "\$Response->ErrorDocument has not been implemented!"
    );
    return;
}

=item $Response->Flush()

Sends buffered output to client and clears buffer.

=cut

# A _headers_writer is a reference to a subroutine that takes two arguments:
# ( $status, $headers_array_ref )
has '_headers_writer' => (
    is  => 'rw',
    isa => CodeRef,
);

# A _content_writer is a reference to a subroutine that takes one argument:
# ( $data )
has '_content_writer' => (
    is  => 'rw',
    isa => CodeRef,
);

sub Flush {
    my ( $self ) = @_;
    $self->asp->GlobalASA->Script_OnFlush;

    # If this is the first Flush, need to write out the headers and begin the
    # response.
    unless ( $self->_headers_written ) {

        # Process the resulting response
        $self->Status || $self->Status( 200 );

        # Process the response headers
        # Set Content-Type header
        my $charset      = $self->Charset;
        my $content_type = $self->ContentType;
        $content_type .= "; charset=$charset" if $charset;
        push @{ $self->Headers }, 'Content-Type' => $content_type;

        # Set the Cookies
        push @{ $self->Headers }, @{ $self->CookiesHeaders };

        # Set the Cache-Control
        push @{ $self->Headers }, 'Cache-Control' => $self->CacheControl;

        # Set the Expires header from either Expires or ExpiresAbsolute
        # attribute
        if ( $self->Expires ) {
            push @{ $self->Headers },
                Expires => time2str( time + $self->Expires );
        } elsif ( $self->ExpiresAbsolute ) {
            push @{ $self->Headers }, Expires => $self->ExpiresAbsolute;
        }

        # In the case that streaming response is supported, a _headers_writer
        # should be defined. If so, use it to write out the Status and Headers
        if ( $self->_headers_writer ) {
            $self->_headers_writer->( $self->Status, $self->Headers );
        }

        # Headers are written, so don't write them out again, even if not
        # streaming response
        $self->_set_headers_written;
    }

    my $body = $self->Output;

    # Process HTML::FillInForm
    if ( $self->FormFill ) {
        my @errors;
        $body =~ s/(\<form[^\>]*\>.*?\<\/form\>)/
            {
                my $form = $1;

                # HTML::FillInForm::ForceUTF8->_get_param expects all form data
                # to be a string or an arrayref. File uploads are actually
                # objects (CGI::File::Temp), so there's a 500 error if the form
                # field tries to populate with that data. This loop removes any
                # form data that is a reference to something that isn't an
                # array.
                my $form_data = $self->asp->Request->Form;
                for ( keys %$form_data ) {
                    my $form_ref = ref $form_data->{$_};
                    delete $form_data->{$_}
                        if $form_ref && $form_ref ne 'ARRAY';
                }

                eval {
                    my $fif = HTML::FillInForm::ForceUTF8->new;
                    $form = $fif->fill(
                        scalarref => \$form,
                        fdat      => $form_data,
                    );
                };
                if ( $@ ) {
                    push @errors, $@;
                }

                $form;
            }
            /iexsg;
        if ( @errors ) {
            my $errors = join ' : ', @errors;
            Plasp::Exception::Code->throw( "HTML::FillInForm failed: $errors" );
        }
    }

    if ( my $charset = $self->Charset ) {
        $body = Encode::encode( $charset, $body );
    } elsif ( $self->ContentType =~ /text|javascript|json/ ) {
        $body = Encode::encode( 'UTF-8', $body );
    }

    if ( $self->_content_writer ) {

        # In the case that streaming response is supported, a _content_writer
        # should be defined. If so, use it to write out the body, then clear
        # Output buffer.
        $self->_content_writer->( $body );
        $self->Clear;

    } else {

        # If streaming response not supported, then keep track of a flushed
        # offset and save the output up to that point.
        $self->_flushed_offset( $self->OutputLength );
    }


}

=item $Response->Include($filename, @args)

This API extension calls the routine compiled from asp script in C<$filename>
with the args @args.  This is a direct translation of the SSI tag

  <!--#include file=$filename args=@args-->

Please see the SSI section for more on SSI in general.

This API extension was created to allow greater modularization of code by
allowing includes to be called with runtime arguments.  Files included are
compiled once, and the anonymous code ref from that compilation is cached, thus
including a file in this manner is just like calling a perl subroutine. The
C<@args> can be found in C<@_> in the includes like:

  # include.inc
  <% my @args = @_; %>

As of C<2.23>, multiple return values can be returned from an include like:

  my @rv = $Response->Include($filename, @args);

=item $Response->Include(\$script_text, @args)

Added in Apache::ASP C<2.11>, this method allows for executing ASP scripts that
are generated dynamically by passing in a reference to the script data instead
of the file name. This works just like the normal C<< $Response->Include() >>
API, except a string reference is passed in instead of a filename. For example:

  <%
    my $script = "<\% print 'TEST'; %\>";
    $Response->Include(\$script);
  %>

This include would output C<TEST>. Note that tokens like C<< <% >> and C<< %> >>
must be escaped so Apache::ASP does not try to compile those code blocks
directly when compiling the original script. If the C<$script> data were fetched
directly from some external resource like a database, then these tokens would
not need to be escaped at all as in:

  <%
    my $script = $dbh->selectrow_array(
       "select script_text from scripts where script_id = ?",
       undef, $script_id
       );
    $Response->Include(\$script);
  %>

This method could also be used to render other types of dynamic scripts, like
XML docs using XMLSubs for example, though for complex runtime XML rendering,
one should use something better suited like XSLT.

=cut

sub Include {
    my ( $self, $include, @args ) = @_;
    my $asp = $self->asp;

    my $compiled;
    if ( ref( $include ) && ref( $include ) eq 'SCALAR' ) {
        my $scriptref     = $include;
        my $parsed_object = $asp->parse( $scriptref );
        $compiled = {
            mtime => time(),
            perl  => $parsed_object->{data},
        };
        my $caller = [ caller( 1 ) ]->[3] || 'main';
        my $id    = join( '', '__ASP_', $caller, 'x', $asp->_compile_checksum );
        my $subid = join( '', $asp->GlobalASA->package, '::', $id, 'xREF' );
        if ( $parsed_object->{is_perl}
            && ( my $code = $asp->compile(
                    $parsed_object->{data},
                    $subid ) ) ) {
            $compiled->{is_perl} = 1;
            $compiled->{code}    = $code;
        } else {
            $compiled->{is_raw} = 1;
            $compiled->{code}   = $parsed_object->{data};
        }
    } else {
        $compiled = $asp->compile_include( $include );
        return unless $compiled;
    }

    my $code = $compiled->{code};

    # exit early for cached static file
    if ( $compiled->{is_raw} ) {
        $self->WriteRef( $code );
        return;
    }

    $asp->execute( $code, @args );
}

=item $Response->Redirect($url)

Sends the client a command to go to a different url C<$url>. Script immediately
ends.

=cut

sub Redirect {
    my ( $self, $url ) = @_;

    $self->Status( 302 );
    $self->AddHeader( Location => $url );
    $self->Clear;

    Plasp::Exception::Redirect->throw;
}

=item $Response->TrapInclude($file, @args)

Calls $Response->Include() with same arguments as passed to it, but instead
traps the include output buffer and returns it as as a perl string reference.
This allows one to postprocess the output buffer before sending to the client.

  my $string_ref = $Response->TrapInclude('file.inc');
  $$string_ref =~ s/\s+/ /sg; # squash whitespace like Clean 1
  print $$string_ref;

The data is returned as a referenece to save on what might be a large string
copy. You may dereference the data with the $$string_ref notation.

=cut

sub TrapInclude {
    my ( $self, $include, @args ) = @_;

    # In order to "trap" the include, gotta setup local variables so that
    # anthing overwritten under this scope will automatically get restored
    # after this function. local is a real neat feature of Perl.
    local $self->{Output} = '';
    local $self->{BinaryRef} = \( $self->{Output} );
    local $self->{_content_writer} = undef

    # Not sure why, but if I set this to zero in one line, it ends up warning
    # of modification of a readonly value
    local $self->{_flushed_offset};
    $self->_flushed_offset( 0 );

    $self->Include( $include, @args );

    return \( $self->{Output} );
}

=item $Response->Write($data)

Write output to the HTML page. C<< <%=$data%> >> syntax is shorthand for a
C<< $Response->Write($data) >>. All final output to the client must at some
point go through this method.

=cut

sub WriteRef {
    my ( $self, $dataref ) = @_;
    $self->Write( $$dataref );
}

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp::Session>

=item * L<Plasp::Request>

=item * L<Plasp::Application>

=item * L<Plasp::Server>

=back
