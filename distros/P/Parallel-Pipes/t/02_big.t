use strict;
use warnings;
use Parallel::Pipes;
use Test::More;

my $num = $^O eq 'MSWin32' ? 1 : 4;

my $pipes = Parallel::Pipes->new($num, sub {
    my $data = shift;
    return $data . " " . ("x" x ($data*10*1024));
});

my @back;
for my $i (1..9) {
    my @ready = $pipes->is_ready;
    for my $ready (grep $_->is_written, @ready) {
        push @back, $ready->read;
    }
    $ready[0]->write($i);
}
while (my @written = $pipes->is_written) {
    push @back, $_->read for @written;
}

@back = sort @back;

is_deeply \@back, [ map { $_ . " " . ("x" x ($_*10*1024)) } 1..9 ];

done_testing;
