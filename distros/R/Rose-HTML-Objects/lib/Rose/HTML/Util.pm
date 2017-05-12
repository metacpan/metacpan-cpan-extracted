package Rose::HTML::Util;

use strict;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = 
  qw(escape_html unescape_html escape_uri escape_uri_component
     encode_entities strip_html html_attrs_string);

our %EXPORT_TAGS = 
(
  all => 
  [
    qw(escape_html unescape_html escape_uri escape_uri_component 
       encode_entities) 
  ]
);

use HTML::Entities();
use URI::Escape;

if(exists $ENV{'MOD_PERL'} && require mod_perl && $mod_perl::VERSION < 1.99)
{
  require Apache::Util;

  #*escape_html   = \&HTML::Entities::encode;
  *escape_html   = \&encode_entities;
  *unescape_html = \&HTML::Entities::decode;
  *escape_uri_component = \&Apache::Util::escape_uri;
}
else
{
  #*escape_html   = \&HTML::Entities::encode;
  *escape_html   = \&encode_entities;
  *unescape_html = \&HTML::Entities::decode;
  *escape_uri_component = \&URI::Escape::uri_escape;
}

our $VERSION = '0.011';

sub encode_entities { HTML::Entities::encode_entities($_[0], @_ > 1 ? $_[1] : '<>&"') }

sub escape_uri
{
  URI::Escape::uri_escape($_[0], 
    (@_ > 1) ? (defined $_[1] ? $_[1] : ()) : q(^A-Za-z0-9\-_.,'!~*#?&()/?@\:\[\]=));
}

sub html_attrs_string
{
  my %attrs;

  if(@_ == 1 && ref $_[0] eq 'HASH')
  {
    %attrs = %{$_[0]};
  }
  elsif(@_ && @_ % 2 == 0)
  {
    %attrs = @_;
  }

  return '' unless(keys %attrs);

  return ' ' . join(' ', map { $_  . q(=") . escape_html($attrs{$_}) . q(") }
                         sort keys(%attrs));
}

sub strip_html
{
  my($text) = shift;

  # XXX: dumb for now...
  $text =~ s{<[^>]*?/?>}{}g;

  return $text;
}

1;


__END__

=head1 NAME

Rose::HTML::Util - Utility functions for manipulating HTML.

=head1 SYNOPSIS

    use Rose::HTML::Util qw(:all);

    $esc = escape_html($str);
    $str = unescape_html($esc);

    $esc = escape_uri($str);
    $str = unescape_uri($esc);

    $comp = escape_uri_component($str);

    $esc = encode_entities($str);

=head1 DESCRIPTION

L<Rose::HTML::Util> provides aliases and wrappers for common HTML manipulation functions.  When running in a mod_perl 1.x web server environment, Apache's C-based functions are used in some cases.

This all may seem silly, but I like to be able to pull these functions from a single location and get the fastest possible versions.

=head1 EXPORTS

L<Rose::HTML::Util> does not export any function names by default.

The 'all' tag:

    use Rose::HTML::Util qw(:all);

will cause the following function names to be imported:

    escape_html()
    unescape_html()
    escape_uri()
    escape_uri_component()
    encode_entities()

=head1 FUNCTIONS

=over 4

=item B<escape_html STRING [, UNSAFE]>

This method passes its arguments to L<HTML::Entities::encode_entities()|HTML::Entities/encode_entities>.  If the list of unsafe characters is omitted, it defaults to C<E<lt>E<gt>&">

=item B<unescape_html STRING>

This method is an alias for L<HTML::Entities::decode()|HTML::Entities/decode>.

=item B<escape_uri STRING>

This is a wrapper for L<URI::Escape::uri_escape()|URI::Escapeuri_escape> that is intended to escape entire URIs.  Example:

    $str = 'http://foo.com/bar?baz=1%&blay=foo bar'
    $esc = escape_uri($str);

    print $esc; # http://foo.com/bar?baz=1%25&blay=foo%20bar

In other words, it tries to escape all characters that need to be escaped in a URI I<except> those characters that are legitimately part of the URI: forward slashes, the question mark before the query, etc.

The current implementation escapes all characters except those in this set:

    A-Za-z0-9\-_.,'!~*#?&()/?@:[]=

Note that the URI-escaped string is not HTML-escaped.  In order make a URI safe to include in an HTML page, call L<escape_html()|/escape_html> as well:

    $h = '<a href="' . escape_html(escape_uri($str)) . '">foo</a>';

=item B<escape_uri_component STRING>

When running under mod_perl 1.x, this is an alias for L<Apache::Util::escape_uri()|Apache::Util/escape_uri>. Otherwise, it's an alias for L<URI::Escape::uri_escape()|URI::Escapeuri_escape>.

=item B<encode_entities STRING [, UNSAFE]>

This method passes its arguments to L<HTML::Entities::encode_entities()|HTML::Entities/encode_entities>.  If the list of unsafe characters is omitted, it defaults to C<E<lt>E<gt>&">

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
