package RDF::aREF::Encoder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.27';

use RDF::NS;
use RDF::aREF::Decoder qw(localName blankNodeIdentifier);
use Scalar::Util qw(blessed reftype);
use Carp qw(croak);

sub new {
    my ($class, %options) = @_;

    if (!defined $options{ns}) {
        $options{ns} = RDF::NS->new;
    } elsif (!$options{ns}) {
        $options{ns} = bless {
            rdf =>  'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
            owl =>  'http://www.w3.org/2002/07/owl#',
            xsd =>  'http://www.w3.org/2001/XMLSchema#',
        }, 'RDF::NS';
    } elsif ( !blessed $options{ns} or !$options{ns}->isa('RDF::NS') ) {
        $options{ns} = RDF::NS->new($options{ns});
    }

    $options{sn} = $options{ns}->REVERSE;
    $options{subject_map} = !!$options{subject_map};
    if ($options{NFC}) {
        eval { require Unicode::Normalize };
        croak "Missing Unicode::Normalize: NFC normalization disabled!\n" if $@;
    }

    bless \%options, $class;
}

sub qname {
    my ($self, $uri) = @_;
    return unless $self->{sn};
    my @qname = $self->{sn}->qname($uri);
    return $qname[0] if @qname == 1;
    return join('_',@qname) if @qname and $qname[1] =~ localName;
    return;
}

sub uri {
    my ($self, $uri) = @_;

    if ( my $qname = $self->qname($uri) ) {
        return $qname;
    } else {
        return "<$uri>";
    }
}

sub subject {
    my ($self, $subject) = @_;

    return do {
        if (!reftype $subject) {
            undef
        # RDF/JSON
        } elsif (reftype $subject eq 'HASH') {
            if ($subject->{type} eq 'uri' or $subject->{type} eq 'bnode') {
                $subject->{value}
            }
        # RDF::Trine::Node
        } elsif (reftype $subject eq 'ARRAY') { 
            if (@$subject == 2 ) {
                if ($subject->[0] eq 'URI') {
                    "".$subject->[1];
                } elsif ($subject->[0] eq 'BLANK') {
                    $self->bnode($subject->[1])
                }
            }
        }
    };
}

sub predicate {
    my ($self, $predicate) = @_;

    $predicate = do {
        if (!reftype $predicate) {
            undef
        # RDF/JSON
        } elsif (reftype $predicate eq 'HASH' and $predicate->{type} eq 'uri') {
            $predicate->{value}
        # RDF::Trine::Node
        } elsif (reftype $predicate eq 'ARRAY') { 
            (@$predicate == 2 and $predicate->[0] eq 'URI') 
                ? "".$predicate->[1] : undef;
        }
    };

    return do {
        if ( !defined $predicate ) {
            undef
        } elsif ( $predicate eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' ) {
            'a'
        } elsif ( my $qname = $self->qname($predicate) ) {
            $qname
        } else {
            $predicate
        }
    };
}

sub object {
    my ($self, $object) = @_;

    return do {
        if (!reftype $object) {
            undef
        # RDF/JSON
        } elsif (reftype $object eq 'HASH') {
            if ($object->{type} eq 'literal') {
                $self->literal( $object->{value}, $object->{lang}, $object->{datatype} )
            } elsif ($object->{type} eq 'bnode') {
                $object->{value}
            } else {
                $self->uri($object->{value})
            }
        # RDF::Trine::Node
        } elsif (reftype $object eq 'ARRAY') {
            if (@$object != 2 ) {
                $self->literal(@$object)
            } elsif ($object->[0] eq 'URI') {
                $self->uri("".$object->[1])
            } elsif ($object->[0] eq 'BLANK') {
                $self->bnode($object->[1])
            }
        }
    };
}

sub literal {
    my ($self, $value, $language, $datatype) = @_;
    if ($self->{NFC}) {
        $value = Unicode::Normalize::NFC($value);
    }
    if ($language) {
        $value.'@'.$language
    } elsif ($datatype and $datatype ne 'http://www.w3.org/2001/XMLSchema#string') {
        $value.'^'.$self->uri($datatype)
    } else {
        $value.'@'
    }
}

sub bnode {
    $_[1] =~ blankNodeIdentifier ? '_:'.$_[1] : undef;
}

sub triple {
    my ($self, $subject, $predicate, $object, $aref) = @_;
    
    $subject   = $self->subject($subject) // return;
    $predicate = $self->predicate($predicate) // return;
    $object    = $self->object($object) // return;
    $aref //= { };

   # empty
    if ( !keys %$aref and !$self->{subject_map} ) {
        $aref->{_id} = $subject;
        $aref->{$predicate} = $object;
    # predicate map
    } elsif ( $aref->{_id} ) {
        if ( $aref->{_id} eq $subject and !$self->{subject_map} ) {
            $self->_add_object_to_predicate_map( $aref, $predicate, $object );
        } else {
            # convert predicate map to subject map
            my $s = delete $aref->{_id};
            my $pm = { };
            foreach (keys %$aref) {
                $pm->{$_} = delete $aref->{$_};
            }
            if ($s eq $subject) {
                $self->_add_object_to_predicate_map( $pm, $predicate, $object ); 
            } else {
                $aref->{$subject} = { $predicate => $object };
            }
            $aref->{$s} = $pm;
        }
    } else { # subject map
        if ( $aref->{$subject} ) {
            $self->_add_object_to_predicate_map( $aref->{$subject}, $predicate, $object );
        } else {
            $aref->{$subject} = { $predicate => $object };
        }
    }

    return $aref;
}

sub _add_object_to_predicate_map {
    my ($self, $map, $predicate, $object) = @_;

    if (ref $map->{$predicate}) {
        push @{$map->{$predicate}}, $object;
    } elsif (defined $map->{$predicate}) {
        $map->{$predicate} = [ $map->{$predicate}, $object ];
    } else {
        $map->{$predicate} = $object;
    }
}

sub add_iterator {
    my ($self, $iterator, $aref) = @_;    
    while (my $s = $iterator->next) {
        $self->triple($s->subject, $s->predicate, $s->object, $aref);
    }
}
 
sub add_hashref {
    my ($self, $hashref, $aref) = @_;
 
    while (my ($s,$ps) = each %$hashref) {
        my $subject = $s =~ /^_:/ ? ['BLANK',substr($s, 2)] : ['URI',$s];
        foreach my $p (keys %$ps) {
            my $predicate = ['URI',$p];
            foreach my $object (@{ $hashref->{$s}->{$p} }) {
                $self->triple($subject, $predicate, $object, $aref);
            }
        }
    }
 
}

1;
__END__

=head1 NAME

RDF::aREF::Encoder - encode RDF to another RDF Encoding Form

=head1 SYNOPSIS

    use RDF::aREF::Encoder;
    my $encoder = RDF::aREF::Encoder->new;
    
    # encode parts of aREF

    my $qname  = $encoder->qname('http://schema.org/Review'); # 'schema_Review'


    my $predicate = $encoder->predicate({
        type  => 'uri',
        value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    }); # 'a'

    my $object = $encoder->object({
        type  => 'literal',
        value => 'hello, world!',
        lang  => 'en'
    }); # 'hello, world!@en'

    # method also accepts RDF::Trine::Node instances
    my $object = $encoder->object( RDF::Trine::Resource->new($iri) );

    # encode RDF graphs (see also function 'encode_aref' in RDF::aREF)
    use RDF::Trine::Parser;
    my $aref = { };
    RDF::Trine::Parser->parse_file ( $base_uri, $fh, sub {
        my $s = shift;
        $encoder->triple( $s->subject, $s->predicate, $s->object, $aref );
    } );

=head1 DESCRIPTION

This module provides methods to encode RDF data in another RDF Encoding Form
(aREF). As aREF was designed to facilitate creation of RDF data, it may be
easier to create aREF "by hand" instead of using this module!

=head1 OPTIONS

=head2 ns

A default namespace map, given as version string of module L<RDF::NS> for
stable qNames or as instance of L<RDF::NS>. The most recent installed version
of L<RDF::NS> is used by default. The value C<0> can be used to only use
required namespace mappings (rdf, rdfs, owl and xsd).

=head2 subject_map

By default RDF graphs with common subject are encoded as aREF predicate map:

   {
      _id => $subject, $predicate => $object
   }

Enable this option to always encode as aREF subject map:

   {
       $subject => { $predicate => $object }
   }

=head1 METHODS

Note that no syntax checking is applied, e.g. whether a given URI is a valid
URI or whether a given language is a valid language tag!

=head2 qname( $uri )

Abbreviate an URI as qName or return C<undef>. For instance
C<http://purl.org/dc/terms/title> is abbreviated to "C<dct_title>".

=head2 uri( $uri )

Abbreviate an URI or as qName or enclose it in angular brackets.

=head2 literal( $value, $language_tag, $datatype_uri )

Encode a literal RDF node by either appending "C<@>" and an optional
language tag, or "C<^>" and an datatype URI.

=head2 bnode( $identifier )

Encode a blank node by prepending "C<_:>" to its identifier.

=head2 subject( $subject )

=head2 predicate( $predicate )

=head2 object( $object )

Encode an RDF subject, predicate, or object respectively. The argument must
either be given as hash reference, as defined in
L<RDF/JSON|http://www.w3.org/TR/rdf-json/> format (see also method
C<as_hashref> of L<RDF::Trine::Model>), or as array reference as internally
used by L<RDF::Trine>.

A hash reference is expected to have the following fields:

=over

=item type

one of C<uri>, C<literal> or C<bnode> (required)

=item value

the URI of the object, its lexical value or a blank node label depending on
whether the object is a uri, literal or bnode

=item lang

the language of a literal value (optional but if supplied it must not be empty)

=item datatype

the datatype URI of the literal value (optional)

=back

An array reference is expected to consists of

=over

=item 

three elements (value, language tag, and datatype uri) for literal nodes,

=item 

two elements "C<URI>" and the URI for URI nodes,

=item

two elements "C<BLANK>" and the blank node identifier for blank nodes.

=back

=head2 triple( $subject, $predicate, $object, [, $aref ] )

Encode an RDF triple, its elements given as explained for method C<subject>,
C<predicate>, and C<object>. If an aREF data structure is given as fourth
argument, the triple is added to this structure, possibly changing an aREF
predicate map to an aRef subject map. Returns C<undef> on failure.

=head2 add_hashref( $aref, $rdf )
 
Add RDF given in L<RDF/JSON|http://www.w3.org/TR/rdf-json/> format (as returned
by method C<as_hashref> in L<RDF::Trine::Model>).

=head2 add_iterator( $aref, $iterator )
 
Add a L<RDF::Trine::Iterator> to an aREF subject map.
 
I<experimental>

=head1 SEE ALSO

L<RDF::aREF::Decoder>, L<RDF::Trine::Node>

=cut
