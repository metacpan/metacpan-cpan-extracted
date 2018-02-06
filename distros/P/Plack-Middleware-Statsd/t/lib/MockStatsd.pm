package MockStatsd;

use strict;
use warnings;

use Sub::Util 1.40 qw/ set_subname /;

sub new {
    my $class = shift;
    my $self  = [];
    bless $self, $class;
}

foreach my $name (qw/ increment decrement update timing_ms set_add gauge /) {
    no strict 'refs';
    my $class = __PACKAGE__;
    *{"${class}::${name}"} = set_subname $name => sub {
        my $self = shift;
        die "Error" if $_[0] && $_[0] =~ 'POST';
        push @{$self}, [ $name, @_ ];
    };
}

sub reset {
    my $self = shift;
    ( splice @{$self}, 0 );
}

1;
