# $File: //member/autrijus/RDF-YAML/lib/RDF/Simple/Serialiser/YAML.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 8523 $ $DateTime: 2003/10/22 04:14:34 $

package RDF::Simple::Serialiser::YAML;
$RDF::Simple::Serialiser::YAML::VERSION = '0.01';

use strict;
use RDF::Simple::Serialiser;
use base 'RDF::Simple::Serialiser';

=head1 NAME

RDF::Simple::Serialiser::YAML - Simple RDF/YAML serialiser

=head1 SYNOPSIS

    my $ser = RDF::Simple::Serialiser::YAML->new;

    my @triples = (
	['http://example.com/url#', 'dc:creator', 'zool@example.com'],
	['http://example.com/url#', 'foaf:Topic', '_id:1234'],
	['_id:1234','http://www.w3.org/2003/01/geo/wgs84_pos#lat','51.334422']
    );

    my $yaml_string = $ser->serialise(@triples);

=head1 DESCRIPTION

This module is a subclass of L<RDF::Simple::Serialiser> to
produce serialised RDF/YAML documents from an array of triples.

Please see L<RDF::Simple::Serialiser> for a list of supported
methods.

=cut

# Escapes for unprintable characters
my @escapes = qw(\z   \x01 \x02 \x03 \x04 \x05 \x06 \a
                 \x08 \t   \n   \v   \f   \r   \x0e \x0f
                 \x10 \x11 \x12 \x13 \x14 \x15 \x16 \x17
                 \x18 \x19 \x1a \e   \x1c \x1d \x1e \x1f
                );

sub render {
    my ($self, $template, $data, $out_object) = @_;
    $data->{emit} = sub { $self->emit($_[0]) };
    return $self->SUPER::render($template, $data, $out_object);
}

sub emit {
    my ($self, $string) = @_;

    use bytes;
    if ($string =~ /^\W|[\x00-\x08\x0b-\x0d\x0e-\x1f:#]|^\s|\s\z|\A\z/) {
	$string =~ s/\\/\\\\/g;
	$string =~ s/"/\\"/g;
	$string =~ s/([\x00-\x1f])/$escapes[ord($1)]/ge;
	return qq{"$string"};
    }
    else {
	return $string;
    }
}

sub get_template {
    my $template = <<'END_TEMPLATE';
[% USE url('') %]--- #YAML:1.0
'':[% FOREACH key = ns.keys.sort %]
  [% IF key.length %][% key %][% ELSE %]''[% END %]: [% url(ns.$key) %][% END %][% FOREACH object = objects %]
[% IF object.Uri %][% object.Uri %][% ELSE %][% object.NodeId %][% END %]:[% IF object.Class != 'rdf:Description' %]
  rdf:type: [% object.Class %][% END %][% FOREACH lit = object.literal.keys.sort %][% FOREACH prop = object.literal.$lit %]
  [% lit %]: [% emit(prop) %][% END %][% END %][% FOREACH res = object.resource.keys.sort %][% FOREACH prop = object.resource.$res %]
  [% res %]: [% url(prop) %][% END %][% END %][% FOREACH node = object.nodeid.keys.sort %][% FOREACH prop = object.nodeid.$node %]
  [% node %]: [% prop %][% END %][% END %][% END %]
END_TEMPLATE

    return \$template;
}

1;

=head1 SEE ALSO

L<RDF::YAML>, L<RDF::Simple::Parser::YAML>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
