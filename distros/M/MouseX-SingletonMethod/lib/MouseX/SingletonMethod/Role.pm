package MouseX::SingletonMethod::Role;
use strict;
use warnings;
use Mouse::Role;

our $VERSION = '0.05';

my $singleton = sub {
    my $self = shift;
    my $methods = shift || {};

    my $meta = $self->meta->create_anon_class(
        superclasses => [ $self->meta->name ],
        methods      => $methods,
    );
    $meta->add_method( meta => sub {$meta} );

    bless $self, $meta->name;
};

sub become_singleton {
    $_[0]->$singleton;
}

sub add_singleton_method {
    $_[0]->$singleton( { $_[1] => $_[2] } );
}

sub add_singleton_methods {
    my $self = shift;
    $self->$singleton( {@_} );
}

no Mouse::Role;
1;
__END__

=pod

=head1 NAME

MouseX::SingletonMethod::Role - Role providing Singleton Method option

=head1 DESCRIPTION

See L<MouseX::SingletonMethod>

=head1 METHODS

=head2 become_singleton

Make the object a singleton

=head2 add_singleton_method

Adds a singleton method to this object:

  $foo->add_singleton_method( foo => sub { 'foo' } );

=head2 add_singleton_methods

Same as above except allows multiple method declaration:

  $bar->add_singleton_methods(
      bar1 => sub { 'bar1' },
      bar2 => sub { 'bar2' },
  );

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
