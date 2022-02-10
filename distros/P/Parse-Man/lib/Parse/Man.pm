#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2022 -- leonerd@leonerd.org.uk

package Parse::Man 0.03;

use v5.14;
use warnings;
use utf8;

use base qw( Parser::MGC );

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

sub from_file
{
   my $self = shift;
   my ( $file ) = @_;

   if( $file =~ m/\.gz$/ ) {
      return $self->SUPER::from_file( $file, binmode => ":gzip" );
   }
   else {
      return $self->SUPER::from_file( $file );
   }
}

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

   $self->skip_ws;

   # A single chunk is either "quoted sequence" or whitespace-separated
   return $self->any_of(
      sub { $self->committed_scope_of( '"', "_escaped", qr/"|$/m ) },
      sub { $self->_escaped( 1 ) },
   );
}

sub _escaped
{
   my $self = shift;
   my ( $break_on_space ) = @_;
   my $ret = "";

   my $consumed = 0;

   $consumed++ while $self->any_of(
      sub { my $esc = ( $self->expect( qr/\\(?|\((..)|(.))/ ) )[1];
            $self->commit;
            $ret .= $self->parse_escape( $esc );
            1;
          },
      sub { length( my $more = $self->substring_before( $break_on_space ? qr/[\\\n\s]/ : qr/[\\\n]/ ) ) or return 0;
            $ret .= $more;
            1 },
      sub { 0 },
   );

   $consumed or $self->fail( "Expected a chunk" );

   return $ret;
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
         $self->scope_of( undef, sub {
            $self->{fonts} = [ "R" ];
            $self->parse_plaintext;
         }, "\n" );
      },
   );
}

=head1 TEXT CHUNK FORMATTING METHOD

The following method is used to handle formatted text. Each call is passed a
plain string value from the input content.

=cut

=head2 chunk

   $parser->chunk( $text, %opts )

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

   my @chunks = $self->parse_chunks;

   $self->chunk( shift @chunks, font => "R", size =>  0 ) if @chunks > 2;
   $self->chunk( shift @chunks, font => "R", size => -1 );
   $self->chunk( shift @chunks, font => "R", size =>  0 ) if @chunks;
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

=head2 para_TH

   $parser->para_TH( $name, $section )

Handles the C<.TH> paragraph which gives the page title and section number.

=cut

sub parse_directive_TH
{
   my $self = shift;
   $self->_change_para( "P" ),
   $self->para_TH( $self->parse_chunks );
}

=head2 para_SH

   $parser->para_SH( $title )

Handles the C<.SH> paragraph, which gives a section header.

=cut

sub parse_directive_SH
{
   my $self = shift;
   $self->_change_para( "P" ),
   $self->para_SH( $self->parse_chunks_flat );
}

=head2 para_SS

   $parser->para_SS( $title )

Handles the C<.SS> paragraph, which gives a sub-section header.

=cut

sub parse_directive_SS
{
   my $self = shift;
   $self->_change_para( "P" ),
   $self->para_SS( $self->parse_chunks_flat );
}

=head2 para_TP

   $parser->para_TP( $opts )

Handles a C<.TP> paragraph, which gives a term definition.

=cut

sub parse_directive_TP
{
   my $self = shift;
   $self->_change_para( "TP" );
}

=head2 para_IP

   $parser->para_IP( $opts )

Handles a C<.IP> paragraph, which is indented like the definition part of a
C<.TP> paragraph.

=cut

sub parse_directive_IP
{
   my $self = shift;
   $self->_change_para( "IP" );

   if( defined( my $marker = $self->maybe( "token_chunk" ) ) ) {
      $self->_change_para_options( marker => $marker );
   }
   if( defined( my $indent = $self->maybe( "token_chunk" ) ) ) {
      $self->_change_para_options( indent => $indent );
   }
}

=head2 para_P

   $parser->para_P( $opts )

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

=head2 para_EX

   $parser->para_EX( $opts )

Handles the C<.EX> paragraph, which is example text; intended to be rendered
in a fixed-width font without filling.

=cut

sub parse_directive_EX
{
   my $self = shift;
   $self->_push_para( "EX" );
}

sub parse_directive_EE
{
   my $self = shift;
   $self->_pop_para( "EX" );
}

sub parse_directive_RS
{
   my $self = shift;
   if( defined( my $indent = $self->maybe( "token_chunk" ) ) ) {
      $self->_change_para_options( indent => $indent );
   }
   else {
      $self->_change_para_options( indent => "4n" );
   }
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

   $self->_flush_para;

   $self->sequence_of(
      sub { $self->any_of(
         sub { my $esc = ( $self->expect( qr/\\(?|\((..)|(.))/ ) )[1];
               $self->commit;
               my @chunks = $self->parse_escape( $esc );
               $self->chunk( $_, font => $self->{fonts}[-1], size => 0 ) for @chunks;
             },
         sub { $self->chunk( $self->substring_before( qr/[\\\n]/ ), font => $self->{fonts}[-1], size => 0 ) },
      ); }
   );
}

sub parse_escape
{
   my $self = shift;
   my ( $esc ) = @_;

   my $meth = "parse_escape_$esc";
   $meth = sprintf "parse_escape_x%v02X", $esc if length($esc) == 1 and $esc =~ m/[^A-Za-z0-9]/;
   $meth = "parse_escape_char" if length($esc) > 1;
   $meth = $self->can( $meth ) or
   $self->fail( "Unrecognised escape sequence \\$esc" );
   return $self->$meth( $esc );
}

sub parse_escape_x2D # \-
{
   my $self = shift;

   # TODO: Unicode minus sign?
   return "-";
}

# Ignore the "italic corrections" for now
*parse_escape_x2C = # \,
*parse_escape_x2F = # \/
   sub { return };

# The "empty" character
sub parse_escape_x26 # \&
{
   my $self = shift;

   return "";
}

*parse_escape_e = *parse_escape_E = *parse_escape_x5C = sub {
   my $self = shift;

   return "\\";
};

sub parse_escape_f
{
   my $self = shift;

   $self->any_of(
      sub { $self->expect( qr/P/ );
            $self->commit;
            @{ $self->{fonts} } > 1 or $self->fail( "Cannot \\fP without a \\f font defined" );
            pop @{ $self->{fonts} }; },
      sub { push @{ $self->{fonts} }, ( $self->expect( qr/([A-Z])/ ) )[1]; },
      sub { push @{ $self->{fonts} }, ( $self->expect( qr/\((..)/ ) )[1]; },
   );

   return; # empty
}

# TODO: Vastly expand this table
my %chars = (
   'aq' => q('),
   'bu' => '•',
   'co' => '©',
);

sub parse_escape_char
{
   my $self = shift;
   my ( $name ) = @_;

   my $char = $chars{$name} // "<char $name>";

   return $char;
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

sub _push_para
{
   my $self = shift;
   my ( $new_mode ) = @_;

   # Shallow clone
   push @{ $self->{para_stack} }, { %{ $self->{para_options} } };
   $self->_change_para( $new_mode );
}

sub _pop_para
{
   my $self = shift;
   my ( $expect_mode ) = @_;

   $self->{para_options}{mode} eq $expect_mode or
      $self->fail( "Expected current paragraph mode of $expect_mode" );

   $self->{para_options} = pop @{ $self->{para_stack} };

   $self->_flush_para;
   $self->{para_flushed} = 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
