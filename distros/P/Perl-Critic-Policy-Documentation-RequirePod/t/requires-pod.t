
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Test::More;

my @ok = (
    q{
print 'Hello World';
=pod
=head1 NAME
Hello World
=cut
    },
    q{
=pod
=head1 NAME
Hello World
=cut
print 'Hello World';
    },
    q{
print 'Hello World';
=pod
=head1 NAME
Hello World
=cut
print 'Goodbye World';
    },
);

my @not_ok = (
    q{ print 'Hello World'; },
);

plan tests => @ok + @not_ok;

my $policy = 'Documentation::RequirePod';

for my $test (@ok) {
    my $violation_count = pcritique($policy, \$test);
    is($violation_count, 0, "nothing wrong with C< $test >");
}

for my $test (@not_ok) {
    my $violation_count = pcritique($policy, \$test);
    is($violation_count, 1, "C< $test > is no good");
}
