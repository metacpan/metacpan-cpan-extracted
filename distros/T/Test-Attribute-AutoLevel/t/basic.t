use strict;
use warnings;
use Test::More;
use App::Prove;
use Capture::Tiny 'capture';

my (undef, $stderr, undef) = capture {
    my $prove = App::Prove->new;
    $prove->process_args("-lvc","./t/internal_test");
    $prove->run;
};

my @lines = grep { $_ } map { $_ =~ /^#   at/ ? $_ : undef } split /\n/, $stderr;

is_deeply \@lines, [
    '#   at ./t/internal_test line 19.',
    '#   at ./t/internal_test line 20.',
    '#   at ./t/internal_test line 20.',
];

done_testing;

