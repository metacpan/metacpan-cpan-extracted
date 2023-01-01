package MooseX::Storage::Format::JSONpm 0.093094;
use MooseX::Role::Parameterized;
# ABSTRACT: a format role for MooseX::Storage using JSON.pm

#pod =head1 SYNOPSIS
#pod
#pod   package Point;
#pod   use Moose;
#pod   use MooseX::Storage;
#pod
#pod   with Storage(format => 'JSONpm');
#pod
#pod   has 'x' => (is => 'rw', isa => 'Int');
#pod   has 'y' => (is => 'rw', isa => 'Int');
#pod
#pod   1;
#pod
#pod   my $p = Point->new(x => 10, y => 10);
#pod
#pod   # pack the class into a JSON string
#pod   my $json = $p->freeze(); # { "__CLASS__" : "Point", "x" : 10, "y" : 10 }
#pod
#pod   # unpack the JSON string into an object
#pod   my $p2 = Point->thaw($json);
#pod
#pod ...in other words, it can be used as a drop-in replacement for
#pod MooseX::Storage::Format::JSON.  However, it can also be parameterized:
#pod
#pod   package Point;
#pod   use Moose;
#pod   use MooseX::Storage;
#pod
#pod   with Storage(format => [ JSONpm => { json_opts => { pretty => 1 } } ]);
#pod
#pod At present, C<json_opts> is the only parameter, and is used when calling the
#pod C<to_json> and C<from_json> routines provided by the L<JSON|JSON> library.
#pod Default values are merged into the given hashref (with explict values taking
#pod priority).  The defaults are as follows:
#pod
#pod   { ascii => 1 }
#pod
#pod =cut

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

#pod =method freeze
#pod
#pod   my $json = $obj->freeze;
#pod
#pod =cut

  method freeze => sub {
    my ($self, @args) = @_;

    my $json = to_json($self->pack(@args), $p->json_opts);
    return $json;
  };

#pod =method thaw
#pod
#pod   my $obj = Class->thaw($json)
#pod
#pod =cut

  method thaw => sub {
    my ($class, $json, @args) = @_;

    $class->unpack( from_json($json, $p->json_opts), @args);
  };

};

1;

#pod =head1 THANKS
#pod
#pod Thanks to Stevan Little, Chris Prather, and Yuval Kogman, from whom I cribbed
#pod this code -- from MooseX::Storage::Format::JSON.

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Format::JSONpm - a format role for MooseX::Storage using JSON.pm

=head1 VERSION

version 0.093094

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 freeze

  my $json = $obj->freeze;

=head2 thaw

  my $obj = Class->thaw($json)

=head1 THANKS

Thanks to Stevan Little, Chris Prather, and Yuval Kogman, from whom I cribbed
this code -- from MooseX::Storage::Format::JSON.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
