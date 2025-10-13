#!perl -T

use strict;
use warnings FATAL => 'all';

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use Time::HiRes qw( sleep );
use List::Util qw(max);
use utf8;

use Test::More qw(no_plan);

BEGIN {
	use_ok('Term::ANSIEncode') || BAIL_OUT('Cannot load Term::ANSIEncode!');
}

# utf8 must be enabled
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

diag(colored(['black on_magenta'],sprintf('%-28s',' Testing object creation ')));
my $ansi = Term::ANSIEncode->new();
isa_ok($ansi,'Term::ANSIEncode');

my $max = 1;
diag(colored(['black on_green'],sprintf('%-28s',' Testing tokens ')));
foreach my $t (keys %{$ansi->{'ansi_sequences'}}) {
	$max = max(length($t),$max);
}
$max += 6;
foreach my $token (sort(keys %{$ansi->{'ansi_sequences'}})) {
	next if ($token =~ /NEWLINE|LINEFEED|RETURN|HORIZONTAL/);
	my $text   = '[% ' . $token . ' %]';
    my $output = $ansi->ansi_decode($text);

	$output =~ s/\e/\\e/gs;
    $output =~ s/\r/\\r/gs;

	my $test = $ansi->{'ansi_sequences'}->{$token};

    $test =~ s/\e/\\e/gs;
    $test =~ s/\[\% RETURN \%\]/\\r/gs;

	cmp_ok($output,'eq',"$test","$text");
}

exit(0);

__END__

