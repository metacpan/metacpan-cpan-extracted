package Sub::Mux;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.02';

sub new {
    my $class = shift;

    my @subs;
    $class->_push(\@subs, \@_);
    bless { subs => \@subs }, $class;
}

sub subs { $_[0]->{subs} }

sub execute_first {
    my $self = shift;

    for my $code (@{$self->subs}) {
        my $res = $code->(@_);
        return $res if defined $res;
    }
    return;
}

sub execute {
    execute_first(@_);
}

sub execute_all {
    my $self = shift;

    my $result;
    for my $code (@{$self->subs}) {
        my $res = $code->(@_);
        push @{$result}, $res;
    }
    return $result;
}

sub execute_list {
    my $self = shift;

    my $list = $self->subs;

    my $result;
    for my $i (@_) {
        my $code = $list->[$i];
        my $res = $code->(@_);
        push @{$result}, $res;
    }
    return $result;
}

sub unshift_subs {
    my $self = shift;

    $self->_unshift($self->subs, \@_);
}

sub _unshift {
    my ($self, $list, $append) = @_;

    for my $arg (reverse @{$append}) {
        if (ref $arg eq 'CODE') {
            unshift @{$list}, $arg;
        }
        else {
            croak 'wrong subs';
        }
    }
}

sub shift_subs { shift @{$_[0]->subs}; }

sub push_subs {
    my $self = shift;

    $self->_push($self->subs, \@_);
}

sub _push {
    my ($self, $list, $append) = @_;

    for my $arg (@{$append}) {
        if (ref $arg eq 'CODE') {
            push @{$list}, $arg;
        }
        else {
            croak 'wrong subs';
        }
    }
}

sub pop_subs { pop @{$_[0]->subs}; }

1;

__END__

=head1 NAME

Sub::Mux - multiplexer to execute subs


=head1 SYNOPSIS

    use Sub::Mux;

    my $mux = Sub::Mux->new(
        sub { 'a' },
        sub { ['b'] },
    );

    $mux->push_subs( sub { 'c' } );

    $res = $mux->execute;            # 'a'

    $res = $mux->execute_all;        # ['a', ['b'], 'c']

    $res = $mux->execute_list(0, 1); # ['a', ['b'] ]


=head1 DESCRIPTION

Sub::Mux is the module for multiplex subs executer


=head1 METHODS

=head2 new(@args)

constructor

C<@args> contains coderef list.

=head2 subs

to get subs list

=head2 execute_first, execute

executing subs and return the first result.

=head2 execute_all

execute all subs and return all results as array ref.

=head2 execute_list(@args)

execute specific subs and return the result as array ref.

C<@args> is the list of index.

=head2 push_subs(@subs), pop_subs, unshift_subs(@subs), shift_subs

To operate the element of subs.
These are similar to core functions: C<push>, C<pop>, C<unshift>, C<shift>


=head1 REPOSITORY

Sub::Mux is hosted on github
<http://github.com/bayashi/Sub-Mux>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
