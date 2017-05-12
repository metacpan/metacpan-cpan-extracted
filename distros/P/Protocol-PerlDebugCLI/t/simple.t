use strict;
use warnings;

use Test::More;
use Protocol::PerlDebugCLI;

my $deb = new_ok('Protocol::PerlDebugCLI');

my $txt = <<'EOF';
Loading DB routines from perl5db.pl version 1.33
Editor support available.

Enter h or `h h' for help, or `man perldebug' for more help.

main::(testscript.pl:7):                my %seen;
main::(testscript.pl:8):                sub mark_as_seen {
  DB<1> 
EOF
chomp($txt);

$deb->add_handler_for_event(
	write => sub {
		my ($self, $data) = @_;
		note "Want to write $data";
	},
	current_position => sub {
		my ($self, %args) = @_;
		is($args{function}, 'main::', 'detected correct function at start');
		is($args{file}, 'testscript.pl', 'detected correct file at start');
		is($args{line}, '7', 'detected correct line number at start');
		0;
	}
);
$deb->on_read(\$txt, 0);
is($deb->request_current_line, $deb, 'returns $self for current_line request');

done_testing();
