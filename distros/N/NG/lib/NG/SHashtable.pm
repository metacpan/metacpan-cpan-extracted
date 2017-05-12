package SHashtable;

use strict;
use warnings;
use base qw(Hashtable);

sub new {
    my $pkg  = shift;
    my $hash = {@_};
    return bless $hash, $pkg;
}

sub each {
    my ( $self, $sub ) = @_;
    $self->keys->sort(
        sub {
            my ( $a, $b ) = @_;
            return $a cmp $b;
        }
      )->each(
        sub {
            my ($key) = @_;
            $sub->( $key, $self->get($key) );
        }
      );
    return $self;
}

1;
