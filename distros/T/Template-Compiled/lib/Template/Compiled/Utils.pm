use 5.008;
use strict;
use warnings;

package Template::Compiled::Utils;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Exporter::Shiny our @EXPORT = qw(
	echo
	echof
);

sub echo {
	my $outref = do {
		my $caller = caller;
		no strict 'refs';
		${"$caller\::_OUT_REF"};
	};
	$$outref .= $_ for @_;
}

sub echof {
	my $fmt = shift;
	@_ = sprintf $fmt, @_;
	goto \&echo;
}

1;
