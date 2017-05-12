package MooseX::Storage::Format::JSONpm;
{
  $MooseX::Storage::Format::JSONpm::VERSION = '0.093093';
}
use MooseX::Role::Parameterized;
# ABSTRACT: a format role for MooseX::Storage using JSON.pm


use namespace::autoclean;

use JSON;

parameter json_opts => (
  isa => 'HashRef',
  default => sub { return { } },
  initializer => sub {
    my ($self, $value, $set) = @_;

    %$value = (ascii => 1, %$value);
    $set->($value);
  }
);

role {
  my $p = shift;

  requires 'pack';
  requires 'unpack';


  method freeze => sub {
    my ($self, @args) = @_;

    my $json = to_json($self->pack(@args), $p->json_opts);
    return $json;
  };


  method thaw => sub {
    my ($class, $json, @args) = @_;

    $class->unpack( from_json($json, $p->json_opts), @args);
  };

};

1;

__END__

=pod

=head1 NAME

MooseX::Storage::Format::JSONpm - a format role for MooseX::Storage using JSON.pm

=head1 VERSION

version 0.093093

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage(format => 'JSONpm');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  # pack the class into a JSON string
  my $json = $p->freeze(); # { "__CLASS__" : "Point", "x" : 10, "y" : 10 }

  # unpack the JSON string into an object
  my $p2 = Point->thaw($json);

...in other words, it can be used as a drop-in replacement for
MooseX::Storage::Format::JSON.  However, it can also be parameterized:

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage(format => [ JSONpm => { json_opts => { pretty => 1 } } ]);

At present, C<json_opts> is the only parameter, and is used when calling the
C<to_json> and C<from_json> routines provided by the L<JSON|JSON> library.
Default values are merged into the given hashref (with explict values taking
priority).  The defaults are as follows:

  { ascii => 1 }

=head1 METHODS

=head2 freeze

  my $json = $obj->freeze;

=head2 thaw

  my $obj = Class->thaw($json)

=head1 THANKS

Thanks to Stevan Little, Chris Prather, and Yuval Kogman, from whom I cribbed
this code -- from MooseX::Storage::Format::JSON.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
