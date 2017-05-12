package SVG::Parser::SAX::Handler;
use strict;
use vars qw(@ISA $VERSION);

require 5.004;

use base qw(XML::SAX::Base SVG::Parser::Base);
use SVG::Parser::Base;
use SVG 2.0;

$VERSION="1.03";

#-------------------------------------------------------------------------------

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my %attrs=@_;

    # pass on non-minus-prefixed attributes to handler
    my %handler_attrs;
    foreach (keys %attrs) {
        $handler_attrs{$_}=delete $attrs{$_} unless /^-/;
    }

    my $self=$class->SUPER::new(%handler_attrs);

    # minus-prefixed attributes stay here, double-minus to SVG object
    foreach (keys %attrs) {
        if (/^-(-.+)$/) {
            $self->{__svg_attr}{$1}=$attrs{$_};
        } else {
            $self->{$_}=$attrs{$_};
        }
    } 

    return $self;
}

#-------------------------------------------------------------------------------

sub start_document {
    my ($self,$document)=@_;
    return $self->SVG::Parser::Base::StartDocument();
}

sub start_element {
    my ($self,$element)=@_;

    my $name=$element->{Name};
    my %attrs=map {
	$element->{Attributes}{$_}{Name} => $element->{Attributes}{$_}{Value}
    } keys %{$element->{Attributes}};

    $self->SVG::Parser::Base::StartTag($name,%attrs);
}

sub end_element {
    my ($self,$element)=@_;
    return $self->SVG::Parser::Base::EndTag($element);
}

sub characters {
    my ($self,$text)=@_;
    return $self->SVG::Parser::Base::Text($text->{Data});
}

sub start_cdata {
    my $self=shift;
    return $self->SVG::Parser::Base::CdataStart();
}

sub end_cdata {
    my $self=shift;
    return $self->SVG::Parser::Base::CdataEnd();
}

sub processing_instruction {
    my ($self,$pi)=@_;
    return $self->SVG::Parser::Base::PI(
        $pi->{Target},
        $pi->{Data}
    );
}

sub comment {
    my ($self,$comment)=@_;
    return $self->SVG::Parser::Base::Comment($comment->{Data});
}

sub end_document {
    my ($self,$document)=@_;
    return $self->SVG::Parser::Base::FinishDocument();
}

#-------------------------------------------------------------------------------

# handle XML declaration, if present
sub xml_decl {
    my ($self,$decl)=@_;

    $self->SVG::Parser::Base::XMLDecl(
        $decl->{Version},
        $decl->{Encoding},
        $decl->{Standalone}
    );
}

# handle Doctype declaration, if present (and if parser handles it)
sub doctype_decl {
    my ($self,$dtd)=@_;

    $self->SVG::Parser::Base::Doctype(
        $dtd->{Name},
        $dtd->{SystemId},
        $dtd->{PublicId},
        $dtd->{Internal}
    );
}

#-------------------------------------------------------------------------------

sub entity_decl {
    my ($self,$edecl)=@_;

    if (defined $edecl->{Notation}) {
        # unparsed entity decl
        $self->SVG::Parser::Base::Unparsed(
            $edecl->{Name},
            $edecl->{Value},
            $edecl->{SystemID},
            $edecl->{PublicID},
            $edecl->{Notation},
            0,
        );
    } else {
        # internal/external entity decl
        my $isp=0;
        if (defined $edecl->{Name}) {
            $isp=1 if $edecl->{Name} =~ s/^%//;
        }
    
        $self->SVG::Parser::Base::Entity(
            $edecl->{Name},
            $edecl->{Value},
            $edecl->{SystemID},
            $edecl->{PublicID},
            $edecl->{Notation},
            $isp
        );
    }
}

sub notation_decl { 
    my ($self,$ndecl)=@_;

    $self->SVG::Parser::Base::Notation(
        $ndecl->{Name},
        $ndecl->{Base},
        $ndecl->{SystemID},
        $ndecl->{PublicID},
    );
}

sub element_decl {
    my ($self,$edecl)=@_;

    $self->SVG::Parser::Base::Element(
        $edecl->{Name},
        $edecl->{Model}
    );
}

sub attribute_decl {
    my ($self,$adecl)=@_;

    $self->SVG::Parser::Base::Attlist(
        $adecl->{eName},
        $adecl->{aName},
        $adecl->{Type},
        (defined($adecl->{Value}) ? $adecl->{Value} : $adecl->{Mode}),
        ((defined($adecl->{Mode}) and $adecl->{Mode} eq '#FIXED')?1:0),
    );
}

#-------------------------------------------------------------------------------

=head1 NAME

SVG::Parser::SAX::Handler - SAX handler class for SVG documents

=head1 DESCRIPTION

This module provides the handlers for constructing an SVG document object when
using SVG::Parser::SAX. See L<SVG::Parser::SAX> for more information.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG::Parser>, L<SVG::Parser::SAX>

=cut

1;
