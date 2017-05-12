package TestServerState;
use strict;
use warnings;

use parent 'OAuth::Lite2::Model::ServerState';

__PACKAGE__->mk_ro_accessors(qw(extra));

sub new {
    my ($class, %params) = @_;
    my $extra = delete $params{extra};
    my $self = $class->SUPER::new(%params);
    $self->{extra} = $extra;
    return $self;
}

1;
