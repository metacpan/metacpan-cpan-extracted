package Tags::HTML::Element::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

Readonly::Array our @EXPORT_OK => qw(tags_boolean tags_value);

our $VERSION = 0.02;

sub tags_boolean {
	my ($self, $textarea, $method) = @_;

	if ($textarea->$method) {
		return (['a', $method, $method]);
	}

	return ();
}

sub tags_value {
	my ($self, $textarea, $method, $method_rewrite) = @_;

	if (defined $textarea->$method) {
		return ([
			'a',
			defined $method_rewrite ? $method_rewrite : $method,
			$textarea->$method,
		]);
	}

	return ();
}

1;

__END__
