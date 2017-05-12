#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Parse::Man::DOM;

use strict;
use warnings;

use base qw( Parse::Man );

our $VERSION = '0.02';

=head1 NAME

C<Parse::Man::DOM> - parse nroff-formatted manpages and return a DOM tree

=head1 SYNOPSIS

 use Parse::Man::DOM;

 my $parser = Parse::Man::DOM->new;

 my $document = $parser->from_file( "my_manpage.1" );

 print "The manpage name is", $document->meta( "name" ), "\n";

=head1 DESCRIPTION

This subclass of L<Parse::Man> returns an object tree representing the parsed
content of the input file. The returned result will be an object of the
C<Parse::Man::DOM::Document> class, which itself will contain other objects
nested within it.

=cut

sub parse
{
   my $self = shift;

   local $self->{current_document} = $self->_make( document => );

   $self->SUPER::parse( @_ );

   return $self->{current_document};
}

sub para_TH
{
   my $self = shift;
   my ( $name, $section ) = @_;

   $self->{current_document}->add_meta( $self->_make( metadata => name    => $name ) );
   $self->{current_document}->add_meta( $self->_make( metadata => section => $section ) );
}

sub para_SH
{
   my $self = shift;
   my ( $text ) = @_;
   $self->{current_document}->append_para( $self->_make( heading => 1 => $text ) );
}

sub para_SS
{
   my $self = shift;
   my ( $text ) = @_;
   $self->{current_document}->append_para( $self->_make( heading => 2 => $text ) );
}

sub para_P
{
   my $self = shift;
   my ( $opts ) = @_;
   $self->{current_document}->append_para( $self->_make( para_plain => $opts, $self->_make( chunklist => ) ) );
}

sub para_TP
{
   my $self = shift;
   my ( $opts ) = @_;
   $self->{current_document}->append_para( $self->_make( para_term => $opts, $self->_make( chunklist => ), $self->_make( chunklist => ) ) );
}

sub para_IP
{
   my $self = shift;
   my ( $opts ) = @_;
   $self->{current_document}->append_para( $self->_make( para_indent => $opts, $self->_make( chunklist => ) ) );
}

sub chunk
{
   my $self = shift;
   my ( $text, %opts ) = @_;
   $self->{current_document}->append_chunk( $self->_make( chunk => $text => $opts{font}, $opts{size} ) );
}

sub join_para
{
   my $self = shift;
   $self->{current_document}->append_chunk( $self->_make( linebreak => ) );
}

sub entity_br
{
   my $self = shift;
   $self->{current_document}->append_chunk( $self->_make( break => ) );
}

sub entity_sp
{
   my $self = shift;
   $self->{current_document}->append_chunk( $self->_make( space => ) );
}

sub _make
{
   my $self = shift;
   my $type = shift;
   my $code = $self->can( "${type}_class" ) or die "Unable to make a ${type}";
   return $code->()->new( @_ );
}

use constant document_class    => "Parse::Man::DOM::Document";
use constant metadata_class    => "Parse::Man::DOM::Metadata";
use constant heading_class     => "Parse::Man::DOM::Heading";
use constant para_plain_class  => "Parse::Man::DOM::Para::Plain";
use constant para_term_class   => "Parse::Man::DOM::Para::Term";
use constant para_indent_class => "Parse::Man::DOM::Para::Indent";
use constant chunklist_class   => "Parse::Man::DOM::Chunklist";
use constant chunk_class       => "Parse::Man::DOM::Chunk";
use constant space_class       => "Parse::Man::DOM::Space";
use constant break_class       => "Parse::Man::DOM::Break";
use constant linebreak_class   => "Parse::Man::DOM::Linebreak";

package Parse::Man::DOM::Document;

=head1 Parse::Man::DOM::Document

Represents the document as a whole.

=cut

sub new
{
   my $class = shift;
   return bless { meta => {}, paras => [] }, $class;
}

=head2 $meta = $document->meta( $key )

Returns a C<Parse::Man::DOM::Metadata> object for the named item of metadata.

=over 4

=item * name

The page name given to the C<.TH> directive.

=item * section

The section number given to the C<.TH> directive.

=back

=cut

sub meta
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->{meta}{$name} || die "No meta defined for $name";
}

sub add_meta
{
   my $self = shift;
   my ( $meta ) = @_;
   $self->{meta}{ $meta->name } = $meta;
}

=head2 @paras = $document->paras

Returns a list of C<Parse::Man::DOM::Heading> or C<Parse::Man::DOM::Para> or 
subclass objects, containing the actual page content.

=cut

sub paras
{
   my $self = shift;
   return @{ $self->{paras} };
}

sub append_para
{
   my $self = shift;
   push @{ $self->{paras} }, @_;
}

sub last_para { shift->{paras}[-1] }

sub append_chunk { shift->last_para->append_chunk( @_ ) }

package Parse::Man::DOM::Metadata;

=head1 Parse::Man::DOM::Metadata

Represents a single item of metadata about the page.

=cut

sub new
{
   my $class = shift;
   return bless [ $_[0] => $_[1] ], $class;
}

=head2 $name = $metadata->name

The string name of the metadata

=head2 $value = $metadata->value

The string value of the metadata

=cut

sub name  { shift->[0] }
sub value { shift->[1] }

package Parse::Man::DOM::Heading;
use constant type => "heading";

=head1 Parse::Man::DOM::Heading

Represents the contents of a C<.SH> or C<.SS> heading

=cut

sub new
{
   my $class = shift;
   return bless [ $_[0] => $_[1] ], $class;
}

=head2 $level = $heading->level

The heading level number; 1 for C<.SH>, 2 for C<.SS>

=head2 $text = $heading->text

The plain text string of the heading title

=cut

sub level { shift->[0] }
sub text  { shift->[1] }

package Parse::Man::DOM::Para;

=head1 Parse::Man::DOM::Para

Represents a paragraph of formatted text content. Will be one of the following
subclasses.

=cut

=head2 $filling = $para->filling

Returns true if filling (C<.fi>) is in effect, or false if no-filling (C<.nf>)
is in effect.

=head2 $chunklist = $para->body

Returns a C<Parse::Man::DOM::Chunklist> to represent the actual content of the
paragraph.

=cut

sub filling { shift->{filling} }
sub body    { shift->{body} }

package Parse::Man::DOM::Para::Plain;
use base qw( Parse::Man::DOM::Para );
use constant type => "plain";

=head1 Parse::Man::DOM::Para::Plain

Represent a plain (C<.P> or C<.PP>) paragraph.

=head2 $type = $para->type

Returns C<"plain">.

=cut

sub new
{
   my $class = shift;
   my ( $opts, $body ) = @_;
   return bless { (map { $_ => $opts->{$_} } qw( filling indent )), body => $body }, $class;
}

sub append_chunk { shift->body->append_chunk( @_ ) }

package Parse::Man::DOM::Para::Term;
use base qw( Parse::Man::DOM::Para );
use constant type => "term";

=head1 Parse::Man::DOM::Para::Term

Represents a term paragraph (C<.TP>).

=head2 $type = $para->type

Returns C<"term">.

=cut

sub new
{
   my $class = shift;
   my ( $opts, $term, $definition ) = @_;

   return bless { indent => $opts->{indent}, term => $term, definition => $definition }, $class;
}

=head2 $chunklist = $para->term

Returns a C<Parse::Man::DOM::Chunklist> for the defined term name.

=head2 $chunklist = $para->definition

Returns a C<Parse::Man::DOM::Chunklist> for the defined term definition.

=cut

sub term       { shift->{term} }
sub definition { shift->{definition} }

sub append_chunk
{
   my $self = shift;
   my ( $chunk ) = @_;
   if( !$self->{term_done} and $chunk->isa( "Parse::Man::DOM::Linebreak" ) ) {
      $self->{term_done} = 1;
   }
   elsif( !$self->{term_done} ) {
      $self->term->append_chunk( $chunk );
   }
   else {
      $self->definition->append_chunk( $chunk );
   }
}

package Parse::Man::DOM::Para::Indent;
use base qw( Parse::Man::DOM::Para::Plain );
use constant type => "indent";

=head1 Parse::Man::DOM::Para::Indent

Represents an indented paragraph (C<.IP>).

=head2 $type = $para->type

Returns C<"indent">.

=cut

package Parse::Man::DOM::Chunklist;

=head1 Parse::Man::DOM::Chunklist

Contains a list of C<Parse::Man::DOM::Chunk> objects to represent paragraph
content.

=cut

sub new
{
   my $class = shift;
   return bless { chunks => [ @_ ] }, $class;
}

=head2 @chunks = $chunklist->chunks

Returns a list of C<Parse::Man::DOM::Chunk> objects.

=cut

sub chunks { @{ shift->{chunks} } }

sub append_chunk
{
   my $self = shift;
   push @{ $self->{chunks} }, @_;
}

package Parse::Man::DOM::Chunk;

=head1 Parse::Man::DOM::Chunk

Represents a chunk of text with a particular format applied.

=cut

sub new
{
   my $class = shift;
   return bless [ @_ ], $class;
}

sub is_linebreak { 0 }
sub is_space     { 0 }
sub is_break     { 0 }

=head2 $text = $chunk->text

The plain string value of the text for this chunk.

=head2 $font = $chunk->font

The font name in effect for this chunk. One of C<"R">, C<"B">, C<"I"> or
C<"SM">.

=head2 $size = $chunk->size

The size of this chunk, relative to the paragraph base of 0.

=cut

sub text { shift->[0] }
sub font { shift->[1] }
sub size { shift->[2] }

package Parse::Man::DOM::Linebreak;
use base qw( Parse::Man::DOM::Chunk );

sub new
{
   my $class = shift;
   return bless [], $class;
}

sub is_linebreak { 1 }

package Parse::Man::DOM::Space;
use base qw( Parse::Man::DOM::Chunk );

sub new
{
   my $class = shift;
   return bless [], $class;
}

sub is_space { 1 }

package Parse::Man::DOM::Break;
use base qw( Parse::Man::DOM::Chunk );

sub new
{
   my $class = shift;
   return bless [], $class;
}

sub is_break { 1 }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
