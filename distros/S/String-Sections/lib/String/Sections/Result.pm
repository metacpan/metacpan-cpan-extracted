use strict;
use warnings;

package String::Sections::Result;
BEGIN {
  $String::Sections::Result::AUTHORITY = 'cpan:KENTNL';
}
{
  $String::Sections::Result::VERSION = '0.3.2';
}

# ABSTRACT: Glorified wrapper around a hash representing a parsed String::Sections result
#


use Moo 1.000008;

## no critic (RequireArgUnpacking)

sub _croak   { require Carp;         goto &Carp::croak; }
sub _blessed { require Scalar::Util; goto &Scalar::Util::blessed }



use Types::Standard qw( HashRef ArrayRef ScalarRef Str Maybe );

our $TYPE_SECTION_NAME     = Str;
our $TYPE_SECTION_NAMES    = ArrayRef [Str];
our $TYPE_SECTION          = ScalarRef [Str];
our $TYPE_OPTIONAL_SECTION = Maybe [$TYPE_SECTION];
our $TYPE_CURRENT          = Maybe [Str];
our $TYPE_SECTIONS         = HashRef [$TYPE_SECTION];

has 'sections' => (
  is      => ro =>,
  isa     => $TYPE_SECTIONS,
  lazy    => 1,
  builder => sub {
    return {};
  },
);



has '_current' => (
  is        => ro  =>,
  isa       => $TYPE_CURRENT,
  reader    => '_current',
  writer    => 'set_current',
  predicate => 'has_current',
  lazy      => 1,
  builder   => sub { return _croak('current never set, but tried to use it') },
);


has '_section_names' => (
  is   => ro =>,
  isa  => $TYPE_SECTION_NAMES,
  lazy => 1,
  builder => sub { return [] },
);


sub section {
  $TYPE_SECTION_NAME->assert_valid( $_[1] );
  return $_[0]->sections->{ $_[1] };
}


sub section_names { return ( my @list = @{ $_[0]->_section_names } ) }


sub section_names_sorted { return ( my @list = sort @{ $_[0]->_section_names } ) }


sub has_section {
  $TYPE_SECTION_NAME->assert_valid( $_[1] );
  return exists $_[0]->sections->{ $_[1] };
}


sub set_section {
  $TYPE_SECTION_NAME->assert_valid( $_[1] );
  $TYPE_SECTION->assert_valid( $_[2] );
  if ( not exists $_[0]->sections->{ $_[1] } ) {
    push @{ $_[0]->_section_names }, $_[1];
  }
  $_[0]->sections->{ $_[1] } = $_[2];
  return;
}


sub append_data_to_current_section {
  $TYPE_OPTIONAL_SECTION->assert_valid( $_[1] );
  if ( not exists $_[0]->sections->{ $_[0]->_current } ) {
    push @{ $_[0]->_section_names }, $_[0]->_current;
    my $blank = q{};
    $_[0]->sections->{ $_[0]->_current } = \$blank;
  }
  if ( defined $_[1] ) {
    ${ $_[0]->sections->{ $_[0]->_current } } .= ${ $_[1] };
  }
  return;
}


sub append_data_to_section {
  $TYPE_SECTION_NAME->assert_valid( $_[1] );
  $TYPE_OPTIONAL_SECTION->assert_valid( $_[2] );
  if ( not exists $_[0]->sections->{ $_[1] } ) {
    push @{ $_[0]->_section_names }, $_[1];
    my $blank = q{};
    $_[0]->sections->{ $_[1] } = \$blank;
  }
  if ( defined $_[2] ) {
    ${ $_[0]->sections->{ $_[1] } } .= ${ $_[2] };
  }
  return;
}


sub shallow_clone {
  my $class = _blessed( $_[0] ) || $_[0];
  my $instance = $class->new();
  for my $name ( $_[0]->section_names ) {
    $instance->set_section( $name, $_[0]->sections->{$name} );
  }
  return $instance;
}


sub shallow_merge {
  my $class = _blessed( $_[0] ) || $_[0];
  my $instance = $class->new();
  for my $name ( $_[0]->section_names ) {
    $instance->set_section( $name, $_[0]->sections->{$name} );
  }
  for my $name ( $_[1]->section_names ) {
    $instance->set_section( $name, $_[1]->sections->{$name} );
  }
  return $instance;
}


sub _compose_section {
  $TYPE_SECTION_NAME->assert_valid( $_[1] );
  return sprintf qq[__[%s]__\n%s], $_[1], ${ $_[0]->sections->{ $_[1] } };
}


sub to_s {
  my $self = $_[0];
  return join qq{\n}, map { $self->_compose_section($_) } $self->section_names_sorted;
}

1;

__END__

=pod

=head1 NAME

String::Sections::Result - Glorified wrapper around a hash representing a parsed String::Sections result

=head1 VERSION

version 0.3.2

=head1 METHODS

=head2 C<sections>

    my $sections = $result->sections;
    for my $key( keys %{$sections}) {
        ...
    }

=head2 C<set_current>

    $result->set_current('foo');

=head2 C<has_current>

    if ( $result->has_current ){
    }

=head2 C<section>

    my $ref = $result->section( $name );
    print ${$ref};

=head2 C<section_names>

This contains the names of the sections in the order they were found/inserted.

    my @names = $result->section_names;

=head2 C<section_names_sorted>

=head2 C<has_section>

    if ( $result->has_section($name) ) {
        ...
    }

=head2 C<set_section>

    $result->set_section($name, \$data);

=head2 C<append_data_to_current_section>

    # Unitialise slot
    $result->append_data_to_current_section();
    # Unitialise and/or extend slot
    $result->append_data_to_current_section('somedata');

=head2 C<append_data_to_section>

    # Unitialise slot
    $result->append_data_to_current_section( $name );
    # Unitialise and/or extend slot
    $result->append_data_to_current_section( $name, 'somedata');

=head2 C<shallow_clone>

    my $clone = $result->shallow_clone;

    if ( refaddr $clone->section('foo') == refaddr $result->section('foo') ) {
        print "clone success!"
    }

=head2 C<shallow_merge>

    my $merged = $result->shallow_merge( $other );

    if ( refaddr $merged->section('foo') == refaddr $result->section('foo') ) {
        print "foo copied from orig successfully!"
    }
    if ( refaddr $merged->section('bar') == refaddr $other->section('bar') ) {
        print "bar copied from other successfully!"
    }

=head2 C<to_s>

    my $str = $result->to_s

=head1 ATTRIBUTES

=head2 C<sections>

=head1 PRIVATE ATTRIBUTES

=head2 C<_current>

=head2 C<_section_names>

=head1 PRIVATE METHODS

=head2 C<_current>

    my $current = $result->_current;

=head2 <_section_names>

=head2 C<_compose_section>

    my $str = $result->_compose_section('bar');

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"String::Sections::Result",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
