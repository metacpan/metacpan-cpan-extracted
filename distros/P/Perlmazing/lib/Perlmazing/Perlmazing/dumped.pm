use Perlmazing;
use Data::Dump qw();

sub main {
	return unless @_;
	Data::Dump::dump(@_);
}

1;