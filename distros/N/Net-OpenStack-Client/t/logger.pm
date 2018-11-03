package logger;

use strict;
use warnings;
use Test::More;

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {}; # here, it gives a reference on a hash
    bless $self, $class;

    return $self;
};

no strict 'refs';
foreach my $i (qw(error warn info debug verbose)) {
    *{$i} = sub {
        my ($self, @args) = @_;
        diag "[".uc($i)."] ", map {ref($_) ? explain($_) : $_} @args;
    }
}
use strict 'refs';


1;
