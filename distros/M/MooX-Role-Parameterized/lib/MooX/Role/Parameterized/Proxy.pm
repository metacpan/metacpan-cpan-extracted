package MooX::Role::Parameterized::Proxy;
{
    $MooX::Role::Parameterized::Proxy::VERSION = '0.082';
}
use strict;
use warnings;
use Carp qw(croak);

# ABSTRACT: small proxy to offer mop methods like has, with, requires, etc.

=head1 DESCRIPTION

L<MooX::Role::Parameterized::Proxy> is a proxy to the target class. 

This proxy offer has, with, before, around, after, requires and method - to avoid inject magic around the L<apply>

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

sub requires {
    my $self   = shift;
    my $target = $self->{target};
    my $role   = $self->{role};

    if ( $target->can('requires') ) {
        goto &{"${target}::requires"};
    }
    else {
        my $required_method = shift;
        croak "Can't apply $role to $target - missing $required_method"
          if !$target->can($required_method);
    }
}

sub method {
    my ( $self, $name, $code ) = @_;
    my $target = $self->{target};

    carp("method ${target}\:\:${name} already exists, overriding...")
      if $target->can($name);

    no strict 'refs';
    *{"${target}\:\:${name}"} = $code;
}

1;
