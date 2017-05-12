
use strict;

sub handler {
	my $q = shift;
	my $url = $q->url(full => 1);

	my $login = $q->param('login');
	if (defined $login) {
		print qq!Set-Cookie: activesession="user $login"; Path=/\n!;
		print qq!Location: $url?welcome=1\n!;
		print "\n";
		return 303;
	}

	my $session = $q->cookie('activesession');
	if (not $session) {
		my $logged_out = $q->param('logged_out');
		if ($logged_out) {
			return {
				session => "logged out $logged_out",
			};
		}
		return {
			session => 'no session',
		};
	}

	if (not $session =~ /^"user (\d+)"$/) {
		die "cookie [activesession] has invalid value [$session]\n";
	}

	my $user = $1;
	if ($q->param('logout')) {
		print qq!Set-Cookie: activesession="user $user"; Path=/; Max-Age=0\n!;
		print qq!Location: $url?logged_out=$user\n!;
		print "\n";
		return 303;
	}

	if ($q->param('welcome')) {
		return {
			login => $user,
			session => "logged in $user",
		};
	}

	return {
		login => $login,
		session => "running $user",
	};
}

1;

