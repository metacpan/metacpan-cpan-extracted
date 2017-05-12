#$Revision: 1.5 $
package Test_LinkParser;
use Pod::ParseUtils;
use strict;
use vars '@ISA', '$VERSION';
@ISA = 'Pod::Hyperlink';
$VERSION = ('$Revision: 1.5 $' =~ /([\d\.]+)/)[0];

# Override Pod::Hyperlink for the unit tests since different versions behave
# differently WRT decorating links (e.g. '... elsewhere in this document')

TRACE("\$Pod::ParseUtils::VERSION: " . $Pod::ParseUtils::VERSION);

if (1) { # Set to '0' to test against Pod::Hyperlink
	*markup = *markup = \&_markup;
	*text = *text = \&_text;
}

sub _markup {
	my $self = shift;
	my $page = $self->page;
	my $node = $self->node;
	my $type = $self->type;
	$self->SUPER::markup(@_);
	my $text = $self->text(@_);
	DUMP($self);

	return $type eq 'hyperlink' ? $text
		: $self->alttext ? "Q<" . $self->alttext . ">"
		: $page && $node ? "Q<$node> in P<$page>"
		: !$page ? "Q<$node>"
		: $page && ! $node ?
			$page =~ /^(\w+)\((\d)\)/ ? "P<$1>($2)"  # manpages
			: "P<$page>"
		: 'XXX';
}

sub _text {
	my $self = shift;
	my $page = $self->page;
	my $node = $self->node;
	my $type = $self->type;
	my $text = $self->SUPER::text(@_);
	DUMP($self);

	return $type eq 'hyperlink' ? $text
		: $self->alttext ? $self->alttext
		: $page && $node ? "$node in $page"
		: !$page ? "$node"
		: $page && ! $node ? $page
		: 'XXX';
}

sub TRACE {}
sub DUMP  {}
