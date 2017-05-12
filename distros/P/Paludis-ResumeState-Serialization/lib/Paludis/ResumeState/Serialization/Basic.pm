use strict;
use warnings;

package Paludis::ResumeState::Serialization::Basic;
BEGIN {
  $Paludis::ResumeState::Serialization::Basic::AUTHORITY = 'cpan:KENTNL';
}
{
  $Paludis::ResumeState::Serialization::Basic::VERSION = '0.01000410';
}

# ABSTRACT: Basic & Consistent Resume-State serialization interface.

use Paludis::ResumeState::Serialization::Grammar;
use Params::Util qw( _HASHLIKE _STRING );
use Class::Load 0.06 qw();
use English qw( -no_match_vars );


## no critic ( RequireArgUnpacking ProhibitUnreachableCode ProhibitMagicNumbers  RequireCheckedSyscalls )
sub _debug {

  return;    # Comment this for tracing.
  return unless Class::Load::load_optional_class('Data::Dumper');

  local $Data::Dumper::Indent   = 1;
  local $Data::Dumper::Maxdepth = 3;
  print Data::Dumper::Dumper( \@_ );
  return 1;
}


sub serialize {
  my ( $self, $data ) = @_;
  my $string = _serialize_basic_resumespec($data);
  return $string;
}


sub deserialize {
  my ( $self, $content ) = @_;

  local $Paludis::ResumeState::Serialization::Grammar::CLASS_CALLBACK = sub {
    my ( $classname, $parameters, $parameters_list, $extra ) = @_;
    return { type => 'class', classname => $classname, parameters => $parameters_list, %{$extra} };
  };

  local $Paludis::ResumeState::Serialization::Grammar::LIST_CALLBACK = sub {
    my ($parameters) = @_;
    return { type => 'array', parameters => $parameters, count => scalar @{$parameters} };
  };
  my $results;
  my $grammar = Paludis::ResumeState::Serialization::Grammar::grammar();
  local (%RS) = ();

  if ( $content =~ $grammar ) {
    $results = \%RS;
    return $results;
  }

  return;
}

sub _serialize_basic_array {
  my $data  = shift;
  my $out   = 'c(';
  my $i     = 1;
  my @pairs = ();
  for my $value ( @{ $data->{parameters} } ) {
    my $key = $i;
    $i++;
    push @pairs, sprintf q{%s=%s;}, $key, _serialize_basic_value($value);
  }
  push @pairs, 'count=' . _serialize_basic_value( $data->{count} ) . q{;};
  $out .= ( join q{}, @pairs );
  $out .= ')';
  return $out;
}

sub _serialize_basic_class {
  my $data = shift;
  my $out  = $data->{classname} . '(';
  $out .= _serialize_basic_parameters( $data->{parameters} );
  $out .= ')';
  return $out;
}

sub _serialize_basic_value {
  my $value = shift;
  if ( defined _STRING($value) ) {
    $value =~ s/"/\\"/gmsx;
    return sprintf q{"%s"}, $value;
  }
  if ( _HASHLIKE($value) ) {
    if ( defined $value->{type} and $value->{type} eq 'class' ) {
      return _serialize_basic_class($value);
    }
    if ( defined $value->{type} and $value->{type} eq 'array' ) {
      return _serialize_basic_array($value);
    }
    Carp::croak("UNEXPECTED PARAMETER TYPE: $value->{type} ");

  }
  Carp::croak("UNEXPECTED PARAMETER VALUE: $value");

}

sub _serialize_basic_parameters {
  my $data = shift;
  _debug( 'serialize_basic_parameters', $data );

  my @pairs = ();
  for my $kv_pair ( @{$data} ) {
    my ( $key, $value ) = @{$kv_pair};

    #    my $value = $data->{$key};
    push @pairs, sprintf q{%s=%s;}, $key, _serialize_basic_value($value);
  }
  return ( join q{}, @pairs );
}

sub _serialize_basic_resumespec {
  my $data = shift;
  _debug( 'serialize_basic_resumespec', $data );
  return unless _HASHLIKE($data);
  return unless defined $data->{ResumeSpec};
  return unless defined $data->{ResumeSpec}->{classname};
  return unless defined $data->{ResumeSpec}->{type} and $data->{ResumeSpec}->{type} eq 'class';
  return unless defined $data->{ResumeSpec}->{parameters};
  return unless defined $data->{ResumeSpec}->{pid};
  my $out = $data->{ResumeSpec}->{classname} . q{@} . $data->{ResumeSpec}->{pid};
  $out .= '(';
  $out .= _serialize_basic_parameters( $data->{ResumeSpec}->{parameters} );
  $out .= ');';
  return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Paludis::ResumeState::Serialization::Basic - Basic & Consistent Resume-State serialization interface.

=head1 VERSION

version 0.01000410

=head1 SYNOPSIS

See L<< C<::Serialization>|Paludis::ResumeState::Serialization >> for recommended usage.

This interface provides a very "dumb" but consistent serialization support.

    ResumeData@1234(foo="bar";baz="quux";doo=c(1="baz";2="buzz";3="bizz";count="3";);borzoi=Hysterical(););

Will be deserialized as follows:

    {
      ResumeSpec => {
        type       => 'class',
        classname  => 'ResumeData',
        pid        => '1234',
        parameters => [
          [ 'foo', 'bar' ],
          [ 'baz', 'quux' ],
          [
            'doo',
            {
              type       => 'array',
              parameters => [ 'baz', 'buzz', 'bizz' ],
              count      => 3
            }
          ],
          [
            'borzoi',
            {
              type       => 'class',
              classname  => 'Hysterical',
              parameters => [],
            }
          ],
        ],
      },
    }

And giving that exact structure to serialize, will return the aforementioned serialized string.

=head1 METHODS

=head2 serialize

    my $string = ->serialize( $data );

=head2 deserialize

    my $object = ->deserialize( $content );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
