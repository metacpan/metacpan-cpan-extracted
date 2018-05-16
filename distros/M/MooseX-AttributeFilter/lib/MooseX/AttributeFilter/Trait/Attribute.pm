package MooseX::AttributeFilter::Trait::Attribute;
use 5.008009;
use strict;
use warnings;

our $VERSION = "0.06";

use Moose::Role;

has filter => (
    is  => 'ro',
    isa => 'CodeRef|Str',
    predicate => 'has_filter',
);

after _process_options => sub {
    my $this = shift;
    my ($name, $options) = @_;
    
    return unless defined $options->{filter};
    
    if ($options->{filter} eq '1') {
        $options->{filter} = "_filter_${name}";
    }    
};

before install_accessors => sub {
    my $this = shift;
    my $filter = $this->filter;
    if (defined $filter and not ref $filter) {
        my $class  = $this->associated_class;
        my $method = $class->find_method_by_name($filter);
        
        die sprintf(
            "No filter method '%s' defined for %s attribute '%s'",
            $filter,
            $class->name,
            $this->name,
            ) if !$method;
    }
};

around _coerce_and_verify => sub {
    my $next = shift;
    my $this = shift;
    my ($value, $instance) = @_;
    my $filter = $this->filter;
    if ($filter) {
        
        # Need to figure out if we're being called by non-immutable
        # constructor. This is ugly, but searching the call stack works.
        my $in_ctor = 0;
        for my $level (0 .. 8) {  # should be enough
            my (undef, undef, undef, $sub) = caller($level);
            if ($sub eq 'Moose::Meta::Attribute::initialize_instance_slot') {
                $in_ctor = 1;
                last;
            }
        }
        
        $value = $instance->$filter($value, $in_ctor ? () : $this->get_value($instance));
    }
    $this->$next($value, $instance);
};

has _filter_ix => (
    is  => 'rw',
    isa => 'Int',
);

sub _inline_filter {
    my $this = shift;
    my ($instance, $value, $filtered, $for_constructor) = @_;
    
    my @code;
    my $filter = $this->filter;
    if (ref $filter) {
        if (not defined $this->_filter_ix) {
            # going via metaobject would be smarter
            # but this is faster. xD
            push(our @FILTERS, $filter);
            $this->_filter_ix($#FILTERS);
        }
        push @code, sprintf(
            'my $filter = $%s::FILTERS[%d];',
            __PACKAGE__,
            $this->_filter_ix,
        );
        push @code, sprintf(
            $for_constructor
                ? 'my %s = %s->%s(%s);'
                : 'my %s = %s->%s(%s, %s);',
            $filtered,
            $instance,
            '$filter',
            $value,
            $for_constructor
                ? ()
                : $this->_inline_instance_get($instance),
        ),
    }
    elsif (defined $filter) {
        push @code, sprintf(
            $for_constructor
                ? 'my %s = %s->%s(%s);'
                : 'my %s = %s->%s(%s, %s);',
            $filtered,
            $instance,
            $filter,
            $value,
            $for_constructor
                ? ()
                : $this->_inline_instance_get($instance),
        ),
    }
    
    return @code;
}

around _inline_set_value => sub {
    my $next = shift;
    my $this = shift;
    my ($instance, $value, $tc, $coercion, $message, $for_constructor) = @_;    
    return $this->$next(@_) unless $this->has_filter;
    my @code = (
        $this->_inline_filter($instance, $value, '$filtered', $for_constructor),
        $this->$next($instance, '$filtered', $tc, $coercion, $message, $for_constructor),
    );
    #use Data::Dumper;
    #warn Dumper \@code;
    return @code;
};

around _inline_init_from_default => sub {
    my $next = shift;
    my $this = shift;
    my ($instance, $default, $tc, $coercion, $message, $for_lazy) = @_;
    my $filtered = '$filtered';
    return $this->$next(@_) unless $this->has_filter;
    
    my @code = (
        $this->_inline_generate_default($instance, $default),
        $this->_inline_filter($instance, $default, $filtered, $for_lazy),
        $this->has_type_constraint
            ? ($this->_inline_check_coercion($filtered, $tc, $coercion, $for_lazy),
               $this->_inline_check_constraint($filtered, $tc, $message, $for_lazy))
            : (),
        $this->_inline_init_slot($instance, $filtered),
        $this->_inline_weaken_value($instance, $filtered),
    );
    #use Data::Dumper;
    #warn Dumper \@code;
    return @code;
};

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::AttributeFilter::Trait::Attribute - trait for filtered attributes

=head1 SYNOPSIS

    package My::Class;
    use Moose;
    use MooseX::AttributeFilter;
    
    has field => (
        is     => 'rw',
        filter => 'filterField',
    );
    
    sub filterField {
        my $this = shift;
        return "filtered($_[0])";
    }
    
    package main;
    My::Class->meta->get_attribute("field")->has_filter;  # true

=head1 DESCRIPTION

MooseX::AttributeFilter::Trait::Attribute is a trait for L<Moose::Meta::Attribute>.
L<MooseX::AttributeFilter> automatically applies it to all attributes, but it
acts as no-op if attribute does not use C<filter> option.

=head2 Methods

=over

=item C<filter>

Returns the value of the C<filter> option. This may be a string (method name)
or coderef or undef.

=item C<has_filter>

Boolean.

=back

=head1 SEE ALSO

L<MooseX::AttributeFilter>.

=head1 LICENSE

Copyright (C) 2018 Little Princess Kitten <kitten@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KITTEN <kitten@cpan.org>

L<https://metacpan.org/author/KITTEN>

L<https://github.com/icklekitten>

<3

=cut

