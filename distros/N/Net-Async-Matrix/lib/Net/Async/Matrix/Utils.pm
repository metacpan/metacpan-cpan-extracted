#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2017 -- leonerd@leonerd.org.uk

package Net::Async::Matrix::Utils;

use strict;
use warnings;

our $VERSION = '0.19';
$VERSION = eval $VERSION;

use Exporter 'import';
our @EXPORT_OK = qw(
   parse_formatted_message
   build_formatted_message
);

use String::Tagged 0.11;

# Optionally parse HTML rich-formatted body; but don't get too upset if we
# don't have these installed
use constant CAN_PARSE_HTML => eval {
   require HTML::TreeBuilder;
   require Convert::Color::HTML;
};

# Optionally build HTML rich-formatted body; but don't get too upset if we
# don't have this installed
use constant CAN_BUILD_HTML => eval {
   require String::Tagged::HTML;
   require Convert::Color::HTML;
};

=head1 NAME

C<Net::Async::Matrix::Utils> - support utilities for L<Net::Async::Matrix>

=head1 DESCRIPTION

=cut

=head1 FUNCTIONS

=cut

=head2 parse_formatted_message

   $st = parse_formatted_message( $content )

Given the content of a C<m.room.message> event of C<m.text> or C<m.emote>
type, returns a L<String::Tagged> instance containing the text of the message
with formatting in L<String::Tagged::Formatting> style. If the message is not
formatted, or the formatting is of a kind not recognised, the plain-text body
is returned in an instance with no tags.

The following formats are recognised:

=over 4

=item org.matrix.custom.html

This format requires the presence of L<HTML::TreeBuilder> to parse; it will be
ignored if this module is not available.

 HTML              | String::Tagged::Formatting
 ------------------+---------------------------
 <b>, <strong>     | 'bold'
 <i>, <em>         | 'italic'
 <u>               | 'under'
 <strike>          | 'strike'
 <tt>, <code>      | 'monospace'
 <font color="..." | 'fg'

=back

=cut

sub parse_formatted_message
{
   my ( $content ) = @_;

   for my $format ( $content->{format} ) {
      last if !$format;

      return _parse_html_body( $content->{formatted_body} ) if
         CAN_PARSE_HTML and $format eq "org.matrix.custom.html";
   }

   return String::Tagged->new( $content->{body} );
}

sub _parse_html_body
{
   my ( $formatted ) = @_;

   return _traverse_html( HTML::TreeBuilder->new_from_content( $formatted )
      ->find_by_tag_name( 'body' )
   );
}

sub _traverse_html
{
   my ( $node ) = @_;

   # Plain text
   return String::Tagged->new( $node ) if !ref $node;

   my %tags;
   for ( $node->tag ) {
      ( $_ eq "b" || $_ eq "strong" ) and $tags{bold}++,   last;
      ( $_ eq "i" || $_ eq "em" )     and $tags{italic}++, last;

      $_ eq "u"      and $tags{under}++,  last;
      $_ eq "strike" and $tags{strike}++, last;

      ( $_ eq "tt" || $_ eq "code" )  and $tags{monospace}++, last;

      if( $_ eq "font" ) {
         my %attrs = $node->all_attr;

         my $fg = defined $attrs{color} ?
            eval { Convert::Color::HTML->new( $attrs{color} ) } :
            undef;

         $tags{fg} = $fg if defined $fg;

         last;
      }
   }

   my $ret = String::Tagged->new;

   $ret .= _traverse_html( $_ ) for $node->content_list;

   $ret->apply_tag( 0, length $ret, $_, $tags{$_} ) for keys %tags;

   return $ret;
}

=head2 build_formatted_message

   $content = build_formatted_message( $str )

Given a L<String::Tagged::Formatting> instance or plain string, returns a
content HASH reference encoding the formatting the message. Plain strings are
returned simply as a plain-text body; formatted instances will be output as
formatted content if possible:

=over 4

=item org.matrix.custom.html

This format is output for formatted messages if L<String::Tagged::HTML> is
available.

 String::Tagged::Formatting | HTML
 ---------------------------+--------------------
 'bold'                     | <strong>
 'italic'                   | <em>
 'under'                    | <u>
 'strike'                   | <strike>
 'monospace'                | <code>
 'fg'                       | <font color="...">

=back

=cut

sub build_formatted_message
{
   my ( $str ) = @_;

   return { body => $str } if !ref $str;

   if( $str->tagnames and CAN_BUILD_HTML ) {
      my $html = String::Tagged::HTML->clone( $str,
         only_tags => [qw( bold italic under strike monospace fg )],
         convert_tags => {
            bold      => "strong",
            italic    => "em",
            under     => "u",
            strike    => "strike",
            monospace => "code",
            fg        => sub { font => { color => $_[1]->as_html->name } },
         },
      );

      return {
         body => $str->str,
         format => "org.matrix.custom.html",
         formatted_body => $html->as_html,
      };
   }
   else {
      return { body => $str->str };
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
