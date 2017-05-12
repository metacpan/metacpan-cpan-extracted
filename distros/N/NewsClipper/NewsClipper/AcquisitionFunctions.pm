# -*- mode: Perl; -*-
package NewsClipper::AcquisitionFunctions;

# This package contains a set of useful functions for grabbing data from the
# internet. It is used by the handlers' Get functions.

use strict;
# For some HTML manipulation functions
use NewsClipper::HTMLTools;
# For UserAgent
use LWP::UserAgent;
# For exporting of functions
use Exporter;

use vars qw( @ISA @EXPORT $VERSION );

@ISA = qw( Exporter );
@EXPORT = qw(GetUrl GetHtml GetImages GetLinks GetText);

$VERSION = 0.67;

use NewsClipper::Globals;

my $userAgent = new LWP::UserAgent;

# ------------------------------------------------------------------------------

# Gets the entire contents from a URL. This function *does not* escape & < and
# >. Use "GetHtml($url,'^','$')" if you want this behavior.

sub GetUrl($)
{
  my $url = shift;

  unless (defined($url) && ($url ne ''))
  {
    dprint "GetUrl couldn't get data. Proper URL not supplied.";
    $errors{'acquisition'} .=
      "GetUrl couldn't get data. Proper URL not supplied.\n";
    return undef;
  }

  dprint "GetUrl is getting URL:\n  $url";

  # Try to get the cached data if it's available and still valid. First try to
  # get the update times for the handler.
  my @updateTimes = @NewsClipper::Interpreter::update_times;

  # If the user specified "always", there's no need to check the time.
  if (lc($updateTimes[0]) eq 'always')
  {
    dprint "\"Always\" specified. Skipping cache check"
  }
  # See if we can just return the current cached data.
  else
  {
    my ($cachedData,$cacheStatus) =
      $NewsClipper::Globals::cache->get($url,@updateTimes);

    # If the data is still valid for the @updateTimes, we can return it
    # immediately (There's no need to bless this since it's just a SCALAR)
    return \$cachedData if $cacheStatus eq 'valid';

    # Now see if the remote content hasn't changed. If it hasn't, we can
    # just return the cached data.
    if ($cacheStatus eq 'stale')
    {
      my $last_modified = _GetLastModifiedTime($url);
      my $cached_time = $NewsClipper::Globals::cache->GetTimeCached($url);
      if (defined $last_modified && defined $cached_time &&
          $cached_time > $last_modified)
      {
        return \$cachedData
      }
    }
  }

  # Otherwise we'll have to fetch it.
  $userAgent->timeout($config{socket_timeout});
  $userAgent->proxy(['http', 'ftp'], $config{proxy})
    if $config{proxy} ne '';
  my $request = new HTTP::Request GET => "$url";

  # We'll look like Netscape to the servers. Some servers return different
  # information depending on whether you are a browser or not.
#  $userAgent->agent('Mozilla/4.03');

  # Reload content if the user wants it
  $request->push_header("Pragma" => "no-cache") if exists $opts{r};

  if ($config{proxy_username} ne '')
  {
    $request->proxy_authorization_basic($config{proxy_username},
                     $config{proxy_password});
  }

  # Tell the server not to send the data if it hasn't been modified. This is
  # an extra check in addition to the last modified check above.
  {
    my $cached_time = $NewsClipper::Globals::cache->GetTimeCached($url);
    $request->if_modified_since($cached_time);
  }

  my $result;
  my $numTriesLeft = $config{socket_tries};

  do
  {
    $result = $userAgent->request($request);
    $numTriesLeft--;
  } until ($numTriesLeft == 0 || $result->is_success);

  # If the server reports that the data hasn't changed
  if (!$result->is_success && $result->code == 304)
  {
    dprint "Server reports data hasn't changed.";

    my ($cachedData,$cacheStatus) =
      $NewsClipper::Globals::cache->get($url,@updateTimes);

    # Use the cached data if there is any available
    if ($cacheStatus eq 'stale')
    {
      dprint "Using cached data.";
      # No need to bless this since it's just a SCALAR
      return \$cachedData;
    }
    else
    {
      dprint "There is no cached data available";

      return undef;
    }
  }
  elsif (!$result->is_success)
  {
    dprint "Couldn't get data. Error on HTTP request: \"" . $result->message .
      "\"";
    $errors{'acquisition'} .= "Error on HTTP request: \"" .
                              $result->message . "\".\n"
      if defined $result;

    my ($cachedData,$cacheStatus) =
      $NewsClipper::Globals::cache->get($url,@updateTimes);

    # Use the cached data if there is any available
    if ($cacheStatus eq 'stale')
    {
      dprint "HTTP request failed, but there is cached data available.";
      $errors{'acquisition'} .= "Using cached data.\n";
      # No need to bless this since it's just a SCALAR
      return \$cachedData;
    }
    else
    {
      dprint "HTTP request failed, and there is no cached data available";
      $errors{'acquisition'} .= "There is no cached data.\n";

      return undef;
    }
  }

  my $content = $result->content;

  # Strip linefeeds off the lines if the content looks non-binary
  $content =~ s/\r//gs if $content !~ /\000/;

  # Cache it for later use, even if "always" was specified. (We use the cached
  # data to determine when the info was last fetched. Also, the person may
  # change the handler to something other than "always".)
  $NewsClipper::Globals::cache->set($url,$content);

  # No need to bless this since it's just a SCALAR
  return \$content;
}

# ------------------------------------------------------------------------------

# Contacts a remote server and determines when the content at the URL was last
# modified. Returns undef if it can't determine the time.

sub _GetLastModifiedTime
{
  my $url = shift;

  # Tell the server to return just 1 byte of content, so we can analyze the
  # headers. We do a GET here instead of HEAD because I heard that Apache
  # doesn't return the size for HEAD requests by default.

  # Some FTP servers try to send the whole thing no matter what we tell them.
  # In that case, we set the timeout small to abort after the headers are
  # received but before a lot of data comes down the pipe.
  my $old_timeout = $userAgent->timeout(5);

  my $result;
  my $numTriesLeft = $config{socket_tries};

  do
  {
    $result = $userAgent->request(HTTP::Request->new('GET', $url),sub{die},1);
    $numTriesLeft--;
  } until ($numTriesLeft == 0 || $result->is_success);

  $userAgent->timeout($old_timeout);

  return $result->last_modified;
}

# ------------------------------------------------------------------------------

# Gets all the text from a URL, stripping out all HTML tags between the
# starting pattern and the ending pattern. This function escapes & < >.

sub GetText($$$)
{
  my $url = shift;
  my $startPattern = shift;
  my $endPattern = shift;

  my $html = GetUrl($url);

  return unless
    defined $html && defined $startPattern && defined $endPattern;

  $html = $$html;

  # Strip off all the stuff before and after the start and end patterns
  $html = &ExtractText($html,$startPattern,$endPattern);

  unless (defined $html)
  {
    dprint reformat (70,dequote <<"    EOF");
      Remote content was acquired, but GetText could not extract the
      interesting part using the start pattern "$startPattern" and the end
      pattern "$endPattern".
    EOF

    return undef;
  }

  # Remove pieces of tags at the ends
  $html =~ s/^[^<]*>//s;
  $html =~ s/<[^>]*$//s;

  # Wrap in HTML to help TreeBuilder.
  $html = "<body>$html" unless $html =~ /<body/i;
  $html = "$html</body>" unless $html =~ /<\/body>/i;
  $html = "</head>$html" unless $html =~ /<\/head>/i;
  $html = "<head>$html" unless $html =~ /<head/i;
  $html = "<html>$html" unless $html =~ /<html/i;
  $html = "$html</html>" unless $html =~ /<\/html>/i;

  # FormatText seems to have a problem with &nbsp;
  $html =~ s/&nbsp;/ /sg;

  # Convert to text
  require HTML::FormatText;
  require HTML::TreeBuilder;

  my $f = HTML::FormatText->new(leftmargin=>0);
  $html = $f->format(HTML::TreeBuilder->new->parse($html));
  $html =~ s/\n*$//sg;

  # Escape HTML characters
  $html = EscapeHTMLChars($html);

  if ($html ne '')
  {
    # No need to bless this since it's just a SCALAR
    return \$html;
  }
  else
  {
    return undef;
  }
}

# ------------------------------------------------------------------------------

# Extracts HTML between startPattern and endPattern. 

# startPattern and endPattern can be '^' or '$' to match the beginning of the
# file or the end of the file, and understands <base href=...>

sub GetHtml($$$)
{
  my $url = shift;
  my $startPattern = shift;
  my $endPattern = shift;

  my $html = &GetUrl($url);

  return unless
    defined $html && defined $startPattern && defined $endPattern;

  $html = $$html;

  {
    my $base_href = GetAttributeValue($html,'base','href');
    $url = $base_href if defined $base_href;
  }

  # Strip off all the stuff before and after the start and end patterns
  $html = &ExtractText($html,$startPattern,$endPattern);
  return unless defined $html;

  unless (defined $html)
  {
    dprint reformat (70,dequote <<"    EOF");
      Remote content was acquired, but GetHtml could not extract the
      interesting part using the start pattern "$startPattern" and the end
      pattern "$endPattern".
    EOF

    return undef;
  }

  $html = &MakeLinksAbsolute($url,$html);
  return unless defined $html;

  if ($html ne '')
  {
    # No need to bless this since it's just a SCALAR
    return \$html;
  }
  else
  {
    return undef;
  }
}

#-------------------------------------------------------------------------------

# Extracts all <img...> tags at a given url between startPattern
# and endPattern.
# Handles '^' and '$' to signify start and end of file, and understands <base
# href=...>

sub GetImages($$$)
{
  my $url = shift;
  my $startPattern = shift;
  my $endPattern = shift;

  my $html = &GetUrl($url);

  return unless
    defined $html && defined $startPattern && defined $endPattern;

  $html = $$html;

  {
    my $base_href = GetAttributeValue($html,'base','href');
    $url = $base_href if defined $base_href;
  }

  # Strip off all the stuff before and after the start and end patterns
  $html = &ExtractText($html,$startPattern,$endPattern);

  unless (defined $html)
  {
    dprint reformat (70,dequote <<"    EOF");
      Remote content was acquired, but GetImages could not extract the
      interesting part using the start pattern "$startPattern" and the end
      pattern "$endPattern".
    EOF

    return undef;
  }

  # Remove any formatting
  $html = StripTags($html);

  require HTML::TreeBuilder;
  my $tree = HTML::TreeBuilder->new;
  $tree->parse($html);

  my @imgTags;

  foreach my $linkpair (@{$tree->extract_links('img')})
  {
    # Extract the link from the HTML element.
    my $elem = ${$linkpair}[1];
    my $link = $elem->as_HTML();
    chomp $link;

    # Repair brain-dead & to &amp; in URLs
    $link =~ s!
        # First look for an a, img, or area, followed later by an href or src
        (<\s*(?:a|img|area)\b[^>]*(?:href|src)\s*=\s*
        # Then an optional quote
        ['"]?)
        # Then the interesting part
        ([^'"> ]+)
        # Then another optional quote
        (['"]?
        # And the left-overs
        [^>]*>)
      !
        my $front = $1;
        my $url = $2;
        my $back = $3;

        $url =~ s/\&amp;/\&/g;

        # Then construct the new link from the prefix and suffix
        $_ = $front.$url.$back;
      !segix;

    # change relative tags to absolute
    $link = &MakeLinksAbsolute($url,$link);
    bless \$link,'Image';
    push @imgTags, \$link;
  }

  if ($#imgTags != -1)
  {
    return \@imgTags;
  }
  else
  {
    return undef;
  }
}

# ------------------------------------------------------------------------------

# Extracts all <a href...>...</a> links at a given url between startPattern
# and endPattern. Removes all text formatting, and makes relative links
# absolute. Puts quotes around attribute values in stuff like <a href=blah> and
# <img src=blah>.

# Handles '^' and '$' to signify start and end of file, and understands <base
# href=...>

sub GetLinks($$$)
{
  my $url = shift;
  my $startPattern = shift;
  my $endPattern = shift;

  my $html = &GetUrl($url);

  return unless
    defined $html && defined $startPattern && defined $endPattern;

  $html = $$html;

  {
    my $base_href = GetAttributeValue($html,'base','href');
    $url = $base_href if defined $base_href;
  }

  # Strip off all the stuff before and after the start and end patterns
  $html = &ExtractText($html,$startPattern,$endPattern);

  unless (defined $html)
  {
    dprint reformat (70,dequote <<"    EOF");
      Remote content was acquired, but GetLinks could not extract the
      interesting part using the start pattern "$startPattern" and the end
      pattern "$endPattern".
    EOF

    return undef;
  }

  # Remove any formatting
  $html = StripTags($html);

  return undef unless defined $html;

  require HTML::TreeBuilder;
  my $tree = HTML::TreeBuilder->new;
  $tree->parse($html);

  my @links;

  foreach my $linkpair (@{$tree->extract_links('a')})
  {
    # Extract the link from the HTML element.
    my $elem = ${$linkpair}[1];
    my $link = $elem->as_HTML();
    chomp $link;

    # Repair brain-dead & to &amp; in URLs
    $link =~ s!
        # First look for an a, img, or area, followed later by an href or src
        (<\s*(?:a|img|area)\b[^>]*(?:href|src)\s*=\s*
        # Then an optional quote
        ['"]?)
        # Then the interesting part
        ([^'"> ]+)
        # Then another optional quote
        (['"]?
        # And the left-overs
        [^>]*>)
      !
        my $front = $1;
        my $url = $2;
        my $back = $3;

        $url =~ s/\&amp;/\&/g;

        # Then construct the new link from the prefix and suffix
        $_ = $front.$url.$back;
      !segix;

    # change relative tags to absolute
    $link = &MakeLinksAbsolute($url,$link);
    bless \$link,'Link';
    push @links, \$link;
  }

  if ($#links != -1)
  {
    return \@links;
  }
  else
  {
    return undef;
  }
}

1;
