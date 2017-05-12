use 5.014;

package P1;
use Mojo::Base -base;

sub DESTROY {
    warn __PACKAGE__ . '::DESTROY';
}

package P2;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub DESTROY {
    warn __PACKAGE__ . '::DESTROY';
}

package main;

{ my $p1 = P1->new; }
say 'P1 iz ded';

{ my $p2 = P2->new; }
say 'P2 iz ded';
__END__
