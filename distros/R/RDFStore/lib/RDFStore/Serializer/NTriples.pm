# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - Tue Jan 28 15:30:00 CET 2003
# *

package RDFStore::Serializer::NTriples;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use Carp;

use RDFStore::Serializer;
use RDFStore;

@RDFStore::Serializer::NTriples::ISA = qw( RDFStore::Serializer );

sub new {
	my ($pkg) = shift;

	my $self = $pkg->SUPER::new(@_);

	bless $self,$pkg;
	};

sub write {
	my ($class, $model, $fh, $namespaces ) = @_;

	$model = $class->{'model'}
                unless($model);

	# init
	$class->SUPER::write( $model, $fh, $namespaces );

	my $itr = $model->elements;
	while ( my $st = $itr->each ) {
		$class->printContent( $st->toString . "\n" );
                };

        return $class->returnContent;
	};

1;
};

__END__

=head1 NAME

RDFStore::Serilizer::NTriples - Serialise a model/graph to W3C RDF Test Cases N-Triples syntax

=head1 SYNOPSIS

	use RDFStore::Serializer::NTriples;

        my $model= new RDFStore::Model();
        $model->add($statement);
        $model->add($statement1);
        $model->add($statement2);

        my $serializer = new RDFStore::Serializer::NTriples;
        my $rdf_strawman = $serializer->serialize( $model ); # serialise model to a string in-memory

        $serializer->serialize( $model, *STREAM ); # serialise model to a given descriptor (stream)

=head1 DESCRIPTION

An RDFStore::Model serializer to W3C RDF Test Cases N-Triples syntax - see http://www.w3.org/TR/rdf-testcases/#ntriples

=head1 CONSTRUCTORS
 
The following methods construct RDFStore::Serializer::NTriples :

=item new ()

 Create an new RDFStore::Serializer object to serialize and RDFStore::Model.

=head1 METHODS

=item write ( MODEL [ , FILEHANDLE_REF, NAMESPACES, BASE ] )

 Write out the given MODEL to FILEHANDLE_REF (or in-memory string if not passed) using a given list of NAMESPACES and xml:base BASE if passed. The NAMESPACES hash ref contains a list of namespace values (URI refs) and prefix names - see RDFStore::Vocabulary::Generator(3). By default the output is returned from the method into a string otheriwse a valid (and opened) FILEHANLDE_REF can be passed, which will be being printed to.

=item serialize ( MODEL [ , FILEHANDLE_REF, NAMESPACES, BASE ] )

 Same as write method above.

=head1 SEE ALSO

 RDFStore::Model(3) RDFStore::Serializer(3)

 http://www.w3.org/TR/rdf-testcases/#ntriples

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
