package MooseX::Semantic::Types;
use strict;
use URI;
use RDF::Trine qw(iri);
use RDF::Trine::Namespace qw(xsd);
use MooseX::Types -declare => [qw( 
    TrineNode
    TrineBlank
    TrineResource 
    TrineModel
    TrineLiteral
    TrineStore

    TrineLiteralOrTrineResorce
    TrineBlankOrUndef 

    ArrayOfTrineResources
    ArrayOfTrineNodes
    ArrayOfTrineLiterals

    HashOfTrineResources
    HashOfTrineNodes
    HashOfTrineLiterals
    CPAN_URI
    UriStr
    )];
use MooseX::Types::URI Uri => { -as => 'MooseX__Types__URI__Uri' };
use MooseX::Types::Moose qw{:all};
use MooseX::Types::Path::Class qw{File Dir};

class_type TrineResource, { class => 'RDF::Trine::Node::Resource' };
subtype ArrayOfTrineResources, as ArrayRef[TrineResource];
subtype HashOfTrineResources, as HashRef[TrineResource];
class_type TrineBlank, { class => 'RDF::Trine::Node::Blank' };
subtype TrineBlankOrUndef, as Maybe[TrineBlank];
class_type TrineLiteral, { class => 'RDF::Trine::Node::Literal' };
subtype ArrayOfTrineLiterals, as ArrayRef[TrineLiteral];
subtype HashOfTrineLiterals, as HashRef[TrineLiteral];
subtype TrineNode, as Object, where {$_->isa('RDF::Trine::Node::Blank') || $_->isa('RDF::Trine::Node::Resource')};
subtype ArrayOfTrineNodes, as ArrayRef[TrineNode];
subtype HashOfTrineNodes, as HashRef[TrineNode];
subtype UriStr, as Str;
class_type TrineModel, { class => 'RDF::Trine::Model' };
class_type TrineStore, { class => 'RDF::Trine::Store' };


class_type CPAN_URI, { class => 'URI' };
# coerce( CPAN_URI,
#     from Str, via { if (/^[a-z]+:/) { URI->new($_) },
# );

coerce( TrineBlankOrUndef,
    from Bool, via { return undef unless $_; RDF::Trine::Node::Blank->new },
);

coerce( TrineLiteral,
    from Int, via { RDF::Trine::Node::Literal->new($_, undef, $xsd->int); },
    from Bool, via { RDF::Trine::Node::Literal->new($_, undef, $xsd->boolean); },
    from Num, via { RDF::Trine::Node::Literal->new($_, undef, $xsd->numeric); },
    from Str, via { RDF::Trine::Node::Literal->new($_, undef, $xsd->string); },
    from Value, via { RDF::Trine::Node::Literal->new($_); },
);
coerce( ArrayOfTrineLiterals,
    from ArrayRef, via { my $u = $_; [map {TrineLiteral->coerce($_)} @$u] },
);


for (File, Dir, ScalarRef, HashRef, "Path::Class::File", "Path::Class::Dir"){
    coerce TrineResource,
        from $_,
            via { iri( MooseX__Types__URI__Uri->coerce( $_ ) ) };
};
coerce (TrineResource,
    from Str, via { iri( $_ ) },
    from CPAN_URI, via { iri( $_->as_string ) },
);

coerce( ArrayOfTrineResources,
    # from Str, via { [ TrineResource->coerce( $_ ) ] },
    from TrineResource, via { [ $_ ] },
    from ArrayRef, via { my $u = $_; [map {TrineResource->coerce($_)} @$u] },
    from Value, via { [ TrineResource->coerce( $_ ) ] },
);

coerce (TrineNode,
    from TrineBlank, via { $_ },
    from TrineResource, via { $_ },
    from Defined, via {TrineResource->coerce( $_ )},
);

coerce (UriStr,
    from Defined, via { TrineResource->coerce( $_)->uri },
);

coerce( TrineModel,
    from Undef, via { RDF::Trine::Model->temporary_model },
    from UriStr, via { 
        my $m = TrineModel->coerce;
        RDF::Trine::Parser->parse_url_into_model( $_, $m );
        return $m;
    },
);

coerce( TrineStore,
    from Undef, via { RDF::Trine::Store->temporary_store },
    from Defined, via { RDF::Trine::Store->new ( $_ ) },
);


1;
