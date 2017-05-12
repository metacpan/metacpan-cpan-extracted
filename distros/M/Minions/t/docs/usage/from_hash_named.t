use strict;
use Test::Most tests => 4;
use Minions ();

my %Class = (
    name => 'Counter',
    interface => [qw( next )],
    implementation => {
        methods => {
            next => sub {
                my ($self) = @_;

                $self->{-count}++;
            }
        },
        has  => {
            count => { default => 0 },
        }, 
    },
);

Minions->minionize(\%Class);
my $counter = Counter->new;

is $counter->next => 0;
is $counter->next => 1;

throws_ok { $counter->new } qr/Can't locate object method "new"/;
throws_ok { Counter->next } qr/Can't locate object method "next" via package "Counter"/;
