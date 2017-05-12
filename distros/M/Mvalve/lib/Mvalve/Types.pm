package Mvalve::Types;
use Moose;
use Moose::Util::TypeConstraints;

role_type 'Mvalve::Queue';
role_type 'Mvalve::State';
role_type 'Mvalve::Throttler';
role_type 'Mvalve::Logger';

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
        $module->new(%{$h->{args}});
    };
};

*__coerce_throttler = $coerce->('Data::Valve', 'Mvalve::Throttler');
*__coerce_queue     = $coerce->('Q4M', 'Mvalve::Queue');
*__coerce_state     = $coerce->('Memory', 'Mvalve::State');
*__coerce_logger    = $coerce->('Stats', 'Mvalve::Logger');

coerce 'Mvalve::Throttler'
    => from 'HashRef'
    => \&__coerce_throttler
;

coerce 'Mvalve::Queue'
    => from 'HashRef'
    => \&__coerce_queue
;

coerce 'Mvalve::State'
    => from 'HashRef'
    => \&__coerce_state
;

coerce 'Mvalve::Logger'
    => from 'HashRef'
    => \&__coerce_logger
;

no Moose;

1;

__END__

=head1 NAME

Mvalve::Types - Mvalve Related Moose Types

=head1 SYNOPSIS

  package MyMvalveModule;
  use Moose;
  use Mvalve::Types;

  has 'foo' => (
    is => 'rw',
    isa => 'Mvalve::Queue'
  );

=cut
