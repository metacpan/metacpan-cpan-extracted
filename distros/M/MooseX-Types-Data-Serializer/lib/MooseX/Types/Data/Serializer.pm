package MooseX::Types::Data::Serializer;
{
  $MooseX::Types::Data::Serializer::VERSION = '0.02';
}
use strict;
use warnings;

=head1 NAME

MooseX::Types::Data::Serializer - A Data::Serializer type library for Moose.

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Types::Data::Serializer;
    
    has serializer => (
        is       => 'ro',
        isa      => 'Data::Serializer',
        required => 1,
        coerce   => 1,
    );
    
    has raw_serializer => (
        is       => 'ro',
        isa      => 'Data::Serializer::Raw',
        required => 1,
        coerce   => 1,
    );
    
    # String will be coerced in to a Data::Serializer object:
    MyClass->new(
        serializer     => 'YAML',
        raw_serializer => 'Storable',
    );
    
    # Hashref will be coerced as well:
    MyClass->new(
        serializer => { serializer => 'YAML', digester => 'MD5' },
        raw_serializer => { serializer => 'Storable' },
    );
    
    use MooseX::Types::Data::Serializer qw( Serializer RawSerializer );
    my $serializer = to_Serializer( 'YAML' );
    my $raw_serializer = to_RawSerializer({ serializer=>'Storable', digester=>'MD5' });
    if (is_Serializer($serializer)) { ... }
    if (is_RawSerializer($raw_serializer)) { ... }

=head1 DESCRIPTION

This module provides L<Data::Serializer> types and coercians for L<Moose> attributes.

Two standard Moose types are provided; Data::Serializer and Data::Serializer::Raw.
In addition, two other MooseX::Types types are provided; Serializer and RawSerializer.

See the L<MooseX::Types> documentation for details on how that works.

=head1 TYPES

=head2 Data::Serializer

This is a standard Moose type that provides coercion from a string or a hashref.  If
a string is passed then it is used for the 'serializer' argumen to Data::Serializer->new().
If a hashref is being coerced from then it will be de-referenced and used as the
arguments to Data::Serializer->new().

=head2 Data::Serializer::Raw

This type works just like Data::Serializer, but for the L<Data::Serializer::Raw> module.

=head2 Serializer

This is a L<MooseX::Types> type that works just like the Data::Serializer type.

=head2 RawSerializer

Just like the Serializer type, but for Data::Serializer::Raw.

=cut

use Moose::Util::TypeConstraints;
use Data::Serializer;
use Data::Serializer::Raw;

use MooseX::Types -declare => [qw( Serializer RawSerializer )];

use MooseX::Types::Moose qw( Str HashRef );

class_type 'Data::Serializer';
class_type 'Data::Serializer::Raw';

subtype Serializer, as 'Data::Serializer';
subtype RawSerializer, as 'Data::Serializer::Raw';

foreach my $type ('Data::Serializer', Serializer) {
    coerce $type,
        from Str, via { Data::Serializer->new( serializer => $_ ) },
        from HashRef, via { Data::Serializer->new( %$_ ) };
}

foreach my $type ('Data::Serializer::Raw', RawSerializer) {
    coerce $type,
        from Str, via { Data::Serializer::Raw->new( serializer => $_ ) },
        from HashRef, via { Data::Serializer::Raw->new( %$_ ) };
}

eval { require MooseX::Getopt; };
if ( !$@ ) {
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 'Data::Serializer', '=s' );
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 'Data::Serializer::Raw', '=s' );
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( Serializer, '=s' );
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( RawSerializer, '=s' );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

