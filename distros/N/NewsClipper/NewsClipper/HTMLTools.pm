# -*- mode: Perl; -*-
package NewsClipper::HTMLTools;

# This package contains a set of useful functions for manipulating HTML.

use strict;
# Used to make relative URLs absolute
use URI;
# For exporting of functions
use Exporter;

use vars qw( @ISA @EXPORT $VERSION );

@ISA = qw( Exporter );
@EXPORT = qw( ExtractText MakeLinksAbsolute StripTags
              EscapeHTMLChars StripAttributes HTMLsubstr
              TrimOpenTags GetAttributeValue ExtractTables );

$VERSION = 0.72;

use NewsClipper::Globals;

# ------------------------------------------------------------------------------

# Takes a bunch of html in the first argument (as one long string or a ref to
# one). Uses the remaining arguments to strip out attributes. By default,
# these are taken to be alt,class. Takes one long string (or a reference to
# one) and returns the same.

sub StripAttributes($@)
{
  my $html = shift;
  my @tags = @_;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      StripAttributes only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  @tags = qw(alt class)
    if $#tags == -1;

  # Make the pattern from @tags
  local $" = '|';
  my $pattern = "@tags";

  my $oldhtml;
  do
  {
    $oldhtml = $html;

    # Strip out anything that matches the pattern inside a tag with ' quotes
    $html =~ s#(<[^>]+?)\s*\b($pattern)\b\s*=\s*'[^']*'([^>]*>)#$1$3#sig;

    # Strip out anything that matches the pattern inside a tag with " quotes
    $html =~ s#(<[^>]+?)\s*\b($pattern)\b\s*=\s*"[^"]*"([^>]*>)#$1$3#sig;

    # Strip out anything that matches the pattern inside a tag without quotes
    $html =~ s#(<[^>]+?)\s*\b($pattern)\b\s*=\s*[^'"]\S*[^'"]([^>]*>)#$1$3#sig;
  } while ($oldhtml ne $html);

  return bless (\$html,$returnRef) if $returnRef;
  return $html;
}

# ------------------------------------------------------------------------------

# Takes a bunch of html in the first argument (as one long string or a ref to
# one). Uses the remaining arguments to strip out tags. By default, these are
# taken to be strong,h1,h2,h3,h4,h5,h6,b,i,u,tt,font,big,small,strike, which
# (hopefully) strips out the formatting.

sub StripTags($@)
{
  my $html = shift;
  my @tags = @_;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      StripTags only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  @tags = qw(strong em h1 h2 h3 h4 h5 h6 b i u tt font big small strike)
    if $#tags == -1;

  # Make the pattern from @tags
  my $temp = $";
  $" = '|';
  my $pattern = "@tags";
  $" = $temp;

  # Strip out anything that matches the pattern
  $html =~ s#<\s*/?\b($pattern)\b[^>]*>##sig;

  return bless (\$html,$returnRef) if $returnRef;
  return $html;
}

# ------------------------------------------------------------------------------

# Extracts all text between the starting and ending patterns. '^' and '$' can
# be used for the starting and ending patterns to signify start of text and
# end of text. Takes one long string (or a reference to one) and returns the
# same.

sub ExtractText($$$)
{
  my $html = shift;
  my $startPattern = shift;
  my $endPattern = shift;

  return undef
    unless defined $html && defined $startPattern && defined $endPattern;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      ExtractText only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  # Makes things a lot faster
  return if $startPattern ne '^' && $html !~ /$startPattern/s;

  if (($startPattern eq '^') && ($endPattern eq '$'))
  {
    return $html;
  }
  if (($startPattern ne '^') && ($endPattern ne '$'))
  {
    return '' unless $html =~ s/.*?$startPattern//s;
    return '' unless $html =~ s/$endPattern.*//s;
    return $html;
  }
  if (($startPattern ne '^') && ($endPattern eq '$'))
  {
    $html =~ s/.*?$startPattern(.*)/$1/s;
    return '' if $1 eq '';
    return $html;
  }
  if (($startPattern eq '^') && ($endPattern ne '$'))
  {
    $html =~ s/(.*?)$endPattern.*/$1/s;
    return '' if $1 eq '';
    return $html;
  }

  return bless (\$html,$returnRef) if $returnRef;
  return $html;
}

# ------------------------------------------------------------------------------

# Takes a bunch of html in the first argument (as one long string or a ref to
# one). Uses the remaining arguments to trim unclosed tags from the beginning
# and end of the html. By default, these are taken to be every possible
# enclosing-style tag.

sub TrimOpenTags($@)
{
  my $html = shift;
  my @tags = @_;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      TrimOpenTags only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  @tags = qw(strong em h1 h2 h3 h4 h5 h6 b i u tt font big small strike a html
                title head body div span blockquote q code samp kbd var dfn
                address ins del acronym abbr s sub sup pre center blink marquee
                multicol layer ilayer nolayer map object nobr ul ol dl menu form
                button label select optgroup textarea fieldset legend table tr
                td th tfoot thead caption col colgroup frameset noframes iframe
                script noscript applet server style bdo)
    if $#tags == -1;

  foreach my $tag (@tags)
  {
    # If we see a starting tag...
    if ($html =~ /^(.*)(<\s*\b$tag\b[^>]*>)(.*?)$/si)
    {
      my ($start,$tagtext,$end) = ($1,$2,$3);
      # If there isn't a closing tag...
      if ($end !~ /<\s*\/\s*\b$tag\b[^>]*>/si)
      {
        $html = $start.$end;
      }
    }

    # If we see an ending tag...
    if ($html =~ /^(.*?)(<\s*\/\s*\b$tag\b[^>]*>)(.*)$/si)
    {
      my ($start,$tagtext,$end) = ($1,$2,$3);
      # If there isn't a starting tag...
      if ($start !~ /<\s*\b$tag\b[^>]*>/si)
      {
        $html = $start.$end;
      }
    }
  }

  return bless (\$html,$returnRef) if $returnRef;
  return $html;
}

# ------------------------------------------------------------------------------

# Takes a substring from HTML, but only counts the non-tag characters. It also
# tries to remove starting HTML tags that have been trimmed off...  Arguments
# are the text, an offset, and the length. Takes one long string (or a
# reference to one) and returns the same.

sub HTMLsubstr($$;$)
{
  my $html = shift;
  my $offset = shift;
  my $length = shift || 32700;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      HTMLsubstr only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  # First split the html into characters
  my @chars = $html =~ /(.)/sg;

  my $returnVal = '';

  my $count = 0;
  my $counting = 1;

  foreach my $char (@chars)
  {
    # Stop counting if we see a <
    if ($char eq '<')
    {
      $counting = 0;
    }

    # Start counting when we see a >, but don't count the >
    if ($char eq '>')
    {
      $counting = 1;
      $count-- unless $count == 0;
    }

    last if $count > $offset + $length;

    $returnVal .= $char if $count >= $offset;

    $count++ if $counting;
  }

  unless (defined $returnVal)
  {
    warn "News Clipper encountered an error taking an HTML stubstring.\n".
      "Please submit a bug report at http://newsclipper.sourceforge.net/\n";
    return '';
  }

  # But wait! What if we chopped off a starting <font>, <tt> etc from the
  # beginning, or an ending </font>, </tt>, etc from the end?
  $returnVal = TrimOpenTags($returnVal);

  return bless (\$returnVal,$returnRef) if $returnRef;
  return $returnVal;
}

# ------------------------------------------------------------------------------

# Escapes & < and > in text. Note that this should only be used on non-HTML
# text. ('AT&T' gets turned into 'AT&amp;T') Takes one long string (or a
# reference to one) and returns the same.

sub EscapeHTMLChars($)
{
  my $html = shift;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      EscapeHTMLChars only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  # Escape HTML characters
  $html =~ s/&/&amp;/sg;
  $html =~ s/</&lt;/sg;
  $html =~ s/>/&gt;/sg;

  return bless (\$html,$returnRef) if $returnRef;
  return $html;
}

# ------------------------------------------------------------------------------

# Searches text for "a href" or "img src" tags and makes them absolute. We
# should probably be doing this with HTML::Parser. Note that this function
# erroneously recognizes stuff like <a href='XXX">. This is pretty rare, and
# doing it this way is faster than recognizing two quotes and no quotes
# separately. Takes one long string (or a reference to one) and returns the
# same.

sub MakeLinksAbsolute($$)
{
  my $url = shift;
  my $html = shift;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      MakeLinksAbsolute only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  $html =~ s/
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
    /
      # Then construct the new link from the prefix and suffix
      $1.sprintf("%s",URI->new($2)->abs($url)).$3
    /segix;

  return bless (\$html,$returnRef) if $returnRef;
  return $html;
}

# ------------------------------------------------------------------------------

# Searches HTML for a tag and an attribute, and returns the value of the
# attribute for the first tag encountered. Returns undef if the value can't be
# found.

sub GetAttributeValue($$$)
{
  my $html = shift;
  my $tag = shift;
  my $attribute = shift;

  return undef
    unless defined $html && defined $tag && defined $attribute;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      GetAttributeValue only takes values of type "SCALAR".
    EOF
  }

  $html = $$html if ref $html;

  if ($html =~ /
      # First look for a <$tag, followed later by an $attribute
      <\s*(?:$tag)\b[^>]*\b(?:$attribute)\b\s*=\s*
      # Then an optional quote
      ['"]?
      # Then the interesting part
      ([^'"> ]+)
      # Then another optional quote
      ['"]?
      # And the left-overs
      [^>]*>
    /six)
  {
    return $1;
  }
  else
  {
    return undef;
  }
}

# ------------------------------------------------------------------------------

# Extracts all tables. Nested tables are not extracted separately--they are
# treated as part of the enclosing table.  Takes one long string (or a
# reference to one) and returns an array of strings (or references to strings).

sub ExtractTables($)
{
  my $html = shift;

  return undef unless defined $html;

  unless (UNIVERSAL::isa(\$html,'SCALAR') || UNIVERSAL::isa($html,'SCALAR'))
  {
    die reformat dequote<<"    EOF";
      ExtractTables only takes values of type "SCALAR".
    EOF
  }

  my $returnRef = 0;

  if (ref $html)
  {
    $returnRef = ref $html;
    $html = $$html;
  }

  my @tables;
  my $depth=0;
  my $newtable;

  while ($html =~ /\G(.*?)(<\s*table\b[^>]*>|<\s*\/\s*table\s*>)/isg)
  {
    my ($prefix,$match) = ($1,$2);

    # Start of table
    if ($match =~ /<\s*table/i)
    {
      $depth++;

      # Brand new table
      if ($depth == 1)
      {
        $newtable = $match;
      }
      # Internal table
      else
      {
        $newtable .= "$prefix$match";
      }
    }
    # End of table
    else
    {
      # We might see an out-of-place </table>
      next if $depth == 0;

      $depth--;
      $newtable .= "$prefix$match";

      # Done with table
      if ($depth == 0)
      {
        if ($returnRef)
        {
          push (@tables, \$newtable);
        }
        else
        {
          push (@tables, $newtable);
        }
      }
      # Internal table
      else
      {
        $newtable .= "$prefix$match";
      }
    }
  }

  return @tables;
}

1;
