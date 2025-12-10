#!perl -T

use strict;
use warnings FATAL => 'all';

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use List::Util qw(max);
use utf8;

use Test::More tests => 2087;

BEGIN {
    use_ok('Term::ANSIEncode') || BAIL_OUT('Cannot load Term::ANSIEncode!');
}

diag("\n" . colored(['cyan on_black'], q{ _______        _   _              }));
diag(colored(['cyan on_black'], q{|__   __|      | | (_)             }));
diag(colored(['cyan on_black'], q{   | | ___  ___| |_ _ _ __   __ _  }));
diag(colored(['cyan on_black'], q{   | |/ _ \/ __| __| | '_ \ / _` | }));
diag(colored(['cyan on_black'], q{   | |  __/\__ \ |_| | | | | (_| | }));
diag(colored(['cyan on_black'], q{   |_|\___||___/\__|_|_| |_|\__, | }));
diag(colored(['cyan on_black'], q{                             __/ | }));
diag(colored(['cyan on_black'], q{                            |___/  }));

# utf8 must be enabled
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

diag("\n" . colored(['black on_magenta'],sprintf('%-28s',' Testing object creation ')));
my $ansi = Term::ANSIEncode->new();
isa_ok($ansi,'Term::ANSIEncode');

my $max = 1;
diag(colored(['black on_green'],sprintf('%-28s',' Testing tokens ')));
foreach my $code (keys %{$ansi->{'ansi_meta'}}) {
    foreach my $t (keys %{$ansi->{'ansi_meta'}->{$code}}) {
        $max = max(length($t),$max);
    }
}
$max += 6;
foreach my $code (keys %{$ansi->{'ansi_meta'}}) {
    foreach my $token (sort(keys %{$ansi->{'ansi_meta'}->{$code}})) {
        next if ($token =~ /NEWLINE|LINEFEED|RETURN|HORIZONTAL/);
#        diag(colored(['white'],"Testing $code -> $token"));
        my $text   = '[% ' . $token . ' %]';
        my $output = $ansi->ansi_decode($text);

        $output =~ s/\e/\\e/gs;
        $output =~ s/\r/\\r/gs;

        my $test = $ansi->{'ansi_meta'}->{$code}->{$token}->{'out'};

        $test =~ s/\e/\\e/gs;
        $test =~ s/\[\% RETURN \%\]/\\r/gs;

        cmp_ok($output,'eq',"$test","$text");
    }
}

exit(0);

__END__

