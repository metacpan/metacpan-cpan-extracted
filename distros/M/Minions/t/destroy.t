use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package ProcessImpl;

    our %__meta__ = (
        role => 1,
        has => { id => { reader => 1 } }
    );
    
    our $Count = 0;

    sub BUILD {
        my (undef, $self) = @_;

        $self->{-id} = ++$Count;
    }
    
    sub DESTROY {
        my ($self) = @_;
        --$Count;
    }
}

{
    package Process;

    our %__meta__ = (
        interface => [qw( id )],
        implementation => 'ProcessImpl',
    );
    Minions->minionize;
}

package main;

for ( 1 .. 3 ) {
    my $proc = Process->new();
    is($proc->id, 1);
}
is($ProcessImpl::Count, 0, 'All objects destroyed');

done_testing();
