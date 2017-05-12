package Spica::Filter;
use strict;
use warnings;
use parent qw/Exporter/;
use Scalar::Util ();
use if $] >= 5.009_005, 'mro';
use if $] < 5.009_005, 'MRO::Compat';

our @EXPORT = qw/add_filter call_filter get_filter_code/;

sub add_filter {
    my ($class, %args) = @_;

    if (ref $class) {
        while (my ($hook, $code) = each %args) {
            push @{$class->{_filter}->{$hook}}, $code;
        }
    } else {
        no strict 'refs';
        while (my ($hook, $code) = each %args) {
            push @{${"${class}::_filter"}->{$hook}}, $code;
        }
    }
}

sub call_filter {
    my ($class, $hook, @args) = @_;
    my @code = $class->get_filter_code($hook);
    for my $code (@code) {
        $code->($class, @args);
    }
}

sub get_filter_code {
    my ($class, $hook) = @_;
    my @code;
    if (Scalar::Util::blessed($class)) {
        push @code, @{ $class->{_filter}->{$hook} || [] };
        $class = ref $class;
    }
    no strict 'refs';
    my $klass = ref $class || $class;
    for (@{mro::get_linear_isa($class)}) {
        push @code, @{${"${_}::_filter"}->{$hook} || []};
    }
    return @code;
}

1;
__END__
copied from Amon2::Trigger!! thanks tokuhirom!!!
