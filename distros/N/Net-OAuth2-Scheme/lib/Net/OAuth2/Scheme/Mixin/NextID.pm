use warnings;
use strict;

package Net::OAuth2::Scheme::Mixin::NextID;
BEGIN {
  $Net::OAuth2::Scheme::Mixin::NextID::VERSION = '0.03';
}
# ABSTRACT: the 'v_id_next', 'counter', and 'random' option groups

use Net::OAuth2::Scheme::Option::Defines;
use Net::OAuth2::Scheme::Random;
use Net::OAuth2::Scheme::Counter;

# INTERFACE v_id
# DEFINES
#   v_id_next
#   v_id_is_random
#   v_id_get_suffix

Define_Group v_id => 'default',
  qw(v_id_next v_id_is_random v_id_get_suffix);

Default_Value v_id_random_length => 12;
Default_Value v_id_suffix => '';

sub pkg_v_id_default {
    my __PACKAGE__ $self = shift;
    my $which = $self->uses('v_id_suggest', 'counter');
    my $pkg = "pkg_v_id_${which}";
    return $self->$pkg(@_);
}

# IMPLEMENTATION v_id_random FOR v_id
# REQUIRES
#   random
# OPTIONS
#   v_id_random_length
#   v_id_suffix

sub pkg_v_id_random {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(qw(v_id_ _default random_length) => @_);
    $self->make_alias(qw(v_id_random_length v_id_length));
    if ($self->is_auth_server) {
        my $random = $self->uses('random');
        my $length = $self->uses('v_id_random_length');
        my $suffix = $self->uses('v_id_suffix');

        $self->croak("v_id_length must be at least 8")
          unless $length >= 8;
        $self->install(v_id_is_random => 1);
        my $l = pack 'w', $length+56;
        $l = ((ord($l)&0xc0)==0xc0 ? chr(0x00).$l :
              (ord($l)&0xc0)==0x80 ? chr(0x80)^$l :
              $l);
        $self->install(v_id_next => sub {
            return $l . $random->($length) . $suffix;
        });
    }
    if ($self->is_resource_server) {
        $self->install(v_id_get_suffix => sub {
            my $v = shift;
            my ($l,$rest) = unpack 'wa*', (ord($v)&0x40)==0 ? chr(0x80)^$v : $v;
            return substr($rest,$l-56);
        });
    }
    return $self;
}

# IMPLEMENTATION v_id_counter FOR v_id
# REQUIRES
#   counter
# OPTIONS
#   v_id_counter_tag
#   v_id_suffix

sub pkg_v_id_counter {
    my __PACKAGE__ $self = shift;
    $self->parameter_prefix(qw(v_id_ _default counter_tag) => @_);
    $self->make_alias(v_id_counter_tag => 'counter_tag');
    if ($self->is_resource_server) {
        $self->install(v_id_get_suffix => $self->uses('counter_get_suffix'));
    }
    if ($self->is_auth_server) {
        my $counter = $self->uses('counter');
        my $suffix = $self->uses('v_id_suffix');
        $self->install(v_id_is_random => 0);
        $self->install(v_id_next => sub {
            return $counter->next() . $suffix;
        });
    }
    return $self;
}


# INTERFACE counter
# SUMMARY
#   generate a sequence of bytes different from every previous sequence produced
#   and from every other possible sequence that can be produced from this same code
#   running in any other process or thread.
# DEFINES
#   counter  object with a 'next' method () -> string of bytes

Define_Group counter_set => 'default', qw(counter counter_get_suffix);

Default_Value counter_tag => '';

sub pkg_counter_set_default {
    my __PACKAGE__ $self = shift;    
    if ($self->is_auth_server) {
        my $tag = $self->uses('counter_tag');
        $self->install('counter', Net::OAuth2::Scheme::Counter->new($tag));
    }
    if ($self->is_resource_server) {
        $self->install('counter_get_suffix', \&Net::OAuth2::Scheme::Counter::suffix);
    }
    return $self;
}


# INTERFACE random
# SUMMARY
#   generate random bytes in a cryptographically secure mannter
# DEFINES
#   random  (n)-> string of n random octets

# default implementation
Default_Value  random_class => 'Math::Random::MT::Auto';

Define_Group  random_set => 'default', qw(random);

sub pkg_random_set_default {
    require Net::OAuth2::Scheme::Random;
    my __PACKAGE__ $self = shift;
    my $rng = Net::OAuth2::Scheme::Random->new($self->installed('random_class'));
    $self->install( random => sub { $rng->bytes(@_) });
    return $self;
}


1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Mixin::NextID - the 'v_id_next', 'counter', and 'random' option groups

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is an internal module that implements ID generation for use as
VTable keys.

See L<Net::OAuth2::Scheme::Factory> for actual option usage.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

