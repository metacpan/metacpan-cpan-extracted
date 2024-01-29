package MooX::Role::Parameterized::Mop;

use strict;
use warnings;
use Carp         qw(croak);
use Scalar::Util qw(blessed);

our $VERSION = "0.5O1";

# ABSTRACT: small proxy to offer mop methods like has, with, requires, etc.

=head1 DESCRIPTION

L<MooX::Role::Parameterized::Mop> is a proxy to the target class. 

This proxy offer C<has>, C<with>, C<before>, C<around>, C<after>, C<requires> and C<method> to avoid inject magic around the L<apply>

It also provides C<meta> as an alias of TARGET_PACKAGE->meta
=cut

sub new {
    my ( $klass, %args ) = @_;

    return bless { target => $args{target}, role => $args{role} }, $klass;
}

sub has {
    my $self = shift;
    goto &{ $self->{target} . '::has' };
}

sub with {
    my $self = shift;
    goto &{ $self->{target} . '::with' };
}

sub before {
    my $self = shift;
    goto &{ $self->{target} . '::before' };
}

sub around {
    my $self = shift;
    goto &{ $self->{target} . '::around' };
}

sub after {
    my $self = shift;
    goto &{ $self->{target} . '::after' };
}

sub meta {
    my $self = shift;

    return $self->{target}->meta;
}

sub requires {
    my $self = shift;

    goto &{ $self->{role} . '::requires' };
}

sub method {
    my ( $self, $name, $code ) = @_;
    my $target = $self->{target};

    carp("method ${target}::${name} already exists, overriding...")
      if $MooX::Role::Parameterized::VERBOSE && $target->can($name);

    {
        no strict 'refs';
        no warnings 'redefine';
        use warnings FATAL => 'uninitialized';

        *{ ${target} . '::' . ${name} } = $code;
    }
}

1;
