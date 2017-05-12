#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Serializer;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Serializer - Data structures Serializer

=head1 SYNOPSIS
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

    $encoded = $app->freeze->json($data);
    $encoded = $app->freeze->yaml($data);
    $encoded = $app->freeze->storable($data);
    $encoded = $app->freeze->dumper($data);
    $encoded = $app->freeze->xml($data);

    # also serialize method is an alias for freeze
    $encoded = $app->serialize->json($data);

=head1 DESCRIPTION

Nile::Serializer - Data structures Serializer

=cut

#use Nile::Base;
use Moose;
use Module::Load;
extends qw(Nile::Serialization);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 json()
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};
    
    $encoded = $app->freeze->json($data);

    # returns:

    # {"lname":"elsheshtawy","fname":"ahmed","phone":{"home":"02222444","mobile":"012222333"}}

Serialize a data structure to a JSON structure.

=cut

sub json {
    return shift->Json->utf8->encode(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 yaml()
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

    $encoded = $app->freeze->yaml($data);

    # returns:

    # ---
    # fname: ahmed
    # lname: elsheshtawy
    # phone:
    #   home: 02222444
    #   mobile: 012222333

Serialize a data structure to a YAML structure.

=cut

sub yaml {
    shift->Yaml;
    return YAML::freeze(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 storable()
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

    $encoded = $app->freeze->storable($data);

    # returns: binary data

Serialize a data structure to a Storable structure.

=cut

sub storable {
    shift->Storable;
    # using network byte order makes sense to always do, under all circumstances to make it platform neutral
    return Storable::nfreeze(@_);
    #return Storable::freeze(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dumper()
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

    $encoded = $app->freeze->dumper($data);

    # returns:

    # $M = {'lname' => 'elsheshtawy','fname' => 'ahmed','phone' => {'home' => '02222444','mobile' => '012222333'}};

Serialize a data structure to a Data::Dumper structure.

=cut

sub dumper {

    my ($self, $data) = @_;

    my $d = Data::Dumper->new([$data], ["M"]);

    $d->Purity(1);
    $d->Quotekeys(1);
    $d->Deepcopy(0);
    $d->Indent(0);
    $d->Terse(0);
    $d->Useqq(0);

    return $d->Dump;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 xml()
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

    $encoded = $app->freeze->xml($data);

    # returns:

    # <?xml version="1.0" encoding="UTF-8" ?>
    # <fname>ahmed</fname>
    # <lname>elsheshtawy</lname>
    # <phone>
    # <home>02222444</home>
    # <mobile>012222333</mobile>
    # </phone>


Serialize a data structure to a XML structure.

=cut

sub xml {
    my $xml = shift->Xml;
    $xml->set(output_encoding => 'UTF-8');
    $xml->set(indent => 0);
    return $xml->write(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'SerealEncoder' => (
      is      => 'rw',
      isa    => 'Sereal::Encoder',
      lazy  => 1,
      default => sub {
          load Sereal::Encoder;
          Sereal::Encoder->new;
      }
  );

=head2 sereal()
    
    $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

    $encoded = $app->freeze->sereal($data);

    # returns: binary data

Serialize a data structure to a binary data using L<Sereal::Encoder>.

=cut

sub sereal {
    my ($self) = shift;
    return $self->SerealEncoder->encode(@_);
}
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
