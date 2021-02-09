package Pod::WordML;
use strict;
use base 'Pod::PseudoPod';

use warnings;
no warnings;

use Carp;

our $VERSION = '0.165';

=encoding utf8

=head1 NAME

Pod::WordML - Turn Pod into Microsoft Word's WordML

=head1 SYNOPSIS

	use Pod::WordML;

=head1 DESCRIPTION

***THIS IS AN ABANDONED MODULE. YOU CAN ADOPT IT ***
*** https://pause.perl.org/pause/authenquery?ACTION=pause_04about#takeover ***

I wrote just enough of this module to get my job done, and I skipped every
part of the specification I didn't need while still making it flexible enough
to handle stuff later.

=head2 The style information

I don't handle all of the complexities of styles, defining styles, and
all that other stuff. There are methods to return style names, and you
can override those in a subclass.

=cut

=over 4

=item document_header

This is the start of the document that defines all of the styles. You'll need
to override this. You can take this directly from

=cut

sub document_header
	{
	my $string = <<'XML';
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<?mso-application progid="Word.Document"?>
<w:wordDocument xmlns:aml="http://schemas.microsoft.com/aml/2001/core" xmlns:dt="uuid:C2F41010-65B3-11d1-A29F-00AA00C14882" xmlns:mo="http://schemas.microsoft.com/office/mac/office/2008/main" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:mv="urn:schemas-microsoft-com:mac:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.microsoft.com/office/word/2003/wordml" xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint" xmlns:wsp="http://schemas.microsoft.com/office/word/2003/wordml/sp2" xmlns:sl="http://schemas.microsoft.com/schemaLibrary/2003/core" w:macrosPresent="no" w:embeddedObjPresent="no" w:ocxPresent="no" xml:space="preserve">
<w:ignoreSubtree w:val="http://schemas.microsoft.com/office/word/2003/wordml/sp2" />
XML

	$string .= $_[0]->fonts . $_[0]->lists . $_[0]->styles;

	$string .= <<'XML';
<w:body>
XML
	}


sub fonts  { '' }
sub lists  { '' }
sub styles { '' }

=item document_footer

=cut

sub document_footer
	{
	<<'XML';
</w:body>
</w:wordDocument>
XML
	}

=item head1_style, head2_style, head3_style, head4_style

The paragraph styles to use with each heading level. By default these are
C<Head1Style>, and so on.

=cut

sub head0_style         { 'Heading0' }
sub head1_style         { 'Heading1' }
sub head2_style         { 'Heading2' }
sub head3_style         { 'Heading3' }
sub head4_style         { 'Heading4' }

=item normal_paragraph_style

The paragraph style for normal Pod paragraphs. You don't have to use this
for all normal paragraphs, but you'll have to override and extend more things
to get everything just how you like. You'll need to override C<start_Para> to
get more variety.

=cut

sub normal_para_style   { 'NormalParagraphStyle' }

=item bullet_paragraph_style

Like C<normal_paragraph_style>, but for paragraphs sections under C<=item>
sections.

=cut

sub first_item_para_style     { 'FirstItemParagraphStyle'  }
sub middle_item_para_style    { 'MiddleItemParagraphStyle' }
sub last_item_para_style      { 'LastItemParagraphStyle'   }
sub item_subpara_style        { 'ItemSubParagraphStyle'    }

=item code_paragraph_style

Like C<normal_paragraph_style>, but for verbatim sections. To get more fancy
handling, you'll need to override C<start_Verbatim> and C<end_Verbatim>.

=cut

sub code_para_style        { 'CodeParagraphStyle'   }
sub single_code_line_style { 'CodeParagraphStyle'   }

=item inline_code_style

The character style that goes with C<< CE<lt>> >>.

=cut

sub inline_code_style	{ 'CodeCharacterStyle' }

=item inline_url_style

The character style that goes with C<< UE<lt>E<gt> >>.

=cut

sub inline_url_style    { 'URLCharacterStyle'  }

=item inline_italic_style

The character style that goes with C<< IE<lt>> >>.

=cut

sub inline_italic_style { 'ItalicCharacterStyle' }

=item inline_bold_style

The character style that goes with C<< BE<lt>> >>.

=cut

sub inline_bold_style   { 'BoldCharacterStyle' }

=back

=head2 The Pod::Simple mechanics

Everything else is the same stuff from C<Pod::Simple>.

=cut
use Data::Dumper;
sub new { my $self = $_[0]->SUPER::new() }

sub emit
	{
	print {$_[0]->{'output_fh'}} $_[0]->{'scratch'};
	$_[0]->{'scratch'} = '';
	return;
	}

sub get_pad
	{
	# flow elements first
	   if( $_[0]{module_flag}   ) { 'scratch'   }
	elsif( $_[0]{url_flag}      ) { 'url_text'      }
	# then block elements
	# finally the default
	else                          { 'scratch'       }
	}

sub start_Document
	{
	$_[0]->{'scratch'} .= $_[0]->document_header; $_[0]->emit;
	}

sub end_Document
	{
	$_[0]->{'scratch'} .= $_[0]->document_footer; $_[0]->emit;
	}

=begin comment

    <w:p wsp:rsidR="001A510A" wsp:rsidRDefault="001A510A" wsp:rsidP="001A510A">
      <w:pPr>
        <w:pStyle w:val="Heading1" />
      </w:pPr>
      <w:r>
        <w:t>This is an h1</w:t>
      </w:r>
    </w:p>

=end comment

=cut

sub _header_start
	{
	my( $self, $style, $level ) = @_;

	my $format = '  <w:p>
    <w:pPr>
      <w:pStyle w:val="%s" />
    </w:pPr>
    <w:r>
      <w:t>';

	$self->{scratch} = sprintf $format, $style;
	$self->emit;
	}

sub _header_end
	{
	'</w:t>
    </w:r>
  </w:p>
';
	}

sub start_head0     { $_[0]->_header_start( $_[0]->head0_style, 0 ); }
sub end_head0       { $_[0]{'scratch'}  .= $_[0]->_header_end; $_[0]->end_non_code_text }

sub start_head1     { $_[0]->_header_start( $_[0]->head1_style, 1 ); }
sub end_head1       { $_[0]{'scratch'}  .= $_[0]->_header_end; $_[0]->end_non_code_text }

sub start_head2     { $_[0]->_header_start( $_[0]->head2_style, 2 );  }
sub end_head2       { $_[0]{'scratch'} .= $_[0]->_header_end; $_[0]->end_non_code_text }

sub start_head3     { $_[0]->_header_start( $_[0]->head3_style, 3 );  }
sub end_head3       { $_[0]{'scratch'} .= $_[0]->_header_end; $_[0]->end_non_code_text }

sub start_head4     { $_[0]->_header_start( $_[0]->head4_style, 4 );  }
sub end_head4       { $_[0]{'scratch'} .= $_[0]->_header_end; $_[0]->end_non_code_text }

sub end_non_code_text
	{
	my $self = shift;

	$self->make_curly_quotes;

	$self->emit;
	}

=begin comment

<w:body>
  <w:p wsp:rsidR="1" wsp:rsidRDefault="4">
    <w:r>
      <w:t>This is a line in a paragraph</w:t>
    </w:r>
  </w:p>
  <w:p wsp:rsidR="2" wsp:rsidRDefault="5" />
  <w:p wsp:rsidR="3" wsp:rsidRDefault="5">
    <w:r>
      <w:t>This is another line in another paragraph</w:t>
    </w:r>
  </w:p>
  <w:sectPr wsp:rsidR="00285A57" wsp:rsidSect="00285A57">
    <w:pgSz w:w="12240" w:h="15840" />
    <w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:gutter="0" />
  </w:sectPr>
</w:body>

=end comment

=cut

sub make_para
	{
	my( $self, $style, $para ) = @_;

	$self->{'scratch'}  =
qq|  <w:p>
    <w:pPr>
      <w:pStyle w:val="$style" />
    </w:pPr>
    <w:r>
      <w:t>$para</w:t>
    </w:r>
  </w:p>
|;

	$self->emit;
	}

sub start_Para
	{
	my $self = shift;

	# it would be nice to take this through make_para
	my $style = do {
		if( $self->{in_item} )
			{
			if( $self->{item_count} == 1 ) { $self->first_item_para_style }
			else                           { $self->middle_item_para_style }
			}
		elsif( $self->{in_item_list} ) { $self->item_subpara_style }
		else                           { $self->normal_para_style  }
		};

	$self->{'scratch'}  =
qq|  <w:p>
    <w:pPr>
      <w:pStyle w:val="$style" />
    </w:pPr>
    <w:r>
      <w:t>|;

	$self->{'scratch'} .= "\x{25FE} " if $self->{in_item};

	$self->emit;

	$self->{'in_para'} = 1;
	}


sub end_Para
	{
	my $self = shift;

	$self->{'scratch'} .= '</w:t>
    </w:r>
  </w:p>
';

	$self->emit;

	$self->end_non_code_text;

	$self->{'in_para'} = 0;
	}

sub start_figure 	{ }

sub end_figure      { }

sub first_code_line_style  { 'first code line'   }
sub middle_code_line_style { 'middle code line'  }
sub last_code_line_style   { 'last code line'    }

sub first_code_line  { $_[0]->make_para( $_[0]->first_code_line_style,  $_[1] ) }
sub middle_code_line { $_[0]->make_para( $_[0]->middle_code_line_style, $_[1] ) }
sub last_code_line   { $_[0]->make_para( $_[0]->last_code_line_style,   $_[1] ) }

sub start_Verbatim
	{
	$_[0]{'in_verbatim'} = 1;
	}

sub end_Verbatim
	{
	my $self = shift;

	# get rid of all but one trailing newline
	$self->{'scratch'} =~ s/\s+\z//;

	chomp( my @lines = split m/^/m, $self->{'scratch'} );
	$self->{'scratch'} = '';

	@lines = map { s/</&lt;/g; $_ } @lines;

	if( @lines == 1 )
		{
		$self->make_para( $self->single_code_line_style, @lines );
		}
	elsif( @lines )
		{
		my $first = shift @lines;
		my $last  = pop   @lines;

		$self->first_code_line( $first );

		foreach my $line ( @lines )
			{
			$self->middle_code_line( $line );
			}

		$self->last_code_line( $last );
		}

	$self->{'in_verbatim'} = 0;
	}

sub _get_initial_item_type
	{
	my $self = shift;

	my $type = $self->SUPER::_get_initial_item_type;

	#print STDERR "My item type is [$type]\n";

	$type;
	}

=pod

  <w:p wsp:rsidR="00FE5092" wsp:rsidRDefault="00FE5092" wsp:rsidP="00FE5092">
    <w:pPr>
      <w:pStyle w:val="ListBullet" />
      <w:listPr>
        <wx:t wx:val="·" />
        <wx:font wx:val="Symbol" />
      </w:listPr>
    </w:pPr>
    <w:r>
      <w:t>List item 1</w:t>
    </w:r>
  </w:p>

=cut

sub not_implemented { croak "Not implemented!" }

sub bullet_item_style { 'bullet item' }
sub start_item_bullet
	{
	my( $self ) = @_;

	$self->{in_item} = 1;
	$self->{item_count}++;

	$self->start_Para;
	}

sub start_item_number { not_implemented() }
sub start_item_block  { not_implemented() }
sub start_item_text   { not_implemented() }

sub end_item_bullet
	{
	my $self = shift;
	$self->end_Para;
	$self->{in_item} = 0;
	}
sub end_item_number { not_implemented() }
sub end_item_block  { not_implemented() }
sub end_item_text   { not_implemented() }

sub start_over_bullet
	{
	my $self = shift;

	$self->{in_item_list} = 1;
	$self->{item_count}   = 0;
	}
sub start_over_text   { not_implemented() }
sub start_over_block  { not_implemented() }
sub start_over_number { not_implemented() }

sub end_over_bullet
	{
	my $self = shift;

	$self->end_non_code_text;

	$self->{in_item_list} = 0;
	$self->{item_count}   = 0;
	$self->{last_thingy}  = 'item_list';
	$self->{scratch}      = '';
	}
sub end_over_text   { not_implemented() }
sub end_over_block  { not_implemented() }
sub end_over_number { not_implemented() }

sub start_char_style
	{
	my( $self, $style ) = @_;

	$self->{'scratch'} .= qq|</w:t>
    </w:r>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="$style" />
      </w:rPr>
      <w:t>|;

	$self->emit;
	}

sub end_char_style
	{
	$_[0]->{'scratch'} .= '</w:t>
    </w:r>
    <w:r>
      <w:t>';

	$_[0]->emit;
	}


sub bold_char_style { 'Bold' }
sub end_B    { $_[0]->end_char_style }
sub start_B
	{
	$_[0]->start_char_style( $_[0]->bold_char_style );
	}

sub inline_code_char_style { 'Code' }
sub start_C
	{
	$_[0]->{in_C} = 1;
	$_[0]->start_char_style( $_[0]->inline_code_char_style );
	}
sub end_C
	{
	$_[0]->end_char_style;
	$_[0]->{in_C} = 0;
	}

sub italic_char_style { 'Italic' }
sub end_I   { $_[0]->end_char_style }
sub start_I { $_[0]->start_char_style( $_[0]->italic_char_style ); }

sub start_F { $_[0]->end_char_style }
sub end_F   { $_[0]->start_char_style( $_[0]->italic_char_style ); }

sub start_M
	{
	$_[0]{'module_flag'} = 1;
	$_[0]{'module_text'} = '';
	$_[0]->start_C;
	}

sub end_M
	{
	$_[0]->end_C;
	$_[0]{'module_flag'} = 0;
	}

sub start_N { }
sub end_N   { }

sub start_U { $_[0]->start_I }
sub end_U   { $_[0]->end_I   }

sub handle_text
	{
	my( $self, $text ) = @_;

	my $pad = $self->get_pad;

	$self->escape_text( \$text );
	$self->{$pad} .= $text;

	unless( $self->dont_escape )
		{
		$self->make_curly_quotes;
		$self->make_em_dashes;
		$self->make_ellipses;
		}
	}

sub dont_escape {
	my $self = shift;
	$self->{in_verbatim} || $self->{in_C}
	}

sub escape_text
	{
	my( $self, $text_ref ) = @_;

	$$text_ref =~ s/&/&amp;/g;
	$$text_ref =~ s/</&lt;/g;

	return 1;
	}

sub make_curly_quotes
	{
	my( $self ) = @_;

	my $text = $self->{scratch};

	require Tie::Cycle;

	tie my $cycle, 'Tie::Cycle', [ qw( &#x201C; &#x201D; ) ];

	1 while $text =~ s/"/$cycle/;

	# escape escape chars. This is escpaing them for InDesign
	# so don't worry about double escaping for other levels. Don't
	# worry about InDesign in the pod.
	$text =~ s/'/&#x2019;/g;

	$self->{'scratch'} = $text;

	return 1;
	}

sub make_em_dashes
	{
	$_[0]->{scratch} =~ s/--/&#x2014;/g;
	return 1;
	}

sub make_ellipses
	{
	$_[0]->{scratch} =~ s/\Q.../&#x2026;/g;
	return 1;
	}

BEGIN {
require Pod::Simple::BlackBox;

package Pod::Simple::BlackBox;

sub _ponder_Verbatim {
	my ($self,$para) = @_;
	DEBUG and print STDERR " giving verbatim treatment...\n";

	$para->[1]{'xml:space'} = 'preserve';
	foreach my $line ( @$para[ 2 .. $#$para ] )
		{
		$line =~ s/^\t//gm;
		$line =~ s/^(\t+)/" " x ( 4 * length($1) )/e
  		}

  # Now the VerbatimFormatted hoodoo...
  if( $self->{'accept_codes'} and
      $self->{'accept_codes'}{'VerbatimFormatted'}
  ) {
    while(@$para > 3 and $para->[-1] !~ m/\S/) { pop @$para }
     # Kill any number of terminal newlines
    $self->_verbatim_format($para);
  } elsif ($self->{'codes_in_verbatim'}) {
    push @$para,
    @{$self->_make_treelet(
      join("\n", splice(@$para, 2)),
      $para->[1]{'start_line'}, $para->[1]{'xml:space'}
    )};
    $para->[-1] =~ s/\n+$//s; # Kill any number of terminal newlines
  } else {
    push @$para, join "\n", splice(@$para, 2) if @$para > 3;
    $para->[-1] =~ s/\n+$//s; # Kill any number of terminal newlines
  }
  return;
}

}

BEGIN {

# override _treat_Es so I can localize e2char
sub _treat_Es
	{
	my $self = shift;

	require Pod::Escapes;
	local *Pod::Escapes::e2char = *e2char_tagged_text;

	$self->SUPER::_treat_Es( @_ );
	}

sub e2char_tagged_text
	{
	package Pod::Escapes;

	my $in = shift;

	return unless defined $in and length $in;

	   if( $in =~ m/^(0[0-7]*)$/ )         { $in = oct $in; }
	elsif( $in =~ m/^0?x([0-9a-fA-F]+)$/ ) { $in = hex $1;  }

	if( $NOT_ASCII )
	  	{
		unless( $in =~ m/^\d+$/ )
			{
			$in = $Name2character{$in};
			return unless defined $in;
			$in = ord $in;
	    	}

		return $Code2USASCII{$in}
			|| $Latin1Code_to_fallback{$in}
			|| $FAR_CHAR;
		}

 	if( defined $Name2character_number{$in} and $Name2character_number{$in} < 127 )
 		{
 		return "&$in;";
 		}
	elsif( defined $Name2character_number{$in} )
		{
		# this needs to be fixed width because I want to look for
		# it in a negative lookbehind
		return sprintf '&#x%04x;', $Name2character_number{$in};
		}
	else
		{
		return '???';
		}

	}
}

=head1 TO DO


=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This is an abandoned module. You can adopt it if you like:

	https://pause.perl.org/pause/authenquery?ACTION=pause_04about#takeover

This source is in Github:

	https://github.com/CPAN-Adoptable-Modules/pod-wordml.git

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2009-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the Artistic License 2.0.

=cut

1;
