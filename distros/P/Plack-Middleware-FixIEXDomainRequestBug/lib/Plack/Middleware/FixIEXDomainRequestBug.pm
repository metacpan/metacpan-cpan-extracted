package Plack::Middleware::FixIEXDomainRequestBug;

use strict;
use warnings;
use base 'Plack::Middleware';
use Plack::Util::Accessor 'force_content_type', 'guess_with';

our $VERSION = '0.001';

sub is_POST { uc(pop->{REQUEST_METHOD}) eq 'POST' ? 1:0 };

sub missing_or_textplain_content { 
  if(my $content_type = pop->{CONTENT_TYPE}) {
    return lc($content_type) eq 'text/plain' ? 1:0;
  } else {
    return 1;
  }
}

sub is_ie8_or9 {
  my ($v) = lc(pop->{HTTP_USER_AGENT}||'')=~m/msie\s(\d).+?;/i; # Works for all Version of IE I know
  return $v && ($v eq '8' || $v eq '9') ? 1:0;
}

sub meets_criteria {
  my ($self, $env) = @_;
  if(
    $self->is_POST($env) &&
    $self->missing_or_textplain_content($env) &&
    $self->is_ie8_or9($env)
  ) {
    return 1;
  } else {
    return 0;
  }
}

sub provide_content_type {
  my ($self, $env) = @_;
  if(my $force = $self->force_content_type) {
    return $force;
  } elsif (my $code = $self->guess_with) {
    return $code->($env);
  } 
}

sub prepare_app {
  my $self = shift;
  unless ($self->force_content_type || $self->guess_with) {
    die "You must set either 'force_content_type' or 'guess_with' in order to use the FixIEXDomainRequestBug middleware.";
  }
}

sub call {
  my($self, $env) = @_;
  if($self->meets_criteria($env)) {
    if(my $new_content_type = $self->provide_content_type($env)) {
      $env->{'plack.middleware.fixiexdomainrequestbug.overrode_content_type'} = 1;
      $env->{'CONTENT_TYPE'} = $new_content_type;
    } else {
      warn "You asked me to fix the IE XDomainRequest bug, but I could not provide a new content-type.";
    }
  }

  return $self->app->($env);
}

1;

=head1 NAME

Plack::Middleware::FixIEXDomainRequestBug - Fix IE8/IE9 XDomainRequest Missing Content Type 

=head1 SYNOPSIS

The Following two examples encompass most likely usage

=head2 Specify Mimetype

Specify the mimetype (assumes you control all ends)

    use Plack::Builder;
    builder {
      enable 'FixIEXDomainRequestBug',
        force_content_type => 'application/json';
      $app;
    };

=head2 Custom Provider

Use some custom code to provide a valid mimetype

    use Plack::Builder;
    builder {
      enable 'FixIEXDomainRequestBug',
        guess_with  => sub {
          my $env = shift;
          if($env->{PATH_INFO} =~ m{^/api}) {
            return 'application/json';
          } else {
            return 'application/x-www-form-urlencoded';
          }
        };
      $app;
    };

You may also consider strategies where you apply the middleware differently
under different mount points.

=head1 DESCRIPTION

Here's a good explanation of the issue we are attempting to solve:

L<http://blogs.msdn.com/b/ieinternals/archive/2010/05/13/xdomainrequest-restrictions-limitations-and-workarounds.aspx>

Basically Internet Explorer 8 and 9 have a proprietary approach to allow cross
domain AJAX safely.  However in the attempt to lock down the interface as much
as possible Microsoft introduced what is widely considered a major bug, which
vastly decreases the value of the feature.  What happens is that any type of
attempt to use the XDomainRequest activeX control sets the request content type
to nothing or text/plain (the docs say text/plain is the only type allowed, but
web search and the experience we have seen is that the content type is empty).
As a result, when a framework like L<Catalyst> trys to parse the POST body, it
can't figure out what to do, so it punts, typically busting this code.  Since
it is common with web applications to use a Javascript framework to paper over
browser differences, this means that an application doing cross domain access
might easily work with Firefox but totally bust with IE 8 or 9 (at the time of
this writing these browsers are still the most popular for people using Windows
on the desktop, and typically represent 20%+ total web traffic)

This distribution attempts to solve this problem at the middleware level.  What
it does is check to see if the user agent identifies itself as Internet Explorer
8 or 9, AND the method is POST (only GET and POST http methods are allowed with
XDomainRequest anyway) AND content-type is nothing or text/plain, THEN we do
of the following:

We create the following custom key

    $env->{'plack.middleware.fixiexdomainrequestbug.overrode_content_type'} = 1

You can test if this value is true to detect if we changed the C<content-type>,
should you wish to know (might be useful for debugging).

Then we change $env->{'CONTENT_TYPE'} in one of the following ways

If you've specified a C<force_content_type> configuration, we always use that,
and change the http content type to match.

Otherwise, if you've set a C<guess_with> configuration we assume that is an
anonymous sub and invoke that with $env.  That coderef is expected to return
a string which is a valid C<content-type>.  Commonly you may wish to set a
custom search query parameter as a fallback mechanism for setting the 
C<Content_Type>, or set the expected content-type based on the requested path (
as seen in the L</SYNOPSIS> example.

    use Plack::Builder;
    builder {
      enable 'FixIEXDomainRequestBug',
        guess_with  => sub {
          my $env = shift;
          my $req = Plack::Request->new($env);

          ## Assume a request url like "http://myapp.com/path?format=application/json"
          return $req->query_parameters->get('format')
        };
      $app;
    };

=head1 ATTRIBUTES

This middleware has the following attributes used to inform how a missing or
invalid HTTP C<Content_Type> is altered.  The listing is in order of priority.

It goes without saying that although both attributes are not required, you need
at least one of them for the middleware to function.

See L</SYNOPSIS> for examples.

=head2 force_content_type

String: Default is empty, not required.

This is a string which must be, if defined, a valid mimetype suitable for
populating the HTTP Header C<Content_Type>.  If this attribute is set, and
a request meeting the defined criteria is detected, the C<Content_Type> is
forced to the set value.

=head2 guess_with

CodeRef: Default is empty, not required.

This coderef is used if you wish to create a custom mechanism for figuring out
what the C<Content_Type> should be when the defined criteria (described above)
is detected.  It gets passed the L<PSGI> env and is expected to return a string
which is suitable as a value for HTTP Header C<Content_Type>.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2013, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
