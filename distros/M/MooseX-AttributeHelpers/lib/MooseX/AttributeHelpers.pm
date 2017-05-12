package MooseX::AttributeHelpers; # git description: v0.24-5-gb4c52f0
# ABSTRACT: (DEPRECATED) Extend your attribute interfaces

our $VERSION = '0.25';

use Moose 0.56 ();

use MooseX::AttributeHelpers::Meta::Method::Provided;
use MooseX::AttributeHelpers::Meta::Method::Curried;

use MooseX::AttributeHelpers::Trait::Bool;
use MooseX::AttributeHelpers::Trait::Counter;
use MooseX::AttributeHelpers::Trait::Number;
use MooseX::AttributeHelpers::Trait::String;
use MooseX::AttributeHelpers::Trait::Collection::List;
use MooseX::AttributeHelpers::Trait::Collection::Array;
use MooseX::AttributeHelpers::Trait::Collection::Hash;
use MooseX::AttributeHelpers::Trait::Collection::ImmutableHash;
use MooseX::AttributeHelpers::Trait::Collection::Bag;

use MooseX::AttributeHelpers::Counter;
use MooseX::AttributeHelpers::Number;
use MooseX::AttributeHelpers::String;
use MooseX::AttributeHelpers::Bool;
use MooseX::AttributeHelpers::Collection::List;
use MooseX::AttributeHelpers::Collection::Array;
use MooseX::AttributeHelpers::Collection::Hash;
use MooseX::AttributeHelpers::Collection::ImmutableHash;
use MooseX::AttributeHelpers::Collection::Bag;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers - (DEPRECATED) Extend your attribute interfaces

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::AttributeHelpers;

  has 'mapping' => (
      metaclass => 'Collection::Hash',
      is        => 'rw',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      provides  => {
          exists    => 'exists_in_mapping',
          keys      => 'ids_in_mapping',
          get       => 'get_mapping',
          set       => 'set_mapping',
      },
      curries  => {
          set       => { set_quantity => [ 'quantity' ] }
      }
  );


  # ...

  my $obj = MyClass->new;
  $obj->set_quantity(10);      # quantity => 10
  $obj->set_mapping(4, 'foo'); # 4 => 'foo'
  $obj->set_mapping(5, 'bar'); # 5 => 'bar'
  $obj->set_mapping(6, 'baz'); # 6 => 'baz'


  # prints 'bar'
  print $obj->get_mapping(5) if $obj->exists_in_mapping(5);

  # prints '4, 5, 6'
  print join ', ', $obj->ids_in_mapping;

=head1 DESCRIPTION

B<This distribution is deprecated. The features it provides have been added to
the Moose core code as L<Moose::Meta::Attribute::Native>. This distribution
should not be used by any new code.>

While L<Moose> attributes provide you with a way to name your accessors,
readers, writers, clearers and predicates, this library provides commonly
used attribute helper methods for more specific types of data.

As seen in the L</SYNOPSIS>, you specify the extension via the 
C<metaclass> parameter. Available meta classes are:

=head1 PARAMETERS

=head2 provides

This points to a hashref that uses C<provider> for the keys and
C<method> for the values.  The method will be added to
the object itself and do what you want.

=head2 curries

This points to a hashref that uses C<provider> for the keys and
has two choices for the value:

You can supply C<< {method => [ @args ]} >> for the values.  The method will be
added to the object itself (always using C<@args> as the beginning arguments).

Another approach to curry a method provider is to supply a coderef instead of an
arrayref. The code ref takes C<$self>, C<$body>, and any additional arguments
passed to the final method.

  # ...

  curries => {
      grep => {
          times_with_day => sub {
              my ($self, $body, $datetime) = @_;
              $body->($self, sub { $_->ymd eq $datetime->ymd });
          }
      }
  }

  # ...

  $obj->times_with_day(DateTime->now); # takes datetime argument, checks day

=head1 METHOD PROVIDERS

=over

=item L<Number|MooseX::AttributeHelpers::Number>

Common numerical operations.

=item L<String|MooseX::AttributeHelpers::String>

Common methods for string operations.

=item L<Counter|MooseX::AttributeHelpers::Counter>

Methods for incrementing and decrementing a counter attribute.

=item L<Bool|MooseX::AttributeHelpers::Bool>

Common methods for boolean values.

=item L<Collection::Hash|MooseX::AttributeHelpers::Collection::Hash>

Common methods for hash references.

=item L<Collection::ImmutableHash|MooseX::AttributeHelpers::Collection::ImmutableHash>

Common methods for inspecting hash references.

=item L<Collection::Array|MooseX::AttributeHelpers::Collection::Array>

Common methods for array references.

=item L<Collection::List|MooseX::AttributeHelpers::Collection::List>

Common list methods for array references. 

=back

=head1 DEPRECATION NOTICE

The functionality in this family of modules is now implemented in the L<Moose>
core as L<Moose::Meta::Attribute::Native|native attribute traits>.  No more
development is being done on MooseX::AttributeHelpers, so we encourage you to
switch to native attribute traits.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AttributeHelpers>
(or L<bug-MooseX-AttributeHelpers@rt.cpan.org|mailto:bug-MooseX-AttributeHelpers@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 CONTRIBUTORS

=for stopwords Shawn M Moore Stevan Little Dave Rolsky Florian Ragwitz Yuval Kogman Jason May Karen Etheridge Cory G Watson Jesse Luehrs Robert Boone Bruno Vecchi Johannes Plunien Mike Whitaker Hans Dieter Pearcey Paul Driver 'phaylon' Sedlacek Evan Carroll Dagfinn Ilmari Mannsåker Chris Prather Tom Lanyon nperez

=over 4

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Jason May <jason.a.may@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Cory G Watson <gphat@onemogin.com>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Robert Boone <robo4288@gmail.com>

=item *

Bruno Vecchi <vecchi.b@gmail.com>

=item *

Johannes Plunien <plu@pqpq.de>

=item *

Mike Whitaker <mike@altrion.org>

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Paul Driver <frodwith@gmail.com>

=item *

Robert 'phaylon' Sedlacek <rs@474.at>

=item *

Evan Carroll <me@evancarroll.com>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Chris Prather <cprather@hdpublishing.com>

=item *

Tom Lanyon <tom@netspot.com.au>

=item *

Chris Prather <chris@prather.org>

=item *

nperez <nperez@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
