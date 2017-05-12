package RDF::DOAP::Types;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Type::Utils -all;
use Type::Library -base;
use Types::TypeTiny qw(StringLike);

BEGIN { extends 'Types::Standard' };

declare 'Identifier',
	as InstanceOf["RDF::Trine::Node"];

coerce 'Identifier',
	from Str, q{ /^_:(.+)$/ ? 'RDF::Trine::Node::Blank'->new($1) : 'RDF::Trine::Node::Resource'->new($_) },
	from HasMethods['rdf_about'], q{ $_->rdf_about },
	from StringLike, q{ /^_:(.+)$/ ? 'RDF::Trine::Node::Blank'->new("$1") : 'RDF::Trine::Node::Resource'->new("$_") };

declare 'String',
	as Str;

coerce 'String',
	from InstanceOf["RDF::Trine::Node::Literal"], q{ $_->literal_value },
	from StringLike, q{"$_"};

class_type 'Model', { class => 'RDF::Trine::Model' };

for my $class (qw/ Project Version Change ChangeSet Person Issue Repository /)
{
	declare $class,
		as InstanceOf[ "RDF::DOAP::$class" ];
	coerce $class,
		from 'Identifier', qq{ "RDF::DOAP::$class"->rdf_load(\$_) };
}

1;
