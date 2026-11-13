package Net::DAVTalk;

use strict;

use Carp;
use DateTime::Format::ISO8601;
use DateTime::TimeZone;
use HTTP::Tiny;
use JSON;
use Tie::DataUUID qw{$uuid};
use XML::Spice;
use Net::DAVTalk::XMLParser;
use MIME::Base64 qw(encode_base64);
use Encode qw(encode);
use URI::Escape qw(uri_escape uri_unescape);
use URI;

=head1 NAME

Net::DAVTalk - Interface to talk to DAV servers

=head1 VERSION

Version 0.24

=cut

our $VERSION = '0.26';

=head1 SYNOPSIS

Net::DAVTalk is was originally designed as a service module for Net::CalDAVTalk
and Net::CardDAVTalk, abstracting the process of connecting to a DAV server and
parsing the XML responses.

Example:

    use Net::DAVTalk;
    use XML::Spice;

    my $davtalk = Net::DAVTalk->new(
        url => "https://dav.example.com/",
        user => "foo\@example.com",
        password => "letmein",
        headers => { Cookie => "123", Referer => "456" },
    );

    $davtalk->Request(
        'MKCALENDAR',
        "$calendarId/",
        x('C:mkcalendar', $Self->NS(),
            x('D:set',
                 x('D:prop', @Properties),
            ),
        ),
    );

    $davtalk->Request(
        'DELETE',
        "$calendarId/",
    );

=head1 SUBROUTINES/METHODS

=head2 $class->new(%Options)

Options:

    url: either full https?:// url, or relative base path on the
    server to the DAV endpoint

    host, scheme and port: alternative to using full URL.
    If URL doesn't start with https?:// then these will be used to
    construct the endpoint URI.

    expandurl and wellknown: if these are set, then the wellknown
    name (caldav and carddav are both defined) will be used to
    resolve /.well-known/$wellknown to find the current-user-principal
    URI, and then THAT will be resovlved to find the $wellknown-home-set
    URI, which will be used as the URL for all further actions on
    this object.

    user and password: if these are set, perform basic authentication.
    user and access_token: if these are set, perform Bearer (OAUTH2)
    authentication.

    headers: a hashref of additional headers to add to every request

    SSL_options: a hashref of SSL options to pass down to the default
    user agent
=cut

# General methods

sub new {
  my ($Class, %Params) = @_;

  unless ($Params{url}) {
    confess "URL not supplied";
  }

  # Assume url points to xyz-home-set, otherwise expand the url
  if (delete $Params{expandurl}) {
    # Locating Services for CalDAV and CardDAV (RFC6764)
    my $PrincipalURL = $Class->GetCurrentUserPrincipal(%Params);
    $Params{principal} = $PrincipalURL;

    my $HomeSet = $Class->GetHomeSet(
      %Params,
      url => $PrincipalURL,
    );

    $Params{url} = $HomeSet;
  }

  my $Self = bless \%Params, ref($Class) || $Class;
  $Self->SetURL($Params{url});
  $Self->SetPrincipalURL($Params{principal});
  $Self->ns(D => 'DAV:');

  return $Self;
}

=head2 my $ua = $Self->ua();
=head2 $Self->ua($setua);

Get or set the useragent (HTTP::Tiny or compatible) that will be used to make
the requests:

e.g.

    my $ua = $Self->ua();

    $Self->ua(HTTP::Tiny->new(agent => "MyAgent/1.0", timeout => 5));

=cut

sub ua {
  my $Self = shift;
  if (@_) {
    $Self->{ua} = shift;
  }
  else {
    $Self->{ua} ||= HTTP::Tiny->new(
      agent => "Net-DAVTalk/$VERSION",
      SSL_options => $Self->{SSL_options},
    );
  }
  return $Self->{ua};
}

=head2 $Self->SetURL($url)

Change the endpoint URL for an existing connection.

=cut

sub SetURL {
  my ($Self, $URL) = @_;

  $URL =~ s{/$}{}; # remove any trailing slash

  if ($URL =~ m{^https?://}) {
    my ($HTTPS, $Hostname, $Port, $BasePath)
      = $URL =~ m{^http(s)?://([^/:]+)(?::(\d+))?(.*)?};

    unless ($Hostname) {
      confess "Invalid hostname in '$URL'";
    }

    $Self->{scheme}   = $HTTPS ? 'https' : 'http';
    $Self->{host}     = $Hostname;
    $Self->{port}     = ($Port || ($HTTPS ? 443 : 80));
    $Self->{basepath} = $BasePath;
  }
  else {
    $Self->{basepath} = $URL;
  }

  $Self->{url} = "$Self->{scheme}://$Self->{host}:$Self->{port}$Self->{basepath}";

  return $Self->{url};
}

=head2 $Self->SetPrincipalURL($url)

Set the URL to the DAV Principal

=cut

sub SetPrincipalURL {
  my ($Self, $PrincipalURL) = @_;

  return $Self->{principal} = $PrincipalURL;
}

=head2 $Self->fullpath($shortpath)

Convert from a relative path to a full path:

e.g
    my $path = $Dav->fullpath('Default');
    ## /dav/calendars/user/foo/Default

NOTE: a you can pass a non-relative full path (leading /)
to this function and it will be returned unchanged.

=cut

sub fullpath {
  my $Self = shift;
  my $path = shift;
  my $basepath = $Self->{basepath};
  return $path if $path =~ m{^/};
  return "$basepath/$path";
}

=head2 $Self->shortpath($fullpath)

Convert from a full path to a relative path

e.g
    my $path = $Dav->fullpath('/dav/calendars/user/foo/Default');
    ## Default

NOTE: if the full path is outside the basepath of the object, it
will be unchanged.

    my $path = $Dav->fullpath('/dav/calendars/user/bar/Default');
    ## /dav/calendars/user/bar/Default

=cut

sub shortpath {
  my $Self = shift;
  my $origpath = shift;
  my $basepath = $Self->{basepath};
  my $path = $origpath;
  $path =~ s{^$basepath/?}{};
  return ($path eq '' ? $origpath : $path);
}

=head2 $Self->Request($method, $path, $content, %headers)

The whole point of the module!  Perform a DAV request against the
endpoint, returning the response as a parsed hash.

   method: http method, i.e. GET, PROPFIND, MKCOL, DELETE, etc

   path: relative to base url.  With a leading slash, relative to
         server root, i.e. "Default/", "/dav/calendars/user/foo/Default".

   content: if the method takes a body, raw bytes to send

   headers: additional headers to add to request, i.e (Depth => 1)

In the event of timeout or most HTTP errors, an exception will be raised.

=head2 $Self->SafeRequest($method, $path, $content, %headers)

  my $Result = $DAVTalk->SafeRequest($method, $path, $content, %headers)

This is mostly Request, but it won't throw an exception on most errors.

Instead, it always returns a reference to a hash with these entries:

  payload       - a structured representation of the DAV response, if possible;
                  this is the same thing that the ->Request method returns
  http_response - the underlying HTTP response from HTTP::Tiny
  error         - a string describing the error condition, if any

The C<Request> method uses C<SafeRequest> under the hood, converting error
results into exceptions.

=cut

sub SafeRequest {
  my ($Self, $Method, $Path, $Content, %Headers) = @_;

  # setup request {{{

  $Content = '' unless defined $Content;
  my $Bytes = encode('UTF-8', $Content);

  my $ua = $Self->ua();

  $Headers{'Content-Type'} //= 'application/xml; charset=utf-8';

  if ($Self->{user}) {
    $Headers{'Authorization'} = $Self->auth_header();
  }

  %Headers = (%Headers, %{$Self->{headers}}) if $Self->{headers};

  # XXX - Accept-Encoding for gzip, etc?

  # }}}

  # send request {{{

  my $URI = $Self->request_url($Path);

  my $Response = $ua->request($Method, $URI, {
    headers => \%Headers,
    content => $Bytes,
  });

  if ($Response->{status} == '599' and $Response->{content} =~ m/timed out/i) {
    return {
      http_response => $Response,
      error         => "Error with $Method for $URI (504, Gateway Timeout)",
    };
  }

  my $count = 0;
  while ($Response->{status} =~ m{^30[1278]} and (++$count < 10)) {
    my $location = URI->new_abs($Response->{headers}{location}, $URI);
    if ($ENV{DEBUGDAV}) {
      warn "******** REDIRECT ($count) $Response->{status} to $location\n";
    }

    $Response = $ua->request($Method, $location, {
      headers => \%Headers,
      content => $Bytes,
    });

    if ($Response->{status} == '599' and $Response->{content} =~ m/timed out/i) {
      return {
        http_response => $Response,
        error         => "Error with $Method for $location (504, Gateway Timeout)",
      };
    }
  }

  # one is enough

  my $ResponseContent = $Response->{content} || '';

  if ($ENV{DEBUGDAV}) {
    warn "<<<<<<<< $Method $URI HTTP/1.1\n$Bytes\n" .
         ">>>>>>>> $Response->{protocol} $Response->{status} $Response->{reason}\n$ResponseContent\n" .
         "========\n\n";
  }

  if ($Method eq 'REPORT' && $Response->{status} == 403) {
    # maybe invalid sync token, need to return that fact
    my $Xml = xmlToHash($ResponseContent);
    if (exists $Xml->{"{DAV:}valid-sync-token"}) {
      # This weird "return error in payload" behavior is legacy behavior, and
      # quite possibly should be changed.  It's the only place we returned an
      # "error" in the hashref from Request before writing SafeRequest.
      # -- rjbs, 2026-02-11
      return {
        http_response => $Response,
        payload       => { error => "valid-sync-token" },
      };
    }
  }

  unless ($Response->{success}) {
    return {
      http_response => $Response,
      error         => "ERROR WITH REQUEST\n"
       . "<<<<<<<< $Method $URI HTTP/1.1\n$Bytes\n"
       . ">>>>>>>> $Response->{protocol} $Response->{status} $Response->{reason}\n$ResponseContent\n"
       . "========\n\n",
    };
  }

  if ((grep { $Method eq $_ } qw{GET DELETE}) or ($Response->{status} != 207) or (not $ResponseContent)) {
    return {
      http_response => $Response,
      payload       => { content => $ResponseContent },
    };
  }

  # }}}

  # parse XML response {{{
  my $Xml = xmlToHash($ResponseContent);

  # Normalise XML

  if (exists($Xml->{"{DAV:}response"})) {
    if (ref($Xml->{"{DAV:}response"}) ne 'ARRAY') {
      $Xml->{"{DAV:}response"} = [ $Xml->{"{DAV:}response"} ];
    }

    foreach my $Response (@{$Xml->{"{DAV:}response"}}) {
      if (exists($Response->{"{DAV:}propstat"})) {
        unless (ref($Response->{"{DAV:}propstat"}) eq 'ARRAY') {
          $Response->{"{DAV:}propstat"} = [$Response->{"{DAV:}propstat"}];
        }
      }
    }
  }

  return {
    http_response => $Response,
    payload       => $Xml,
  };

  # }}}
}

sub Request {
  my ($Self, @Rest) = @_;
  my ($Struct) = $Self->SafeRequest(@Rest);

  if ($Struct->{error}) {
    confess $Struct->{error};
  }

  return $Struct->{payload};
}

=head2 $Self->GetProps($Path, @Props)

perform a propfind on a particular path and get the properties back

=cut

sub GetProps {
  my ($Self, $Path, @Props) = @_;
  my @res = $Self->GetPropsArray($Path, @Props);
  return wantarray ? map { $_->[0] } @res : $res[0][0];
}

=head2 $Self->GetPropsArray($Path, @Props)

perform a propfind on a particular path and get the properties back
as an array of one or more items

=cut

sub GetPropsArray {
  my ($Self, $Path, @Props) = @_;

  # Fetch one or more properties.
  #  Use [ 'prop', 'sub', 'item' ] to dig into result structure

  my $NS_D = $Self->ns('D');

  my $Response = $Self->Request(
    'PROPFIND',
    $Path,
    x('D:propfind', $Self->NS(),
      x('D:prop',
        map { ref $_ ? x($_->[0]): x($_) } @Props,
      ),
    ),
    Depth => 0,
  );

  my @Results;
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
      my $PropData = $Propstat->{"{$NS_D}prop"} || next;
      for my $Prop (@Props) {
        my @Values = ($PropData);

        # Array ref means we need to git through structure
        foreach my $Key (ref $Prop ? @$Prop : $Prop) {
          my @New;
          foreach my $Result (@Values) {
            if ($Key =~ m/:/) {
              my ($N, $P) = split /:/, $Key;
              my $NS = $Self->ns($N);
              $Result = $Result->{"{$NS}$P"};
            } else {
              $Result = $Result->{$Key};
            }
            if (ref($Result) eq 'ARRAY') {
              push @New, @$Result;
            }
            elsif (defined $Result) {
              push @New, $Result;
            }
          }
          @Values = @New;
        }

        push @Results, [ map { $_->{content} } @Values ];
      }
    }
  }

  return wantarray ? @Results : $Results[0];
}

=head2 $Self->SyncCollection($Path, %Args)

WebDAV Collection Synchronization (RFC 6578): a sync-collection REPORT
on the collection at $Path, at sync-level 1, from $Args{syncToken} or,
without one, from nothing (every member is reported as added).

Returns, in list context:

* Added: hash of href to etag - members added or changed
* Removed: array of href - members removed
* Errors: array of descriptive strings
* SyncToken: the new opaque DAV:sync-token

and in scalar context just Added.

A server may truncate the results (RFC 6578 section 3.6), marking the
response with a 507 status on the collection itself.  The REPORT is then
repeated from the token that came with it until the results are whole,
so one call always reports every change; a member reported again in a
later round counts as what that round says.  If a truncated response
comes back with the token it was asked from, the server is not moving
on: what has arrived so far is returned with an error.

Dies if the server gives no sync-token: such a response cannot be
synced from again.

Arguments:

* syncToken - the token to sync from (none, undef or '' for a full sync)
* raw - return hrefs as the server wrote them, instead of unescaped as
  every other href from this module is (see request_url)
* MaxRounds - give up (die) after this many truncated responses
  (default 1000)

=cut

sub SyncCollection {
  my ($Self, $Path, %Args) = @_;

  confess "Need a collection path" unless defined $Path and length $Path;
  $Path =~ s{/$}{};

  my $NS_D = $Self->ns('D');
  my $Token = $Args{syncToken};
  my $MaxRounds = defined $Args{MaxRounds} ? $Args{MaxRounds} : 1000;
  my (%Added, %Removed, @Errors);

  for (my $Round = 1; ; $Round++) {
    my $Response = $Self->Request(
      'REPORT',
      "$Path/",
      x('D:sync-collection', $Self->NS(),
        x('D:sync-token', ((defined $Token and length $Token) ? ($Token) : ())),
        x('D:sync-level', 1),
        x('D:prop',
          x('D:getetag'),
        ),
      ),
    );

    my $NewToken = $Response->{"{$NS_D}sync-token"}{content};
    confess "No sync-token in the sync-collection response for $Path"
      unless defined $NewToken and length $NewToken;

    my $Truncated;
    foreach my $Item (@{$Response->{"{$NS_D}response"} || []}) {
      my $href = $Item->{"{$NS_D}href"}{content};
      next unless defined $href and length $href;
      $href = uri_unescape($href) unless $Args{raw};

      # For members that have been removed, the DAV:response MUST
      # contain one DAV:status with a value set to '404 Not Found' and
      # MUST NOT contain any DAV:propstat element.  A 507 there is on the
      # request-URI itself, and says the results were truncated.
      unless ($Item->{"{$NS_D}propstat"}) {
        my $Status = $Item->{"{$NS_D}status"}{content};
        $Status = '' unless defined $Status;
        if ($Status =~ m/ 404 /) {
          delete $Added{$href};
          $Removed{$href} = 1;
        }
        elsif ($Status =~ m/ 507 /) {
          $Truncated = 1;
        }
        else {
          push @Errors, "Odd status in non-propstat response $href: $Status";
        }
        next;
      }

      # iCloud lists the collection itself, with an etag, among the
      # changes (and refuses its URL in a multiget): a collection is not
      # a member to sync
      next if $href =~ m{/$};

      # For members that have changed (i.e., are new or have had their
      # mapped resource modified), the DAV:response MUST contain at
      # least one DAV:propstat element and MUST NOT contain any
      # DAV:status element.
      foreach my $Propstat (@{$Item->{"{$NS_D}propstat"}}) {
        my $Status = $Propstat->{"{$NS_D}status"}{content};
        $Status = '' unless defined $Status;
        if ($Status =~ m/ 200 /) {
          $Added{$href} = $Propstat->{"{$NS_D}prop"}{"{$NS_D}getetag"}{content};
          delete $Removed{$href};
        }
        elsif ($Status =~ m/ 404 /) {
          # a property the server does not have: not an error
        }
        else {
          push @Errors, "Odd status in propstat response $href: $Status";
        }
      }
    }

    my $Stuck = (defined $Token and $NewToken eq $Token);
    $Token = $NewToken;
    last unless $Truncated;
    if ($Stuck) {
      push @Errors, "sync-collection of $Path truncated without a new sync-token";
      last;
    }
    confess "sync-collection of $Path still truncated after $Round rounds"
      if $Round >= $MaxRounds;
  }

  my @Removed = sort keys %Removed;
  return wantarray ? (\%Added, \@Removed, \@Errors, $Token) : \%Added;
}

=head2 $Self->GetCurrentUserPrincipal()
=head2 $class->GetCurrentUserPrincipal(%Args)

Can be called with the same args as new() as a class method, or
on an existing object.  Either way it will use the .well-known
URI to find the path to the current-user-principal.

Returns a string with the path.

=cut

sub GetCurrentUserPrincipal {
  my ($Class, %Args) = @_;

  if (ref $Class) {
    %Args  = %{$Class};
    $Class = ref $Class;
  }

  my $OriginalURL = $Args{url} || '';
  my $Self        = $Class->new(%Args);
  my $NS_D        = $Self->ns('D');
  my @BasePath    = split '/', $Self->{basepath};

  @BasePath = ('', ".well-known/$Args{wellknown}") unless @BasePath;

  PRINCIPAL: while(1) {
    $Self->SetURL(join '/', @BasePath);

    if (my $Principal = $Self->GetProps('', [ 'D:current-user-principal', 'D:href' ])) {
      $Self->SetURL(uri_unescape($Principal));
      return $Self->{url};
    }

    pop @BasePath;
    last unless @BasePath;
  }

  croak "Error finding current user principal at '$OriginalURL'";
}

=head2 $Self->GetHomeSet
=head2 $class->GetHomeSet(%Args)

Can be called with the same args as new() as a class method, or
on an existing object.  Either way it assumes that the created
object has a 'url' parameter pointing at the current user principal
URL (see GetCurrentUserPrincipal above)

Returns a string with the path to the home set.

=cut

sub GetHomeSet {
  my ($Class, %Args) = @_;

  if (ref $Class) {
    %Args  = %{$Class};
    $Class = ref $Class;
  }

  my $OriginalURL = $Args{url} || '';
  my $Self        = $Class->new(%Args);
  my $NS_D        = $Self->ns('D');
  my $NS_HS       = $Self->ns($Args{homesetns});
  my $HomeSet     = $Args{homeset};

  if (my $Homeset = $Self->GetProps('', [ "$Args{homesetns}:$HomeSet", 'D:href' ])) {
    $Self->SetURL(uri_unescape($Homeset));
    return $Self->{url};
  }

  croak "Error finding $HomeSet home set at '$OriginalURL'";
}

=head2 $Self->genuuid()

Helper to generate a uuid string.  Returns a UUID, e.g.

    my $uuid = $DAVTalk->genuuid(); # 9b9d68af-ad13-46b8-b7ab-30ab70da14ac

=cut

sub genuuid {
  my $Self = shift;
  return "$uuid";
}

=head2 $Self->auth_header()

Generate the authentication header to use on requests:

e.g:

    $Headers{'Authorization'} = $Self->auth_header();

=cut

sub auth_header {
  my $Self = shift;

  if ($Self->{password}) {
    return 'Basic ' . encode_base64("$Self->{user}:$Self->{password}", '');
  }

  if ($Self->{access_token}) {
    return "Bearer $Self->{access_token}";
  }

  croak "Need a method to authenticate user (password or access_token)";
}

=head2 $Self->request_url($Path)

The URL to request for $Path.  Paths are unescaped, as every href this
module and its subclasses return is: each segment is URI-escaped here.
A path starting with / is on the server of the connection's URL, one
starting with http:// or https:// (or a reference to such a string) is
absolute, and anything else is relative to the connection's URL.

e.g:

    my $URL = $Self->request_url('/dav/calendars/user/a@b.com/Default/');
    # https://dav.example.com/dav/calendars/user/a%40b.com/Default/

=cut

sub request_url {
  my $Self = shift;
  my $Path = shift;

  my $URL = $Self->{url};

  # A reference, or a full URL (some servers give hrefs as those), is
  # absolute
  if (ref $Path) {
    ($URL, $Path) = $$Path =~ m{(^https?://[^/]+)(.*)$};
  }
  elsif (defined $Path and $Path =~ m{^https?://}i) {
    ($URL, $Path) = $Path =~ m{(^https?://[^/]+)(.*)$}i;
  }

  if ($Path) {
    $Path = join "/", map { uri_escape $_ } split m{/}, $Path, -1;
    if ($Path =~ m{^/}) {
      $URL =~ s{(^https?://[^/]+)(.*)}{$1$Path};
    }
    else {
      $URL =~ s{/$}{};
      $URL .= "/$Path";
    }
  }

  return $URL;
}

=head2 $Self->request_href($Path)

The href for $Path to put in a request body (e.g. the DAV:href elements
of a multiget): the escaped absolute path of request_url($Path).  Hrefs
the module returns are unescaped, so one sent back as it came would not
be a valid URI wherever it has a space, a % or the like.

=cut

sub request_href {
  my ($Self, $Path) = @_;
  my $URL = $Self->request_url($Path);
  $URL =~ s{^https?://[^/]+}{}i;
  return length $URL ? $URL : '/';
}

=head2 $Self->NS()

Returns a hashref of the 'xmlns:shortname' => 'full namespace' items for use in XML::Spice body generation, e.g.

    $DAVTalk->Request(
        'MKCALENDAR',
        "$calendarId/",
        x('C:mkcalendar', $Self->NS(),
            x('D:set',
                 x('D:prop', @Properties),
            ),
        ),
    );

    # { 'xmlns:C' => 'urn:ietf:params:xml:ns:caldav', 'xmlns:D' => 'DAV:' }

=cut

sub NS {
  my $Self = shift;

  return {
    map { ( "xmlns:$_" => $Self->ns($_) ) }
      $Self->ns(),
  };
}


=head2 $Self->ns($key, $value)

Get or set namespace aliases, e.g

  $Self->ns(C => 'urn:ietf:params:xml:ns:caldav');
  my $NS_C = $Self->ns('C'); # urn:ietf:params:xml:ns:caldav

=cut

sub ns {
  my $Self = shift;

  # case: keys
  return keys %{$Self->{ns}} unless @_;

  my $key = shift;
  # case read one
  return $Self->{ns}{$key} unless @_;

  # case write
  my $prev = $Self->{ns}{$key};
  $Self->{ns}{$key} = shift;
  return $prev;
}

=head2 function2

=cut

=head1 AUTHOR

Bron Gondwana, C<< <brong at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-davtalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DAVTalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DAVTalk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DAVTalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DAVTalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-DAVTalk>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-DAVTalk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2026 Fastmail Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself; that is, either the GNU General
Public License as published by the Free Software Foundation (version 1,
or at your option any later version), or the Artistic License.

See L<http://dev.perl.org/licenses/> and the LICENSE file included with
this distribution for more information.

=cut

1; # End of Net::DAVTalk
