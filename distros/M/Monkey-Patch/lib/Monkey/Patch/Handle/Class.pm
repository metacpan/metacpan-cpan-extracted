package Monkey::Patch::Handle::Class;
BEGIN {
  $Monkey::Patch::Handle::Class::VERSION = '0.03';
}
use strict;
use warnings;

use base 'Monkey::Patch::Handle';
use SUPER;

sub call_default {
    my $self  = shift;
    my $class = $self->{package};
    my ($super) = SUPER::find_parent($class, $self->{subname});
    goto &$super if $super;
    return;
}

1;

=pod

=begin Pod::Coverage

.*

=end Pod::Coverage
