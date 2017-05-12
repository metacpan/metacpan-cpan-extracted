#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Parse::Man;

use strict;
use warnings;

use base qw( Parser::MGC );

our $VERSION = '0.02';

use constant pattern_ws => qr/[ \t]+/;

=head1 NAME

C<Parse::Man> - parse nroff-formatted manpages

=head1 DESCRIPTION

This abstract subclass of L<Parser::MGC> recognises F<nroff> grammar from a
file or string value. It invokes methods when various F<nroff> directives are
encountered. It is intended that this class be used as a base class, with
methods provided to handle the various directives and formatting options.
Typically a subclass will store intermediate results in a data structure,
building it as directed by these method invocations.

=cut

sub parse
{
   my $self = shift;

   $self->_change_para_options(
      mode    => "P",
      filling => 1,
      indent  => 0,
   );
   $self->{para_flushed} = 0;

   $self->sequence_of( \&parse_line );
}

sub token_nl
{
   my $self = shift;
   $self->expect( "\n" );
}

sub token_chunk
{
   my $self = shift;

   return $self->any_of(
      sub { ( $self->expect( qr/"((?:\\.|[^"\\\n]+)*)(?:"|$)/m ) )[1] },
      sub { $self->expect( qr/\S+/ ) },
   );
}

sub parse_chunks
{
   my $self = shift;
   @{ $self->sequence_of( \&token_chunk ) };
}

sub parse_chunks_flat
{
   my $self = shift;
   return join " ", $self->parse_chunks;
}

sub parse_line
{
   my $self = shift;

   $self->commit;

   $self->any_of(
      sub {
         my $directive = ( $self->expect( qr/\.([A-Z]+)/i ) )[1];
         $self->commit;
         $self->${\"parse_directive_$directive"}( $self );
         $self->token_nl;
      },
      sub {
         # comments
         $self->expect( qr/\.\\".*?\n/ );
      },
      sub {
         $self->commit;
         $self->scope_of( undef, sub { $self->parse_plaintext }, "\n" );
      },
   );
}

=head1 TEXT CHUNK FORMATTING METHOD

The following method is used to handle formatted text. Each call is passed a
plain string value from the input content.

=cut

=head2 $parser->chunk( $text, %opts )

The C<%opts> hash contains the following options:

=over 4

=item font => STRING

The name of the current font (C<R>, C<B>, etc..)

=item size => INT

The current text size, relative to a paragraph base of 0.

=back

=cut

sub parse_directive_B
{
   my $self = shift;
   $self->_flush_para;
   $self->chunk( $self->parse_chunks_flat, font => "B", size => 0 );
}

sub parse_directive_I
{
   my $self = shift;
   $self->_flush_para;
   $self->chunk( $self->parse_chunks_flat, font => "I", size => 0 );
}

sub parse_directive_R
{
   my $self = shift;
   $self->_flush_para;
   $self->chunk( $self->parse_chunks_flat, font => "R", size => 0 );
}

sub parse_directive_SM
{
   my $self = shift;
   $self->_flush_para;
   $self->chunk( $self->parse_chunks_flat, font => "R", size => -1 );
}

sub _parse_directive_alternate
{
   my $self = shift;
   my ( $first, $second ) = @_;
   $self->_flush_para;
   my $i = 0;
   map { $self->chunk( $_, font => ( ++$i % 2 ? $first : $second ), size => 0 ) } $self->parse_chunks;
}

sub parse_directive_BI
{
   my $self = shift;
   $self->_parse_directive_alternate( "B", "I" );
}

sub parse_directive_IB
{
   my $self = shift;
   $self->_parse_directive_alternate( "I", "B" );
}

sub parse_directive_RB
{
   my $self = shift;
   $self->_parse_directive_alternate( "R", "B" );
}

sub parse_directive_BR
{
   my $self = shift;
   $self->_parse_directive_alternate( "B", "R" );
}

sub parse_directive_RI
{
   my $self = shift;
   $self->_parse_directive_alternate( "R", "I" );
}

sub parse_directive_IR
{
   my $self = shift;
   $self->_parse_directive_alternate( "I", "R" );
}

=pod

Other font requests that are found in C<\fX> or C<\f(AB> requests are handled
by similarly-named methods.

=cut

=head1 PARAGRAPH HANDLING METHODS

The following methods are used to form paragraphs out of formatted text
chunks. Their return values are ignored.

=cut

=head2 $parser->para_TH( $name, $section )

Handles the C<.TH> paragraph which gives the page title and section number.

=cut

sub parse_directive_TH
{
   my $self = shift;
   $self->_change_para( "P" ),
   $self->para_TH( $self->parse_chunks );
}

=head2 $parser->para_SH( $title )

Handles the C<.SH> paragraph, which gives a section header.

=cut

sub parse_directive_SH
{
   my $self = shift;
   $self->_change_para( "P" ),
   $self->para_SH( $self->parse_chunks_flat );
}

=head2 $parser->para_SS( $title )

Handles the C<.SS> paragraph, which gives a sub-section header.

=cut

sub parse_directive_SS
{
   my $self = shift;
   $self->_change_para( "P" ),
   $self->para_SS( $self->parse_chunks_flat );
}

=head2 $parser->para_TP( $opts )

Handles a C<.TP> paragraph, which gives a term definition.

=cut

sub parse_directive_TP
{
   my $self = shift;
   $self->_change_para( "TP" );
}

=head2 $parser->para_IP( $opts )

Handles a C<.IP> paragraph, which is indented like the definition part of a
C<.TP> paragraph.

=cut

sub parse_directive_IP
{
   my $self = shift;
   $self->_change_para( "IP" );
}

=head2 $parser->para_P( $opts )

Handles the C<.P>, C<.PP> or C<.LP> paragraphs, which are all synonyms for a
plain paragraph content.

=cut

sub parse_directive_P
{
   my $self = shift;
   $self->_change_para( "P" );
}

{
   no warnings 'once';
   *parse_directive_PP = *parse_directive_LP = \&parse_directive_P;
}

sub parse_directive_RS
{
   my $self = shift;
   $self->_change_para_options( indent => "4n" );
}

sub parse_directive_RE
{
   my $self = shift;
   $self->_change_para_options( indent => "0" );
}

sub parse_directive_br
{
   my $self = shift;
   $self->entity_br;
}

sub parse_directive_fi
{
   my $self = shift;
   $self->_change_para_options( filling => 1 );
}

sub parse_directive_in
{
   my $self = shift;

   my @ret;
   my $indent = 0;

   $self->maybe( sub {
      $indent = $self->expect( qr/[+-]?\d+[n]?/ );
   } );

   $self->_change_para_options( indent => $indent );
}

sub parse_directive_nf
{
   my $self = shift;
   $self->_change_para_options( filling => 0 );
}

sub parse_directive_sp
{
   my $self = shift;
   $self->entity_sp;
}

sub parse_plaintext
{
   my $self = shift;

   my @font = "R";

   $self->_flush_para;

   $self->sequence_of(
      sub { $self->any_of(
         sub { $self->expect( qr/\\fP/ ); pop @font },
         sub { push @font, ( $self->expect( qr/\\f([A-Z])/ ) )[1]; }, # \fX
         sub { push @font, ( $self->expect( qr/\\f\((..)/ ) )[1]; },  # \f(AB
         sub { my $else = ( $self->expect( qr/\\(.)/ ) )[1]; $self->chunk( $else, font => $font[-1], size => 0 ) },
         sub { $self->chunk( $self->substring_before( qr/[\\\n]/ ), font => $font[-1], size => 0 ) },
      ); }
   );
}

sub _change_para
{
   my $self = shift;
   my ( $mode ) = @_;
   $self->_change_para_options( mode => $mode );
   $self->{para_flushed} = 0;
}

sub _change_para_options
{
   my $self = shift;
   my %opts = @_;

   if( grep { ($self->{para_options}{$_}//"") ne $opts{$_} } keys %opts ) {
      $self->{para_flushed} = 0;
   }

   $self->{para_options}{$_} = $opts{$_} for keys %opts;
}

sub _flush_para
{
   my $self = shift;
   if( !$self->{para_flushed} ) {
      my $mode = $self->{para_options}{mode};
      $self->${\"para_$mode"}( $self->{para_options} );
      $self->{para_flushed}++;
   }
   else {
      $self->join_para;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
