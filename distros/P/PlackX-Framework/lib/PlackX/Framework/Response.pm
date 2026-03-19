use v5.36;
package PlackX::Framework::Response {
  use parent 'Plack::Response';
  use PXF::Util ();

  use Plack::Util::Accessor qw(stash cleanup_callbacks template stream stream_writer);
  sub GlobalResponse ($class)           { ($class->app_namespace.'::Handler')->global_response }
  sub next                              { return;    }
  sub stop                              { $_[0] || 1 }
  sub add_cleanup_callback($self, $sub) { push @{$self->{cleanup_callbacks}}, $sub }
  sub flash_cookie_name         ($self) { PlackX::Framework::flash_cookie_name($self->app_namespace)  }
  sub render_json         ($self, $dat) { $self->render_content('application/json', PXF::Util::encode_json($dat)) }
  sub render_text         ($self, $str) { $self->render_content('text/plain'      , $str            ) }
  sub render_html         ($self, $str) { $self->render_content('text/html'       , $str            ) }
  sub render_stream       ($self, $sub) { $self->stream($sub); $self                                  }
  sub render_template     ($self, @ops) { $self->{template}->render(@ops); $self                      }
  sub finalize                  ($self) { $self->stream ? $self->finalize_sb : $self->SUPER::finalize }

  sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);
    $self->{cleanup_callbacks} //= [];
    $self->{body}              //= [];
    return bless $self, $class;
  }

  sub set_defaults ($self) {
    $self->charset('utf8');
    $self->content_type('text/html');
    $self->status(200);
    return $self;
  }

  sub charset ($self, $newval=undef) {
    if (!defined $newval) {
      my (@conttype) = $self->SUPER::content_type;
      foreach my $el (@conttype) {
        $newval = $1 if $el =~ m/^charset=(.*)$/;
      }
    }
    if (defined $newval) {
      $self->{charset} = $newval;
      $self->content_type;
    }
    return $self->{charset};
  }

  sub content_type ($self, $newval=undef) {
    return $self->SUPER::content_type(defined $newval ? $newval : ())
      if !$self->{charset} or ($newval and $newval =~ m/charset=/i);

    # The way content_type is handled by HTTP::Headers(::Fast) is a bit weird.
    # The getter returns an array with the elements split up.
    # But the setter won't take an array, only a string.
    my (@ct) = defined $newval ? ($newval,) : ($self->SUPER::content_type,);
    @ct = grep { $_ !~ m/^charset=/i } @ct;
    push @ct, 'charset='.$self->{charset};

    return $self->SUPER::content_type(join '; ', @ct);
  }

  sub finalize_sb ($self) {
    # Finalize Streaming Body
    my $original_body = $self->body;
    $self->body(undef);
    my $aref = $self->SUPER::finalize;
    $self->body($original_body);
    pop @$aref;
    return $aref;
  }

  sub print ($self, @lines) {
    if ($self->stream_writer) {
      unshift @lines, @{$self->{body}} and $self->{body} = undef
        if $self->body;
      $self->stream_writer->write($_) for @lines; # write() does not take a list!
      return $self;
    }
    push @{$self->{body}}, @lines;
    return $self;
  }

  sub no_cache ($self, $bool) {
    my $val = $bool ? 'no-cache' : undef;
    $self->header('Pragma' => $val, 'Cache-control' => $val);
  }

  sub flash ($self, $value = undef) {
    # Note: String values are automatically url-encoded by Cookie::Baker
    # If value is false we delete the cookie, so set max-age negative
    # Otherwise set it to 20 minutes (it will be deleted on next request)
    my $max_age = $value ? 60*20 : -1;
    my $cname   = $self->flash_cookie_name;
    $value //= '';

    $value = "$cname-ju64-" . PXF::Util::encode_ju64($value) if ref $value;
    $self->cookies->{$cname} = { value=>$value, path=>'/', 'max-age'=>$max_age, samesite=>'strict' };
    return $self;
  }

  sub flash_redirect ($self, $flashval, $url) {
    return $self->flash($flashval)->redirect($url, 303);
  }

  sub redirect ($self, $url, $code=303) {
    $self->SUPER::redirect($url, $code);
    return $self;
  }

  sub render_content ($self, $content_type, $content) {
    $self->status(200);
    $self->content_type($content_type);
    $self->print($content);
    return $self;
  }

  sub render ($self, $type, @params) {
    if (my $sub = $self->can("render_$type")) {
      return $sub->($self, @params);
    }
    die "$self does not know how to render_$type";
  }
}

1;

=pod

=head1 NAME

PlackX::Framework::Response - Subclass of Plack::Response for PlackX::Framework


=head1 CLASS METHODS

=over 4

=item new()

Returns a new object. This is done for you by the framework.

=item GlobalResponse()

If your app's subclass of PlackX::Framework::Handler's
use_global_request_response method returns a true value, PlackX::Framework
will set up a global response object for you, which can be retrieved via this
class method.

This feature is turned off by default to avoid action-at-a-distance bugs. It
is preferred to use the request object instance passed to each route's
subroutine.

=back


=head1 OBJECT METHODS

=over 4

=item charset(), charset($newval)

Get or set the charset portion of the content-type header.

=item content_type(), content_type($newval)

Like Plack::Response, this is a shortcut for HTTP::Headers::Fast->content_type;
however, if a charset has been set with the charset() method, it will add the
charset to the content-type header, if no charset is specified in $newval.

=item flash(value)

Sets the flash cookie to the value specified, or clears it if the value is
false. PXF automatically clears the cookie on the subsequent request, unless
you set a different one.

=item flash_redirect(value, url)

Combines flash(value) and redirect(url) with a 303 (SEE OTHER) response code.

=item next()

Syntactic sugar for returning a false value. Indicates to PlackX::Framework
to execute the next matching filter.

    return $response->next; # equivalent to return;

See also the stop() method below.

=item no_cache(BOOL)

If passed a true value, adds HTTP Pragma and Cache-Control headers to "no-cache".
If passed a false value, sets these headers to empty string.

=item print($string), print(@strings)

Adds $string or @strings to the response body, or write them to the PSGI
output stream if streaming mode has been activated (see the render_stream()
and stream() methods below).

When streaming is activated, you should append your print strings with newlines
to encourage the server (and browser) to flush the buffer.

Unfortunately, the PSGI specification does not provide a way to flush the
buffer, but if you are using a server that allows this, perhaps you could do:

    $response->print($string);
    $response->stream_writer->flush_buffer();

Or override print in your subclass:

    package MyApp::Response {
      use parent 'PlackX::Framework::Response';
      sub print ($self, @lines) {
        $self->SUPER::print(@lines);
        $self->stream_writer->flush_buffer() if $self->stream_writer;
      }
    }

=item redirect($url, $http_status)

Like Plack::Response->redirect, except the default http status is 303 See Other
instead of 302 Found. This matches the more common type of redirect in a web
app, which is directing the user to another page after a prevous request was
processed (such as a log in form).

=item render($key => @values)

An alias for $obj->render_$key(@values). For example, instead of calling
render_html(...), you could call render(html => ...). Used by PXF's Router
module to implement shortcuts to the appropriate $response->render_*() method.

=item render_html($string)

Sets the content-type to text/html and sets the response body to $string.

=item render_json($ref)

Sets the content-type to application/json and encodes $ref to JSON, setting
the response body to the resulting string.

=item render_stream(CODE)

Call stream() with CODE and return the response object.

Example:

    route '/stream-example' => sub ($request, $response) {
      $response->print(...); # html header
      return $response->render_stream(sub {
        # Do some slow actions
        $response->print(...);
        # Do more slow actions
      });
    };

=item render_template(@args)

Shortcut for $obj->template->render(@ags)

=item render_text($string)

Sets the content-type to text/plain and sets the response body to $string.

=item set_defaults()

Set defaults for the response object. This method is called automatically by
PlackX::Framework::Handler.

=item stash(), stash($hashref)

Returns the current stash hashref, optionally setting it to a new one.

=item stream(CODE)

Get or set a code reference for PSGI streaming. It is recommended you simply
return render_stream(CODE) as described above, but you can use this directly
like the below example.


Example:

    route '/stream-example' => sub ($request, $response) {
      $response->stream(sub {
        $response->print('I am in a stream!');
      });
      # Anything you do here will be executed BEFORE the stream code!
      $response->print('I am before the stream!');
      return $response;
    };


=item stop()

Syntactic sugar for returning the object itself. Indicates to PlackX::Framework
that it should render the response. Useful for semantics in filter actions. The
default router engine does not support multiple matching routes, so not so
useful in route actions. See also the equivalent inverse method, next().

    # In a filter
    return $response->stop; # equivalent to return $response;

=item template()

Returns the PlackX::Framework::Template object, or undef if templating has not
been set up.

=back


=head1 META

For author, copyright, and license, see PlackX::Framework.
