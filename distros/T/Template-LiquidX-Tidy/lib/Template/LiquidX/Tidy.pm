package Template::LiquidX::Tidy;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.01';

use Template::LiquidX::Tidy::Liquid::Utility;
use Template::Liquid;
use Template::Liquid::Document;
use Template::Liquid::Tag::If;
use Template::Liquid::Tag::Case;

use Exporter 'import';
our @EXPORT_OK = qw(transform_back);

our %defaults = (
    indent	  => 4,
    force_nl	  => 0,
    force_nl_tags => 'for endfor '
    .'comment endcomment '
    .'if unless elsif else endif endunless '
#    .'capture '
    .'case when endcase',
    short_if      => 8,
    html	  => 1,
   );

our $_patched;
sub _patch_liquid_store_block_markup {
    return if $_patched++;
    no warnings 'redefine';

    my $_if_push_block = \&Template::Liquid::Tag::If::push_block;
    *Template::Liquid::Tag::If::push_block = sub {
	my $self = shift;
	my ($vars) = @_;
	my $block = $_if_push_block->($self, $vars);
	$block->{markup} = $vars->{markup};
	$block
    };

    my $_case_push_block = \&Template::Liquid::Tag::Case::push_block;
    *Template::Liquid::Tag::Case::push_block = sub {
	my $self = shift;
	my ($vars) = @_;
	my $block = $_case_push_block->($self, $vars);
	$block->{markup} = $vars->{markup};
	$block
    };

    return;
}

BEGIN {
    _patch_liquid_store_block_markup();
}

package Template::Liquid::Document {
    use strict;
    use warnings;
    use experimental 'signatures';

    use Template::LiquidX::Tidy::impl qw(_tidy_list _tidy_make_string);

    sub dump ($self) {
	my $return = '';
	$return .= $self->{markup} if defined $self->{markup};
	for my $node (@{$self->{nodelist}},
		      @{$self->{blocks}}) {
	    my $rendering = ref $node ? $node->dump() : $node;
	    $return .= $rendering if defined $rendering;
	}
	$return .= $self->{markup_2} if defined $self->{markup_2};
	$return
    }

    sub tidy ($self, $args = {}, $level = 0, $clevel = 0, $list = undef) {
	my @list = _tidy_list($self, $args, $level, $clevel);
	if ($list) {
	    @list
	} else {
	    _tidy_make_string($self, $args, @list)
	}
    }

    sub transform ($self, $args = {}, $trans_map = {}, $is_block = undef) {
	my $return = '';
	$trans_map->{__i} ||= 1;
	my $i = $trans_map->{__i}++;
	$trans_map->{ $i } = $self;

	if (defined $self->{markup}) {
	    my $ent = '&#' . (1_040_000 + $i) . ';';
	    if ($self->{markup} =~ /^\s*\{\{/) {
		$return .= $ent;
	    }
	    elsif ($self->{blocks}) {
		$return .= '<div id="' . $ent . '">';
	    }
	    else {
		$return .= '<i id="' . $ent . '"></i>';
	    }
	}

	if ($self->{nodelist}) {
	    for my $node ($self->{nodelist}->@*) {
		my $rendering;
		if (ref $node) {
		    ($rendering) = $node->transform($args, $trans_map);
		}
		else {
		    $rendering = $node;
		}

		$return .= $rendering if defined $rendering;
	    }
	}

	if ($self->{blocks}) {
	    for my $block ($self->{blocks}->@*) {
		my $rendering;
		if (ref $block) {
		    ($rendering) = $block->transform($args, $trans_map, 1);
		}
		else {
		    $rendering = $block;
		}

		$return .= $rendering if defined $rendering;
	    }
	}

	if (defined $self->{markup_2}) {
	    my $ent = '&#' . (1_041_000 + $i) . ';';
	    if ($self->{markup} =~ /^\s*\{\{/) {
		$return .= $ent;
	    }
	    elsif (defined $self->{markup} && $self->{blocks}) {
		$return .= '</div><!-- id="' . $ent . '" -->';
	    }
	    else {
		$return .= '<i id="' . $ent . '"></i>';
	    }
	}

	($return, $trans_map)
    }
};


sub transform_back ($trans, $map) {
    $trans =~ s{
		   (?: (?<command> <i \s+ id\s*=\s*"&\#104(?<content_part> [01])(?<id> [0-9]{3});"></i> )
		     | (?<opentag> <div \s+ id\s*=\s*"&\#104(?<content_part> 0)(?<id> [0-9]{3});">)
		     | (?<closetag> </div><!-- \s+ id\s*=\s*"&\#104(?<content_part> 1)(?<id> [0-9]{3});" \s+ --> )
		     | (?<content> &\#104(?<content_part> [01])(?<id> [0-9]{3}); )
		   )
	   }{
	       $map->{ $+{id} + 0 }{ $+{content_part} ? 'markup_2' : 'markup' }
	   }grex;
}

1;

=head1 NAME

Template::LiquidX::Tidy - Indentation for Liquid template documents

=head1 SYNOPSIS

    use Template::LiquidX::Tidy;
    use Template::Liquid;
    use Template::LiquidX::Tag::...; # any additional tag modules you need

    my $parsed      = Template::Liquid->parse($template_string);
    my $tidy_string = $parsed->{document}->tidy(\%options);

=head1 DESCRIPTION

The LiquidX::Tidy module enhances a parsed Template::Liquid::Document
with a method to indent the document source code according to some
options.

You can also use the command line client L<liquid_tidy> to indent your
template source codes.

=head1 METHODS

=head2 Template::Liquid::Document::tidy(%options)

This method is to be called on a L<Template::Liquid::Document>, i.e. some
node in the document created by C<Template::Liquid-E<gt>parse>.

It returns a string of the formatted and indented document node.

Th following options are possible:

=over 4

=item B<html> =E<gt> boolean

Indent HTML code. Defaults to on.

=item B<indent> =E<gt> number

The number of spaces for each indentation level. Default 4.

=item B<force_nl> =E<gt> boolean

Whether to forcibly add line breaks into tags listed as
force_nl_tags.

Default no for the module, yes for the command line client.

=item B<short_if> =E<gt> number

The length of a text inbetween C<{% if %}> that should be exempt from force_nl

=item B<force_nl_tags> =E<gt> 'for endfor ...'

A space separated list of tags where C<force_nl> will add line breaks.

Default tags: for endfor comment endcomment if unless elsif else endif
endunless case when endcase

=back

=head2 Template::Liquid::Document::dump()

This method is to be called on a L<Template::Liquid::Document>, i.e. some
node in the document created by C<Template::Liquid-E<gt>parse>.

It returns a copy of the source document.

=head2 Template::Liquid::Document::transform()

    my ($transformed_document, $replacement_map) = $document->transform();
    my $new_document = Template::LiquidX::Tidy::transform_back(
        $transformed_document, $replacement_map);

This method is to be called on a L<Template::Liquid::Document>, i.e. some
node in the document created by C<Template::Liquid-E<gt>parse>.

It returns a tuple with the source document where all Liquid tags have
been replaced by HTML entities and blank C<E<lt>divE<gt>> and
C<E<lt>iE<gt>> tags. This HTML document can the be further processed
before using the C<transform_back> method to put back the Liquid tags.

=head2 Template::LiquidX::Tidy::transform_back($transformed_document, $replacement_map)

This method returns a new template string undoing a transform
operation.

=cut

