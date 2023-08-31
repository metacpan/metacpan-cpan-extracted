#!/usr/bin/env perl
use Test::More;
use Term::Tmux::StatusBar;

my ($fg, $bg, $text) = parse(':', 'black:#ffb86c:#[bold]#I #W#{?window_marked_flag,,}');
ok( $fg eq 'black', 'fg' );
ok( $bg eq '#ffb86c', 'bg' );
ok( $text eq '#[bold]#I #W#{?window_marked_flag,,}', 'text' );
$text = status_left("#fffafa,black,#S");
ok($text eq '#[fg=#fffafa,bg=black] #S #[fg=black,bg=default]', 'status_left');
my @results = parse(';', 'white,colour04,#{prefix_highlight};black,yellow,#{pomodoro_status};black,#9370db,#{?#{==:#{bitahub_status_rtx3090},},,3090 #{bitahub_status_rtx3090}};black,#87ceeb,%F');
ok(scalar(@results) == 4, 'sections');

done_testing();
