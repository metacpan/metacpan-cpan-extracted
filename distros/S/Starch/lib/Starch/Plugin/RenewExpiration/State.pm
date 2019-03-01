package Starch::Plugin::RenewExpiration::State;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

around save => sub{
    my $orig = shift;
    my $self = shift;

    my $manager = $self->manager();
    my $thresh = $manager->renew_threshold();

    my $variance = $manager->renew_variance();
    if ($variance > 0) {
        my $delta = int($thresh * $variance);
        $thresh = ($thresh - $delta) + int( rand($delta+1) );
    }

    $self->mark_dirty() if $self->modified() + $thresh <= time();

    return $self->$orig( @_ );
};

1;
