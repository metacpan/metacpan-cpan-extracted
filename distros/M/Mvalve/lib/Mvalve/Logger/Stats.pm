# $Id$

package Mvalve::Logger::Stats;
use Moose;

with 'MooseX::Q4MLog';
with 'Mvalve::Logger';

around 'new' => sub {
    my ($next, $class, %args) = @_;

    $args{q4mlog}->{table} ||= 'q_statslog';
    $next->($class, %args);
};

no Moose;

sub format_q4mlog { 
    my ($self, %args) = @_;
    $args{logged_on} = \'CURRENT_TIMESTAMP';
    return \%args;
}

1;