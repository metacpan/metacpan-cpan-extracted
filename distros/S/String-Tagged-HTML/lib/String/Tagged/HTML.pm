#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2024 -- leonerd@leonerd.org.uk

package String::Tagged::HTML 0.03;

use v5.14;
use warnings;

use base qw( String::Tagged );
String::Tagged->VERSION( '0.20' );

=head1 NAME

C<String::Tagged::HTML> - handle HTML content using C<String::Tagged>

=head1 SYNOPSIS

   use String::Tagged::HTML;

   my $st = String::Tagged::HTML->new( "An important message" );

   $st->apply_tag( 3, 9, b => 1 );

   print $st->as_html( "h1" );

=head1 DESCRIPTION

This subclass of L<String::Tagged> provides a method, C<as_html>, for rendering
the string as an HTML fragment, using the tags to provide formatting. For
example, the SYNOPSIS example will produce the output

   <h1>An <b>important</b> message</h1>

With the exception of tags named C<raw>, a tag applied to an extent of the
C<String::Tagged::HTML> will be rendered using start and end HTML tags of the
same name. If the tag's value is a C<HASH> reference, then this hash will be
used to provide additional attributes for the HTML element. Tags whose names
begin with C<_> will be ignored for this purpose.

   my $str = String::Tagged::HTML->new( "click " )
      ->append_tagged( "here", a => { href => "/see/other.html" } );

   print $str->as_html( "p" );

Z<>

   <p>click <a href="/see/other.html">here</a></p>

If it is not a C<HASH> reference, then its value ought to be a simple boolean
true value, such as C<1>.

The special tag named C<raw> disables HTML entity escaping over its extent.

   my $str = String::Tagged::HTML->new( "This <content> is escaped" );

   my $br = String::Tagged::HTML->new_tagged( "<br/>", raw => 1 );

   print +( $str . $br )->as_html( "p" );

Z<>

   <p>This &lt;content&gt; is escaped<br/></p>

=head2 Automatic C<< <span> >> Generation

Tags whose names begin C<_span_style_...> are used to create a C<style>
attribute for an implied C<span> tag.

All tags with this name prefix are collected together. The part of the name
following this prefix is used as the style property name and the value of the
tag used for its value. These are all joined into a single string, and that is
then used to generate the C<style> tag.

As an extra convenience, any remaining underscores in the tag name will be
converted to hyphens in the style property name.

   my $str = String::Tagged::HTML->new( "Some big text" );
   $str->apply_tag( 5, 3, _span_style_font_size => "large" );

   print $str->as_html

Z<>

   Some <span style="font-size: large;">big</span> text

=head2 Tag Nesting

Because of the arbitrary way that C<String::Tagged> tags may be applied, as
compared to the strict nesting requirements in HTML, the C<as_html> method may
have to break a single C<String::Tagged> tag into multiple regions. In the
following example, the C<i> tag has been split in two to allow it to overlap
correctly with C<b>.

   my $str = String::Tagged::HTML->new( "bbb b+i iii" );
   $str->apply_tag( 0, 7, b => 1 );
   $str->apply_tag( 4, 7, i => 1 );

   print $str->as_html

Z<>

   <b>bbb <i>b+i</i></b><i> iii</i>

=head2 String::Tagged::Formatting SUPPORT

L<String::Tagged::Formatting> specifes a standard way that subclasses of
C<String::Tagged> can express a variety of simple formatting styles. HTML is a
lot more flexible than this (and CSS doubly so). Certain limited support is
provided for converting C<String::Tagged::Formatting> tags into a form that
can be rendered into standalone HTML.

The following tag conversions are supported:

   bold                 <strong>
   under                <u>
   italic               <em>
   strike               <strike>
   monospace            <tt>

   sizepos = "super"    <sup>
   sizepod = "sub"      <sub>

   fg                   <span style="color: #rrggbb">
   bg                   <span style="background-color: #rrggbb">

   link                 <a href="uri">

=cut

=head1 CONSTRUCTORS

As well as the standard C<new> and C<new_tagged> constructors provided by
L<String::Tagged|String::Tagged/CONSTRUCTORS>, the following is provided.

=cut

=head2 new_raw

   $st = String::Tagged::HTML->new_raw( $str );

Returns a new C<String::Tagged::HTML> instance with the C<raw> tag applied
over its entire length. This convenience is provided for creating objects
containing already-rendered HTML fragments.

=cut

sub new_raw
{
   my $class = shift;
   my ( $str ) = @_;
   return $class->new_tagged( $str, raw => 1 );
}

=head2 new_from_formatting

   $st = String::Tagged::HTML->new_from_formatting( $fmt, %params );

Returns a new instance by converting L<String::Tagged::Formatting> standard
tags, as described above.

The following additional named arguments are recognised:

=over 4

=item convert_linefeeds => BOOL

Optional. If true, linefeeds in the source string will be converted into
C<< <br/> >> HTML tags in the result. Defaults to true if absent, but the
behaviour can be disabled by passing a defined-but-false value.

=back

=cut

sub new_from_formatting
{
   my ( $class, $orig, %params ) = @_;

   my $ret = $class->clone( $orig,
      only_tags => [qw( bold italic under strike monospace sizepos fg bg link )],
      convert_tags => {
         bold      => "strong",
         italic    => "em",
         under     => "u",
         # strike stands as is
         monospace => "tt",
         sizepos   => sub {
            my ( $k, $v ) = @_;
            return "sup" => 1 if $v eq "super";
            return "sub" => 1 if $v eq "sub";
            return;
         },
         fg => sub {
            my ( $k, $v ) = @_;
            return _span_style_color => "#" . $v->as_rgb8->hex;
         },
         bg => sub {
            my ( $k, $v ) = @_;
            return _span_style_background_color => "#" . $v->as_rgb8->hex;
         },
         link => sub {
            my ( $k, $v ) = @_;
            return unless defined( my $uri = $v->{uri} );
            return a => { href => $uri };
         },
      }
   );

   if( $params{convert_linefeeds} // 1 ) {
      my $br_tag = $class->new_raw( "<br/>\n" );

      foreach my $e ( reverse $ret->match_extents( qr/\n/ ) ) {
         $ret->set_substr( $e->start, $e->length, $br_tag );
      }
   }

   return $ret;
}

=head2 parse_html

   $st = String::Tagged::HTML->parse_html( $html );

Returns a new C<String::Tagged::HTML> instance by parsing the given HTML
content and composing the plaintext parts of the content, with tags applied
over the appropriate ranges of it.

This parsing is currently performed using L<HTML::TreeBuilder>, and will not
work if that module is not available.

=cut

sub parse_html
{
   my $class = shift;
   my ( $content ) = @_;

   require HTML::TreeBuilder;

   my $tree = HTML::TreeBuilder->new_from_content( $content );
   my $body = $tree->find_by_tag_name( 'body' );

   return _traverse_html( $class, $body );
}

sub _traverse_html
{
   my ( $class, $node ) = @_;

   # Plain text
   return $class->new( $node ) if !ref $node;

   my $tag = $node->tag;

   my $ret = $class->new;

   $ret .= _traverse_html( $class, $_ ) for $node->content_list;

   $ret->apply_tag( 0, length $ret, $tag, { $node->all_external_attr } )
      unless $tag eq "body";

   return $ret;
}

=head1 METHODS

The following methods are provided in addition to those provided by
L<String::Tagged|String::Tagged/METHODS>.

=cut

sub _escape_html
{
   my $s = $_[0];
   $s =~ s/([<>&"'])/$1 eq "<" ? "&lt;" :
                     $1 eq ">" ? "&gt;" :
                     $1 eq "&" ? "&amp;" :
                     $1 eq '"' ? "&quot;" :
                     $1 eq "'" ? "&#39;" : ""/eg;
   $s;
}

sub _cmp_tag_values
{
   my $self = shift;
   my ( $name, $v1, $v2 ) = @_;

   return ( $v1 == $v2 ) if grep { $name eq $_ } qw( b i u small );
   return ( $v1->{href} eq $v2->{href} ) if $name eq "a";
   return ( $v1->{style} eq $v2->{style} ) if $name eq "span";
   die "String::Tagged::HTML does not recognise the tag name '$name'\n";
}

=head2 as_html

   $html = $st->as_html( $element );

Returns a string containing an HTML rendering of the current contents of the
object. If C<$element> is provided, the output will be wrapped in an element
of the given name. If not defined, no outer wrapping will be performed.

=cut

sub _build_style
{
   my ( $style ) = @_;

   return join " ", map {
      my $prop = $_ =~ s/_/-/gr;
      "$prop: $style->{$_};"
   } sort keys %$style;
}

sub as_html
{
   my $self = shift;
   my ( $elem ) = @_;

   my $ret = "";

   my @tags_in_effect; # of [ $name, $value ]

   $self->iter_extents_nooverlap(
      sub {
         my ( $e, %tags ) = @_;

         # _span_style_... hackery
         my %span_style;
         foreach my $k ( grep m/^_/, keys %tags ) {
            my $v = delete $tags{$k};
            if( $k =~ m/^_span_style_(.*)$/ ) {
               $span_style{$1} = $v;
            }
         }
         $tags{span}{style} = _build_style \%span_style if keys %span_style;

         # Look for the first tag that no longer applies, as we'll have to
         # unwind the entire tag stack to that point

         my $i;
         for( $i = 0; $i < @tags_in_effect; $i++ ) {
            my ( $tag, $value ) = @{ $tags_in_effect[$i] };
            last if !exists $tags{$tag};
            last if !$self->_cmp_tag_values( $tag, $value, $tags{$tag} );
            delete $tags{$tag};
         }

         while( @tags_in_effect > $i ) {
            my ( $tag ) = @{ pop @tags_in_effect };
            $ret .= "</$tag>";
         }

         # TODO: Sort these into an optimal order
         foreach my $tag ( keys %tags ) {
            my $value = $tags{$tag};
            if( ref $value eq "HASH" ) {
               my $attrs = join "", map { qq( $_=") . _escape_html($value->{$_}) . q(") } sort keys %$value;
               $ret .= "<$tag$attrs>";
            }
            else {
               $ret .= "<$tag>";
            }
            push @tags_in_effect, [ $tag, $value ];
         }

         $self->iter_substr_nooverlap(
            sub {
               my ( $str, %tags ) = @_;
               $ret .= ( $tags{raw} ? $str : _escape_html( $str ) );
            },
            start => $e->start,
            end   => $e->end,
         );
      },
      except => [qw( raw )],
   );

   while( @tags_in_effect ) {
      my ( $tag ) = @{ pop @tags_in_effect };
      $ret .= "</$tag>";
   }

   return "<$elem>$ret</$elem>" if defined $elem;
   return "$ret";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
