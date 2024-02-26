package RDF::Cowl::Lib::Types;
# ABSTRACT: Type library
$RDF::Cowl::Lib::Types::VERSION = '1.0.0';
use strict;
use warnings;

use Const::Fast;
const our @_CLASS_SUFFIXES => qw(
	Error

	PrimitiveFlags
	StringOpts

	OntologyId
	OntologyHeader

	ErrorHandler
	ImportLoader
	IStreamHandlers
	StreamWriter
	Reader
	Writer
	Iterator

	AnnotValueType
	AxiomType
	CardType
	CharAxiomType
	ClsExpType
	DataRangeType
	EntityType
	NAryAxiomType
	NAryType
	ObjectType
	PrimitiveType
	QuantType

	IStream
	OStream

	XSDVocab
	RDFVocab
	RDFSVocab
	OWLVocab

	Object

	AnnotAssertAxiom
	Annotation
	AnnotProp
	AnnotPropDomainAxiom
	AnnotPropRangeAxiom
	AnnotValue
	AnonInd
	Axiom
	Class
	ClsAssertAxiom
	ClsExp
	DataCard
	DataCompl
	DataHasValue
	DataOneOf
	DataProp
	DataPropAssertAxiom
	DataPropDomainAxiom
	DataPropExp
	DataPropRangeAxiom
	DataQuant
	DataRange
	Datatype
	DatatypeDefAxiom
	DatatypeRestr
	DeclAxiom
	DisjUnionAxiom
	Entity
	FacetRestr
	FuncDataPropAxiom
	HasKeyAxiom
	Individual
	InvObjProp
	InvObjPropAxiom
	IRI
	Literal
	Manager
	NamedInd
	NAryBool
	NAryClsAxiom
	NAryData
	NAryDataPropAxiom
	NAryIndAxiom
	NAryObjPropAxiom
	ObjCard
	ObjCompl
	ObjHasSelf
	ObjHasValue
	ObjOneOf
	ObjProp
	ObjPropAssertAxiom
	ObjPropCharAxiom
	ObjPropDomainAxiom
	ObjPropExp
	ObjPropRangeAxiom
	ObjQuant
	Ontology
	Primitive
	String
	SubAnnotPropAxiom
	SubClsAxiom
	SubDataPropAxiom
	SubObjPropAxiom
	SymTable
	Table
	Vector
);

use Type::Library 0.008 -base,
	-declare => [
		( map { "Cowl$_" } @_CLASS_SUFFIXES  ),
		qw(
			CowlAny
			CowlAnyAnnotValue
			CowlAnyAxiom
			CowlAnyClsExp
			CowlAnyDataPropExp
			CowlAnyDataRange
			CowlAnyEntity
			CowlAnyIndividual
			CowlAnyPrimitive
			CowlAnyObjPropExp
		),
		qw(
			Ulib_uint

			UIStream
			UOStream
			UStrBuf
                ),
	];
use Type::Utils -all;
use Types::Common qw(Any PositiveOrZeroInt Str CodeRef ArrayRef InstanceOf);

# enums
for my $suffix ( grep { $_ =~ /Type$/ } @_CLASS_SUFFIXES ) {
	declare "Cowl${suffix}", as PositiveOrZeroInt;
}

# non-enums
for my $suffix ( grep { $_ !~ /Type$/ } @_CLASS_SUFFIXES ) {
	class_type "Cowl${suffix}" => { class => "RDF::Cowl::${suffix}" };
}

coerce 'CowlString',
	from Str,
	q {
		RDF::Cowl::String->new( RDF::Cowl::Ulib::UString->new( $_ ), RDF::Cowl::StringOpts::COPY )
	};

coerce 'CowlIterator',
	from CodeRef,
	q {
		RDF::Cowl::Iterator->new( $_ )
	};

coerce 'CowlVector',
	from ArrayRef[InstanceOf['RDF::Cowl::Object']],
	q {
		do {
			my $ar = $_;
			my $uvec = RDF::Cowl::Ulib::UVec_CowlObjectPtr->new;
			$uvec->push($_) for @$ar;
			RDF::Cowl::Vector->new($uvec);
		}
	};


class_type 'UString'               => { class => 'RDF::Cowl::Ulib::UString'               };

coerce 'UString',
	from Str,
	q {
		RDF::Cowl::Ulib::UString->new($_)
	};


class_type "CowlObjectPtr"         => { class => "RDF::Cowl::Object"                      };
class_type 'UVec_CowlObjectPtr'    => { class => 'RDF::Cowl::Ulib::UVec_CowlObjectPtr'    };

coerce 'UVec_CowlObjectPtr',
	from ArrayRef[InstanceOf['RDF::Cowl::Object']],
	q {
		do {
			my $ar = $_;
			my $uvec = RDF::Cowl::Ulib::UVec_CowlObjectPtr->new;
			$uvec->push($_) for @$ar;
			$uvec;
		}
	};

class_type 'UHash_CowlObjectTable' => { class => 'RDF::Cowl::Ulib::UHash_CowlObjectTable' };


class_type "CowlAny"            =>  { class => "RDF::Cowl::Object"      } ;
class_type "CowlAnyAnnotValue"  =>  { class => "RDF::Cowl::AnnotValue"  } ;
class_type "CowlAnyAxiom"       =>  { class => "RDF::Cowl::Axiom"       } ;
class_type "CowlAnyClsExp"      =>  { class => "RDF::Cowl::ClsExp"      } ;
class_type "CowlAnyDataPropExp" =>  { class => "RDF::Cowl::DataPropExp" } ;
class_type "CowlAnyDataRange"   =>  { class => "RDF::Cowl::DataRange"   } ;
class_type "CowlAnyEntity"      =>  { class => "RDF::Cowl::Entity"      } ;
class_type "CowlAnyIndividual"  =>  { class => "RDF::Cowl::Individual"  } ;
class_type "CowlAnyPrimitive"   =>  { class => "RDF::Cowl::Primitive"   } ;
class_type "CowlAnyObjPropExp"  =>  { class => "RDF::Cowl::ObjPropExp"  } ;

declare "Ulib_uint", as PositiveOrZeroInt;

declare "UIStream", as Any;
class_type "UOStream"  =>  { class => "RDF::Cowl::Ulib::UOStream"  } ;
declare "UStrBuf", as Any;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Types - Type library

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
