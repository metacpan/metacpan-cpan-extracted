package Serengeti::NotificationCenter;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed refaddr);

{
    my $DefaultCenter;
    sub default_center {
        return $DefaultCenter if $DefaultCenter;
        
        my $pkg = shift || __PACKAGE__;
        $DefaultCenter = $pkg->new;
        
        return $DefaultCenter;
    }
}

sub new {
    my ($pkg) = @_;
    
    return bless [], $pkg;
}

sub add_observer {
    my ($self, $target, %args) = @_;
    
    # Default to default_center
    $self = default_center unless blessed $self;
    
    croak "Missing 'selector' argument" unless $args{selector};
    
    my $for = $args{for};
    if ($for && !(ref $for eq "CODE" || ref $for eq "")) {
        croak "Invalid argument 'for'. Must be scalar or code reference";
    }
    
    my $from = refaddr $args{sender} || 0;
    my $selector = $args{selector};
    
    push @$self, [$target, $selector, $for, $from];
    
    1;
}

sub post_notification {
    my ($self, $sender, $notification, $data, $target) = @_;
    
    # Default to default_center
    $self = default_center unless blessed $self;
    
    for my $observation (@$self) {
        my ($observer, $selector, $for, $from) = @$observation;
        next if $for && $for ne $notification;
        next if $from && $from != refaddr $sender;
        next if $target && $target != refaddr $observer;
        
        eval {
            $observer->$selector($sender, $notification, $data);
        };
        
        warn "$@" if $@;
    }
}

sub remove_observer {
    my ($self, $target) = @_;
    
    # Default to default_center
    $self = default_center unless blessed $self;

    @$self = grep { defined $_->[0] && refaddr $_->[0] != refaddr $target } @$self;
    
    1;
}

1;
