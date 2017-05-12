#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package String::Tagged::HTML;

use strict;
use warnings;

use base qw( String::Tagged );
String::Tagged->VERSION( '0.07' );

our $VERSION = '0.01';

=head1 NAME

C<String::Tagged::HTML> - format HTML output using C<String::Tagged>

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
used to provide additional attributes for the HTML element.

 my $str = String::Tagged::HTML->new( "click here" );
 $str->apply_tag( 6, 4, a => { href => "/see/other.html" } );

 print $str->as_html( "p" );

Z<>

 <p>click <a href="/see/other.html">here</a></p>

If it is not a C<HASH> reference, then its value ought to be a simple boolean
true value, such as C<1>.

The special tag named C<raw> disables HTML entity escaping over its extent.

 my $str = String::Tagged::HTML->new( "This <content> is escaped" );

 my $br = String::Tagged::HTML->new( "<br/>" );
 $br->apply_tag( 0, $br->length, raw => 1 );

 print +( $str . $br )->as_html( "p" );

Z<>

 <p>This &lt;content&gt; is escaped<br/></p>

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

=cut

=head1 CONSTRUCTORS

As well as the standard C<new> and C<new_tagged> constructors provided by
L<String::Tagged|String::Tagged#CONSTRUCTORS>, the following is provided.

=cut

=head2 $st = String::Tagged::HTML->new_raw( $str )

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

=head1 METHODS

The following methods are provided in addition to those provided by
L<String::Tagged|String::Tagged#METHODS>.

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
   die "Unknown tag name $name\n";
}

=head2 $html = $st->as_html( $element )

Returns a string containing an HTML rendering of the current contents of the
object. If C<$element> is provided, the output will be wrapped in an element
of the given name. If not defined, no outer wrapping will be performed.

=cut

sub as_html
{
   my $self = shift;
   my ( $elem ) = @_;

   my $ret = "";

   my @tags_in_effect; # of [ $name, $value ]

   $self->iter_extents_nooverlap(
      sub {
         my ( $e, %tags ) = @_;

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
