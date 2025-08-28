#!perl -T

use strict;
use warnings FATAL => 'all';

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use Time::HiRes qw( sleep );
use List::Util qw(max);
use utf8;

use Test::More tests => 1124;

BEGIN {
	use_ok('Term::ANSIEncode') || BAIL_OUT('Cannot load Term::ANSIEncode!');
}

# utf8 must be enabled
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

diag(colored(['black on_magenta'],sprintf('%-28s',' Testing object creation ')));
my $ansi = Term::ANSIEncode->new('mode' => 'small');
isa_ok($ansi,'Term::ANSIEncode');

my $max = 1;
diag(colored(['black on_green'],sprintf('%-28s',' Testing tokens ')));
foreach my $t (keys %{$ansi->{'ansi_sequences'}}) {
	$max = max(length($t),$max);
}
$max += 6;
foreach my $token (sort(keys %{$ansi->{'ansi_sequences'}})) {
	next if ($token =~ /NEWLINE|LINEFEED|RETURN/);
	my $text   = '[% ' . $token . ' %]';
    my $output = $ansi->ansi_output($text,0,1);

	$output =~ s/\e/\\e/gs;
    $output =~ s/\r/\\r/gs;

	my $test = $ansi->{'ansi_sequences'}->{$token};

    $test =~ s/\e/\\e/gs;
    $test =~ s/\[\% RETURN \%\]/\\r/gs;

	note(sprintf('%-' . $max . 's (GOT)-> %-28s (EXPECTED)-> %-28s',$text ,$output, $test));
	cmp_ok($output,'eq',$test,$text) || BAIL_OUT($text);
}

diag(colored(['black on_bright_yellow'],sprintf('%-28s',' Testing special characters ')) . " It's okay if some of these fail ");
$max = 1;
foreach my $c (keys %{$ansi->{'characters'}->{'NAME'}}) {
	$max = max(length($c),$max);
}
$max += 6;
foreach my $character (sort(keys %{$ansi->{'characters'}->{'NAME'}})) {
    my $text   = '[% ' . $character . ' %]';
    my $output = $ansi->ansi_output($text,0,1);
    my $test   = $ansi->{'characters'}->{'NAME'}->{$character};

    note(sprintf('%-' . $max . 's (GOT)-> %-4s    (EXPECTED)-> %-4s',$text , $output, $test));
	SKIP: {
		skip "$text Not available on this terminal", 1 if ($output ne $test);
		cmp_ok($output,'eq',$test,$text) || diag($text);
	}
}

exit(0);

__END__

