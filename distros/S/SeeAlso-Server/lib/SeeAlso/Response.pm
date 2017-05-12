use strict;
use warnings;
package SeeAlso::Response;
{
  $SeeAlso::Response::VERSION = '0.71';
}
#ABSTRACT: SeeAlso Simple Response

use JSON::XS qw(encode_json);
use Data::Validate::URI qw(is_uri);
use Text::CSV;
use SeeAlso::Identifier;
use Carp;

use overload ( 
    '""'   => sub { $_[0]->as_string },
    'bool' => sub { $_[0]->size or $_[0]->query }
);


sub new {
    my $this = shift;

    my $class = ref($this) || $this;
    my $self = bless {
        'labels' => [],
        'descriptions' => [],
        'uris' => []
    }, $class;

    $self->set( @_ );

    return $self;
}


sub set {
    my ($self, $query, $labels, $descriptions, $uris) = @_;

    $self->query( $query );

    if (defined $labels) {
        croak ("four parameters expected in SeeAlso::Response->new")
            unless ref($labels) eq "ARRAY"
                and defined $descriptions and ref($descriptions) eq "ARRAY"
                and defined $uris and ref($uris) eq "ARRAY";
        my $l = @{$labels};
        croak ("length of arguments to SeeAlso::Response->new differ")
            unless @{$descriptions} == $l and @{$uris} == $l;

        $self->{labels} = [];
        $self->{descriptions} = [];
        $self->{uris} = [];

        for (my $i=0; $i < @{$labels}; $i++) {
            $self->add($$labels[$i], $$descriptions[$i], $$uris[$i]);
        }
    }

    return $self;
}


sub add {
    my ($self, $label, $description, $uri) = @_;

    $label = defined $label ? "$label" : "";
    $description = defined $description ? "$description" : "";
    $uri = defined $uri ? "$uri" : "";
    if ( $uri ne "" ) {
      croak("irregular response URI") 
          unless $uri =~ /^[a-z][a-z0-9.+\-]*:/i;
    }

    return $self unless $label ne "" or $description ne "" or $uri ne "";

    push @{ $self->{labels} }, $label;
    push @{ $self->{descriptions} }, $description;
    push @{ $self->{uris} }, $uri;

    return $self;
}


sub size {
    my $self = shift;
    return scalar @{$self->{labels}};
}


sub get {
    my ($self, $index) = @_;
    return unless defined $index and $index >= 0 and $index < $self->size();

    my $label =       $self->{labels}->[$index];
    my $description = $self->{descriptions}->[$index];
    my $uri =         $self->{uris}->[$index];

    return ($label, $description, $uri);
}


sub query {
    my $self = shift;
    if ( scalar @_ ) {
        my $query = shift;
        $query = SeeAlso::Identifier->new( $query )
            unless UNIVERSAL::isa( $query, 'SeeAlso::Identifier' );
        $self->{query} = $query;
    }
    return $self->{query};
}


*identifier = *query;


sub labels {
    my $self = shift;
    return @{ $self->{labels} };
}


sub descriptions {
    my $self = shift;
    return ( @{ $self->{descriptions} } );
}


sub uris {
    my $self = shift;
    return @{ $self->{uris} };
}


sub toJSON {
    my ($self, $callback, $json) = @_;

    my $response = [
        $self->{query}->as_string,
        $self->{labels},
        $self->{descriptions},
        $self->{uris}
    ];

    return _JSON( $response, $callback, $json );
}


sub as_string {
    return $_[0]->toJSON;
}


sub fromJSON {
    my ($self, $jsonstring) = @_;
    my $json = JSON::XS->new->decode($jsonstring);

    croak("SeeAlso response format must be array of size 4")
        unless ref($json) eq "ARRAY" and @{$json} == 4;

    if (ref($self)) { # call as method
        $self->set( @{$json} );
        return $self;
    } else { # call as constructor
        return SeeAlso::Response->new( @{$json} );
    }
}


sub toCSV {
    my ($self, $headers) = @_;
    my $csv = Text::CSV->new( { binary => 1, always_quote => 1 } );
    my @lines;
    for(my $i=0; $i<$self->size(); $i++) {
        my $status = $csv->combine ( $self->get($i) ); # TODO: handle error status
        push @lines, $csv->string();
    }
    return join ("\n", @lines);
}


sub toBEACON {
    my ($self, $beacon) = @_;
    my @lines;
    my $query = $self->query;
    $query =~ s/[|\n]//g;

    #$this->meta('TARGET')

    for(my $i=0; $i<$self->size(); $i++) {
        ## no critic
        my ($label, $description, $url) = map { s/[|\n]//g; $_; } $self->get($i);
        ## use critic
        my @line = ($query);

        # TODO: remove url, if #TARGET is given

        if ( is_uri( $url ) ) { # may skip label/description
            push @line, $label unless $label eq "" and $description eq "";
            push @line, $description unless $description eq "";
            push @line, $url;
        } else { # no uri
        #if ($url eq "") {
            # TODO: add only if no empty
            push @line, $label;
        #} else {
           # TODO
          # push @line, $label, $description, $url;
            push @line, $description unless $description eq "" and $url eq "";
            push @line, $url unless $url eq "";
        }
        #if ($label != "")
        push @lines, join('|',@line);
    }
    return join ("\n", @lines);
}
 

sub toRDF {
    my ($self) = @_;
    my $subject = $self->query;
    return { } unless is_uri( $subject->as_string );
    my $values = { };

    for(my $i=0; $i<$self->size(); $i++) {
        my ($label, $predicate, $object) = $self->get($i);
        next unless is_uri($predicate); # TODO: use rdfs:label as default?

        if ($object) {
            next unless is_uri($object);
            $object = { "value" => $object, 'type' => 'uri' };
        } else {
            $object = { "value" => $label, 'type' => 'literal' };
        }

        if ($values->{$predicate}) {
            push @{ $values->{$predicate} }, $object;
        } else {
            $values->{$predicate} = [ $object ];
        }
    }

    return {
        $subject => $values
    };
}


sub toRDFJSON {
    my ($self, $callback, $json) = @_;
    return _JSON( $self->toRDF, $callback, $json );
}


sub toRDFXML {
    my ($self) = @_;
    my ($subject, $values) = %{$self->toRDF};

    my @xml = ('<?xml version="1.0" encoding="UTF-8"?>');
    # TODO: $subject => $values
    push @xml, '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">';
    push @xml, '<rdf:Description rdf:about="' . _escape($subject) . '">';
    foreach my $predicate (%{$values}) {
        # TODO
        # <ex:prop rdf:resource="fruit/apple"/>
        # <ex:prop>$literal</ex:prop>
    }
    push @xml, '</rdf:Description>';
    push @xml, '</rdf:RDF>';

    return join("\n", @xml) . "\n";
}


sub toN3 {
    my ($self) = @_;
    return "" unless $self->size();
    my $rdf = $self->toRDF();
    my ($subject, $values) = %$rdf;
    return "" unless $subject && %$values;
    my @lines;

    foreach my $predicate (keys %$values) {
        my @objects = @{$values->{$predicate}};
        if ($predicate eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type') {
            $predicate = 'a';
        } elsif ($predicate eq 'http://www.w3.org/2002/07/owl#sameAs') {
            $predicate = '=';
        } else {
            $predicate =  "<$predicate>";
        }
        @objects = map {
            my $object = $_;
            if ($object->{type} eq 'uri') {
                '<' . $object->{value} . '>';
            } else {
                _escape( $object->{value} );
            }
        } @objects;
        if (@objects > 1) {  
            push @lines, (" $predicate\n    " . join(" ,\n    ", @objects) );
        } else {
            push @lines, " $predicate " . $objects[0];
        }
    }

    my $n3 = "<$subject>";
    if (@lines > 1) {
        return "$n3\n " . join(" ;\n ",@lines) . " .";
    } else {
        return $n3 . $lines[0] . " .";
    }
}


sub toRedirect {
    my ($self, $default) = @_;
    my ($a,$b,$url) = $self->get(0);
    $url = $default unless $url;
    return unless $url;

    return <<HTTP;
Status: 302 Found
Location: $url
URI: <$url>
Content-type: text/html

<html><head><meta http-equiv='refresh' content='0; URL=$url'></head></html>
HTTP
}


my %ESCAPED = ( 
    "\t" => 't', 
    "\n" => 'n', 
    "\r" => 'r', 
    "\"" => '"',
    "\\" => '\\', 
);
 

sub _escape {
    local $_ = $_[0];
    s/([\t\n\r\"\\])/\\$ESCAPED{$1}/sg;
    return '"' . $_  . '"';
}


sub _JSON {
    my ($object, $callback, $JSON) = @_;

    croak ("Invalid callback name")
        if ( $callback and !($callback =~ /^[a-z][a-z0-9._\[\]]*$/i));

    # TODO: change this behaviour (no UTF-8) ?
    $JSON = JSON::XS->new->utf8(0) unless $JSON;

    my $jsonstring = $JSON->encode($object); 

    return $callback ? "$callback($jsonstring);" : $jsonstring;
}

1;

__END__
=pod

=head1 NAME

SeeAlso::Response - SeeAlso Simple Response

=head1 VERSION

version 0.71

=head1 DESCRIPTION

This class models a SeeAlso Simple Response, which is practically the
same as am OpenSearch Suggestions Response. It consists of a query
term, and a list of responses, which each have a label, a description,
and an URI.

=head1 METHODS

=head2 new ( [ $query [, $labels, $descriptions, $uris ] )

Creates a new L<SeeAlso::Response> object (this is the same as an
OpenSearch Suggestions Response object). The optional parameters
are passed to the set method, so this is equivalent:

  $r = SeeAlso::Response->new($query, $labels, $descriptions, $uris);
  $r = SeeAlso::Response->new->set($query, $labels, $descriptions, $uris);

To create a SeeAlso::Response from JSON use the fromJSON method.

=head2 set ( [ $query [, $labels, $descriptions, $uris ] )

Set the query parameter or the full content of this response. If the
query parameter is an instance of L<SeeAlso::Identifier>, the return
of its C<normalized> method is used. This methods croaks if the passed
parameters do not fit to a SeeAlso response.

=head2 add ( $label [, $description [, $uri ] ] )

Add an item to the result set. All parameters are stringified.
The URI is only partly checked for well-formedness, so it is 
recommended to use a specific URI class like C<URI> and pass 
a normalized version of the URI:

  $uri = URI->new( $uri_str )->canonical

Otherwise your SeeAlso response may be invalid. If you pass a 
non-empty URI without schema, this method will croak. If label,
description, and uri are all empty, nothing is added.

Returns the SeeAlso::Response object so you can chain method calls.

=head2 size

Get the number of entries in this response.

=head2 get ( $index )

Get a specific triple of label, description, and uri
(starting with index 0):

  ($label, $description, $uri) = $response->get( $index )

=head2 query ( [ $identifier ] )

Get and/or set query parameter which must be or will converted to a 
L<SeeAlso::Identifier> object.

=head2 identifier

Alias for the query method.

=head2 labels

Return an array of all labels in this response.

=head2 descriptions

Return an array of all descriptions in this response.

=head2 descriptions

Return an array of all descriptions in this response.

=head2 toJSON ( [ $callback [, $json ] ] )

Return the response in JSON format and a non-mandatory callback wrapped
around. The method will croak if you supply a callback name that does
not match C<^[a-z][a-z0-9._\[\]]*$>.

The encoding is not changed, so please only feed response objects with
UTF-8 strings to get JSON in UTF-8. Optionally you can pass a L<JSON>
object to do JSON encoding of your choice.

=head2 as_string 

Returns a string representation of the response with is the default JSON 
form as returned by the toJSON method. Responses are also converted to 
plain strings automatically by overloading. This means you can use responses
as plain strings in most Perl constructs.

=head2 fromJSON ( $jsonstring )

Set this response by parsing JSON format. Croaks if the JSON string 
does not fit SeeAlso response format. You can use this method as
as constructor or as method;

  my $response = SeeAlso::Response->fromJSON( $jsonstring );
  $response->fromJSON( $jsonstring )

=head2 toCSV ( )

Returns the response in CSV format with one label, description, uri triple
per line. The response query is omitted. Please note that newlines in values
are allowed so better use a clever CSV parser!

=head2 toBEACON ( [ $beacon ] )

Returns the response in BEACON format. The response is analyzed to get the most
compact form. You should add L<SeeAlso::Beacon> object that stores meta information 
about a Beacon for further abbreviations. 

Vertical bars in any of the responses values are silently removed.

=head2 toRDF

Returns the response as RDF triples in JSON/RDF structure.
Parts of the result that cannot be interpreted as valid RDF are omitted.

=head2 toRDFJSON

Returns the response as RDF triples in JSON/RDF format.

=head2 toRDFXML

Returns the response as RDF triples in XML/RDF format (not implemented yet).

=head2 toN3

Return the repsonse in RDF/N3 (including pretty print).

=head2 toRedirect ( [ $default ] )

Return a HTTP 302 redirect to the first repsonse's link or a default location.

=head1 INTERNAL FUNCTIONS

=head2 _escape ( $string )

Escape a specific characters in a UTF-8 string for Turtle syntax / Notation 3

=head2 _JSON ( $object [, $callback [, $JSON ] ] )

Encode an object as JSON string, possibly wrapped by callback method.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

