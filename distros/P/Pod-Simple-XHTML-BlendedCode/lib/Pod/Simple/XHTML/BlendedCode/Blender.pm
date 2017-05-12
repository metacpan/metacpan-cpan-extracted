package Pod::Simple::XHTML::BlendedCode::Blender;

# This module blends the code into the pod in such a way that
# Pod::Simple::XHTML::Blended can use it.
# Think of it as a "pod+code->pod" parser.

use 5.008001;
use warnings;
use strict;
use parent 0.223 qw(Pod::Parser);
use PPI::HTML 1.08 qw();

our $VERSION = '1.000';
$VERSION =~ s/_//ms;

sub initialize {
	my $self = shift;
	$self->{highlighter} = PPI::HTML->new();
	return $self->SUPER::initialize();
}

sub preprocess_paragraph {
	my ( $self, $text, $line_number ) = @_;

	my $html;

	if ( $self->cutting() ) {
		$html = $self->{highlighter}->html( \$text );
		$html =~ s{<br>}{}msg;
		$html =~ s{\n\n}{\n}msg;
		$html =~ s{\t}{&nbsp;&nbsp;&nbsp;&nbsp;}msg;
		print { $self->output_handle() }
		  "=begin html\n\n<pre>\n$html</pre>\n\n=end html\n\n";
		return q{};
	} else {
		return $text;
	}
} ## end sub preprocess_paragraph

sub command {
	my ( $self, $command, $text, $line_number, $pod_paragraph ) = @_;

	print { $self->output_handle() } $pod_paragraph->raw_text();
	return;
}

1;                                     # Magic true value required at end of module

__END__
