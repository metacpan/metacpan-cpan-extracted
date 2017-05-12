#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Serialization;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Serialization - Base class for L<Nile::Serializer> and L<Nile::Deserializer>

=head1 SYNOPSIS
    
    $app->freeze;
    $app->thaw;

=head1 DESCRIPTION

Nile::Serialization - Base class for L<Nile::Serializer> and L<Nile::Deserializer>

This is a base class for L<Nile::Serializer> and L<Nile::Deserializer> modules. It also provides direct access to the serialization classes.

=cut

#use Nile::Base;
use Moose;
use Module::Load;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 Json
    
    $json = $app->freeze->Json;
    $encoded = $json->utf8->encode($data);

Returns L<JSON> object.

=cut

has 'Json' => (
      is      => 'rw',
      isa    => 'JSON',
      lazy  => 1,
      default => sub {
          load JSON;
          JSON->new;
      }
  );

=head2 Yaml
    
    $yaml = $app->freeze->Yaml;

Returns L<YAML> object.

=cut

has 'Yaml' => (
      is      => 'rw',
      isa    => 'YAML',
      lazy  => 1,
      default => sub {
          load YAML;
          YAML->new;
      }
  );

=head2 Storable
    
    $json = $app->freeze->Storable;

Returns "Storable" string. L<Storable> deos not suppot new method.

=cut

has 'Storable' => (
      is      => 'ro',
      lazy  => 1,
      default => sub {
          load Storable;
          "Storable";
      }
  );

=head2 Dumper
    
    $dumper = $app->freeze->Dumper;

Returns L<Data::Dumper> object.

=cut

has 'Dumper' => (
      is      => 'rw',
      isa    => 'Data::Dumper',
      lazy  => 1,
      default => sub {
          load Data::Dumper;
          Data::Dumper->new;
      }
  );

=head2 Xml
    
    $xml = $app->freeze->Xml;

Returns L<XML::TreePP> object.

=cut

has 'Xml' => (
      is      => 'ro',
      #isa    => 'Data::Dumper',
      lazy  => 1,
      default => sub {
          load XML::TreePP;
          XML::TreePP->new;
      }
  );


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
