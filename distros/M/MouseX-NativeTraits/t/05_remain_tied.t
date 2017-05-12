#!perl -w
# https://rt.cpan.org/Ticket/Display.html?id=69039

package HashTest;

use Mouse;
use Tie::Hash;
use Test::More;

my @triggered;
has values => (
    is  => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    default  => sub { tie my %e, 'Tie::StdHash'; \%e },
    handles  => {
        set_value => 'set',
    },
    trigger => sub {
        my($self) = @_;
        push @triggered, $self;
    },
);

my $test = __PACKAGE__->new;

isa_ok tied(%{$test->values}), 'Tie::StdHash', 'HashRef is still tied after set directly';

$test->set_value('b' => 'b');

isa_ok tied(%{$test->values}), 'Tie::StdHash', 'HashRef is still tied after set via NativeTraits';

is_deeply \@triggered, [$test];

done_testing;

