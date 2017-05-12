package Module::Collect::Package;
use strict;
use warnings;
use Carp;

sub new {
    my ($class, @args) = @_;
    if (ref $class) {
        return $class->{package}->new(@args) if $class->{package}->can('new');
        croak qq{Can't locate object method "new" via package "$class->{package}"};
    } else {
        return bless { @args }, $class;
    }
}

sub require {
    my ($self) = shift;
    eval { require $self->{path} } or croak $@;
}

sub package { shift->{package} }
sub path { shift->{path} }

1;

__END__

=head1 NAME

Module::Collect::Package - package abstract class for Module::Collect

=head1 SYNOPSIS

  use Module::Collect::Package;

  my $package = Module::Collect::Package->new(
      path    => 'foo/bar/baz.pm',
      package => 'Baz',
  );

  print $package->path;    # foo/bar/baz.pm
  print $package->package; # Baz
  $package->require;       # same require 'foo/bar/baz.pm';
  $package->new;           # same Baz->new;

=head1 AUTHOR

lopnor

Kazuhiro Osawa

=head1 SEE ALSO

L<Module::Collect>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
