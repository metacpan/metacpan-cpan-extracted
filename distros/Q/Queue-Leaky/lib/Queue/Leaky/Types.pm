package Queue::Leaky::Types;

use Moose;
use Moose::Util::TypeConstraints;

role_type 'Queue::Leaky::Driver';
role_type 'Queue::Leaky::State';

my $coerce = sub {
    my $default_class = shift;
    my $prefix = shift;
    return sub {
        my $h = shift;
        my $module = delete $h->{module} || $default_class;
        if ($prefix && $module !~ s/^\+//) {
            $module = join('::', $prefix, $module);
        }
        Class::MOP::load_class($module);
        $module->new(%$h);
    };
};

coerce 'Queue::Leaky::Driver'
    => from 'HashRef'
    => $coerce->('Simple', 'Queue::Leaky::Driver')
;

coerce 'Queue::Leaky::State'
    => from 'HashRef'
    => $coerce->('Memory', 'Queue::Leaky::State');
;

no Moose;

1;
