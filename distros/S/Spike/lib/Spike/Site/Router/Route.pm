package Spike::Site::Router::Route;

use strict;
use warnings;

use base qw(Spike::Tree);

use List::Util qw(first any);
use HTTP::Status qw(:constants);

sub route {
    my ($self, $path) = splice @_, 0, 2;

    return $self if !defined $path || !length $path;

    my $first = ($path =~ s!^/*([^/]+)!!) && $1;

    return $self if !length $first;

    my $rule = $first =~ m!^#! && @_ && ref $_[0] && shift;
    my $fake_rule = sub {};

    my $child = first {
        $_->name eq $first &&
        ($_->rule || $fake_rule) == ($rule || $fake_rule)
    } $self->childs;

    if (!$child) {
        $child = $self->new($first);
        $self->add_child($child);

        $child->rule($rule) if $rule;
    }

    return $child->route($path, @_);
}

sub _check_rule {
    my ($self, $rule, $value) = @_;

    if (ref $rule eq 'CODE') {
        return $rule->($_ = $value);
    }
    elsif (ref $rule eq 'ARRAY') {
        return any { $_ eq $value } @$rule;
    }
    elsif (ref $rule eq 'Regexp') {
        return $value =~ m!^(?:$rule)$!;
    }

    return !1;
}

sub _find {
    my ($self, $part) = @_;

    my @ordered = ([], [], []);

    for my $child ($self->childs) {
        my $name = $child->name;

        if ($name eq '*') {
            push @{$ordered[2]}, $child;
        }
        elsif ($name =~ m!^#!) {
            my $rule = $child->rule;

            if (!$rule || $self->_check_rule($rule, $part)) {
                push @{$ordered[$rule ? 0 : 1]}, $child;
            }
        }
        elsif ($name eq $part) {
            return $child;
        }
    }

    return $ordered[0][0] || $ordered[1][0] || $ordered[2][0] || ();
}

sub find {
    my ($self, $path) = @_;

    return $self if !defined $path || !length $path;

    my $first = ($path =~ s!^/*([^/]+)!!) && $1;

    return $self if !length $first;

    return $_->find($path) for $self->_find($first);

    return wantarray ? (undef, $self) : ();
}

sub _handler {
    my ($self, $hash, $default) = splice @_, 0, 3;

    return $hash->{$default} if !@_;

    if (@_ == 1) {
        return $hash->{+shift}
            if defined $_[0] && !ref $_[0];

        $hash->{$default} = shift;
        return $self;
    }

    $hash->{+shift} = $_[1], shift while @_;
    return $self;
}

sub _handlers {
    my ($self, $hash) = @_;

    return grep { defined $hash->{$_} }
        keys %$hash;
}

sub method {
    my $self = shift;
    return $self->_handler($self->{method} ||= {}, '*', @_);
}

sub methods {
    my $self = shift;
    return $self->_handlers($self->{method});
}

sub _method {
    my ($self, $method) = splice @_, 0, 2;

    return $self->method($method) if !@_;

    if (@_ == 1) {
        return $self->route(shift)->method($method)
            if defined $_[0] && !ref $_[0];

        $self->method($method, shift);
        return $self;
    }

    $self->route(shift)->method($method, shift) while @_;
    return $self;
}

sub get    { shift->_method('GET', @_) }
sub post   { shift->_method('POST', @_) }
sub put    { shift->_method('PUT', @_) }
sub delete { shift->_method('DELETE', @_) }
sub all    { shift->_method('*', @_) }

sub error {
    my $self = shift;
    return $self->_handler($self->{error} ||= {}, HTTP_INTERNAL_SERVER_ERROR, @_);
}

sub errors {
    my $self = shift;
    return $self->_handlers($self->{error});
}

sub prepare {
    my $self = shift;
    return $self->_handler($self, undef, 'prepare', @_ ? shift : ());
}

sub finalize {
    my $self = shift;
    return $self->_handler($self, undef, 'finalize', @_ ? shift : ());
}

__PACKAGE__->mk_accessors(qw(rule));

1;
