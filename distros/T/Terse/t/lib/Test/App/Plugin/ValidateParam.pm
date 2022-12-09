package Test::App::Plugin::ValidateParam;

use base 'Terse::Plugin';

sub az {
	my ($self, $param) = @_;
	return 0 if ref $param;
	return $param =~ m/^[a-z]+$/i;
}

1;
