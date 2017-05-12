use strict;
use Test::Most tests => 4;
use Minions ();

my %Class = (
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

my $counter = Minions->minionize(\%Class)->new;

is $counter->next => 0;
is $counter->next => 1;
is $counter->next => 2;

throws_ok { $counter->new } qr/Can't locate object method "new"/;
