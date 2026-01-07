#!perl -T

# Testing should be friendly and nice looking, not dull ugly text.

use strict;
use warnings FATAL => 'all';

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use List::Util qw(max);
use utf8;

use Test::More tests => 2087;
# use Test::More 'no_plan';

BEGIN {
    use_ok('Term::ANSIEncode') || BAIL_OUT('Cannot load Term::ANSIEncode!');
}

# utf8 must be enabled
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

# ╔ ╗ ╚ ╝ ═ ║
diag("\n\r" . colored(['bright_yellow'], "\e[4m                                    "));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{ _______        _   _              }) . colored(['yellow'], '◣'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{|__   __|      | | (_)             }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   | | ___  ___| |_ _ _ __   __ _  }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   | |/ _ \/ __| __| | '_ \ / _` | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   | |  __/\__ \ |_| | | | | (_| | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   |_|\___||___/\__|_|_| |_|\__, | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{                             __/ | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['white on_black'], q{Term::ANSIEncode}) . colored(['cyan on_black'],q{            |___/  }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏                                   ') . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'],        '◥████████████████████████████████████'));
diag("\r  \n\r  " x 12 . "\e[13A");
diag("\r  \n\r" . colored(['bright_yellow on_magenta'],sprintf('%-25s',' Testing object creation ')));
my $ansi = Term::ANSIEncode->new();
isa_ok($ansi,'Term::ANSIEncode');
diag("\e[1A\r" . colored(['bright_yellow on_magenta'],sprintf('%-25s',' Tested object creation ')) . colored(['bright_green'], ' OK'));

my $max = 1;
diag("\r" . colored(['bright_yellow on_blue'],sprintf('%-25s',' Testing tokens ')) . colored(['yellow'],' ...'));
foreach my $code (keys %{$ansi->{'ansi_meta'}}) {
    foreach my $t (keys %{$ansi->{'ansi_meta'}->{$code}}) {
        $max = max(length($t),$max);
    }
}
$max += 6;
my @colors = ('red','yellow','green','cyan','magenta','bright_blue');
foreach my $code (sort(keys %{$ansi->{'ansi_meta'}})) {
	my $color = shift(@colors);
    foreach my $token (sort(keys %{$ansi->{'ansi_meta'}->{$code}})) {
        next if ($token =~ /NEWLINE|LINEFEED|RETURN|HORIZONTAL/);
        my $text   = '[% ' . $token . ' %]';
		diag("\r" . clline . '     ' . 
			colored(['white'], 'Testing') .
			colored([$color], ' ' . uc($code) . ' ') .
			colored(['white'], 'tokens -> ') .
			colored(['bright_yellow'], $text) . clline . "\r\e[1A"
		);
        my $output = $ansi->ansi_decode($text);

        $output =~ s/\e/\\e/gs;
        $output =~ s/\r/\\r/gs;

        my $test = $ansi->{'ansi_meta'}->{$code}->{$token}->{'out'};

        $test =~ s/\e/\\e/gs;
        $test =~ s/\[\% RETURN \%\]/\\r/gs;

        cmp_ok($output,'eq',"$test","$text");
    }
	diag("\r" . clline . '     ' .
		colored(['white'], 'Tested ') .
		sprintf('%-22s %s',colored([$color], ' ' . uc($code) . ' '), colored(['bright_green'],'OK')) .
		clline
	);

}
diag(' ' x 79 . "\r\e[7A" . colored(['bright_yellow on_blue'],sprintf('%-25s',' Tested tokens ')) . colored(['bright_green'],' OK ') . "\n\r " x 7);

exit(0);

__END__

