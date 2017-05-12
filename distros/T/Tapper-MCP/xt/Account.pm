package # hide from PAUSE indexer
 Account;

use 5.010;

sub new {
        my $class = shift;
        my @args = @_;

        my $self = { @args };
        bless $self, $class
}

sub name { return shift->{name} }

1;
