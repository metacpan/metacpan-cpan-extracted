#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Deserializer;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Deserializer - Data structures deserializer

=head1 SYNOPSIS
    
    $data = $app->thaw->json($encoded);
    $data = $app->thaw->yaml($encoded);
    $data = $app->thaw->storable($encoded);
    $data = $app->thaw->dumper($encoded);
    $data = $app->thaw->xml($encoded);

    # also deserialize method is an alias for freeze
    $data = $app->deserialize->json($encoded);

=head1 DESCRIPTION

Nile::Deserializer - Data structures deserializer

=cut

use Nile::Base;
use Module::Load;
extends qw(Nile::Serialization);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 json()
    
    $encoded = qq!{"lname":"elsheshtawy","fname":"ahmed","phone":{"home":"02222444","mobile":"012222333"}}!;

    $data = $app->thaw->json($encoded);

    # returns:
    # $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

Deserialize a JSON structure to a data structure.

=cut

sub json {
    return shift->Json->utf8->decode(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 yaml()
    
    $data = $app->thaw->yaml($encoded);

    # returns:
    # $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

Deserialize a YAML structure to a data structure

=cut

sub yaml {
    shift->Yaml;
    return YAML::thaw(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 storable()
    
    $data = $app->thaw->storable($encoded);

    # returns:
    # $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

Deserialize a Storable structure to a data structure.

=cut

sub storable {
    shift->Storable;
    return Storable::thaw(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dumper()
    
    $data = $app->thaw->dumper($encoded);

    # returns:
    # $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

Deserialize a Data::Dumper structure to a data structure.

=cut

sub dumper {
    my ($self, $data) = @_;
    return undef unless defined $data;
    my $M = "";
    # clearify hashref's as perl may treat it as a block
    $data = '+'.$data if ($data =~ /^\{/);
    my $res = eval($data);
    if ($@) {
        $self->me->abort("Unable to deserialize : $@. $data");
    }
    return $M ? $M : $res;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 xml()
    
    $data = $app->thaw->xml($encoded);

    # returns:
    # $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};

Deserialize a XML structure to a data structure

=cut

sub xml {
    my $xml = shift->Xml->parse(@_);
    return $xml;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'SerealDecoder' => (
      is      => 'rw',
      isa    => 'Sereal::Decoder',
      lazy  => 1,
      default => sub {
          load Sereal::Decoder;
          Sereal::Decoder->new;
      }
  );

=head2 sereal()
    
    # $encoded: binary data

    $data = $app->thaw->sereal($encoded);

    # returns:
    # $data = {fname=>"ahmed", lname=>"elsheshtawy", phone=>{mobile=>"012222333", home=>"02222444"}};


Deserialize binary data to data structure to using L<Sereal::Decoder>.

=cut

sub sereal {
    my ($self) = shift;
    return $self->SerealDecoder->decode(@_);
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
