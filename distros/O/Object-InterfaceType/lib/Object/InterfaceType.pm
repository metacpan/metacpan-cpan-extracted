package Object::InterfaceType;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = 'interface_type';
our $VERSION = '0.01';

use Scalar::Util 'blessed';

sub interface_type {
    my($typename, $methods) = @_;
    my $caller = caller(0);
    if (ref($typename) eq 'ARRAY') {
        $methods  = $typename;
        $typename = undef;
    }
    $methods = [] unless $methods && ref($methods) eq 'ARRAY';

    my $code = sub {
        my $class = blessed $_[0];
        return unless $class;
        $class->can($_) or return for @{ $methods };
        return 1;
    };

    return $code unless defined $typename;
    no strict 'refs';
    *{"$caller\::is_$typename"} = $code;
}

1;
__END__

=head1 NAME

Object::InterfaceType - the Go lang Interface style duck type checker

=head1 SYNOPSIS

  use Object::InterfaceType;

  # create interface type check function
  interface_type stringify => ['as_string'];
  is_stringify(URI->new) ? 'ok' : 'ng';

  # get interface type code reference
  my $is_stringify = interface_type ['as_string'];
  $is_stringify->(URI->new) ? 'ok' : 'ng';

=head1 DESCRIPTION

Object::InterfaceType is Go lang Interface style duck type checker.

This module export is interface_type function.

It is useful when you receive an object with a specific method.
you can the recyclable duck type check can be performed.

Object::InterfaceType is using Exporter, export of interface_type can be controlled.

  use Object::InterfaceType ();
  Object::InterfaceType::interface_type stringify => ['as_string'];
  is_stringify(URI->new) ? 'ok' : 'ng';


=head1 FUNCTION SPEC

=head2 interface_type $typename => \@methods

C<$typename> added prefix C<is_> is the function name, it creates to current package.

  interface_type stringify => [qw/ new as_string /];

This created function is used as follows.

  my $uri = URI->new;
  if (is_stringify($uri)) {
      say '$uri is stringify object';
  }

C<1> is returned by an object with C<new> and C<is_stringify> method.
C<undef> returns in the other object.

=head2 my $check_code_reference = interface_type \@methods

C<$typename> is omissible.
in that case, the reference of the code to check is returned, without performing creation of a function.

  my $is_stringify = interface_type [qw/ new as_string /];

  my $uri = URI->new;
  if ($is_stringify->($uri)) {
      say '$uri is stringify object';
  }

=head1 TODO

includable interface is unsupported.

specification proposal

  interface_type stringify => [qw/ as_string /];
  my $is_dump = interface_type [qw/ as_dump /];

  # including stringify and $is_dump
  interface_type dump_with_syringify => [
      'new', \&is_stringify, $is_dump
  ];



=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

L<http://golang.org/doc/go_spec.html#Interface_types>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
