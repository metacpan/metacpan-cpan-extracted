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
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - added more magic keywords to 'reservedWords' list
# *             - Modified createResource() accordingly to rdf-api-2000-10-30
# *     version 0.3
# *		- fixed bug in toPerlName() and dumpVocabulary() avoid grep regex checking
# *		- fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- fixed bug in dumpVocabulary() when matching input namespace (escape plus signs)
# *		  and output full qualified package variable names of voc properties
# *		- fixed bug in createVocabulary() when check package name
# *		- fixed miss-spelling bug in toPerlName()
# *             - fixed a few warnings
# *		- updated accordingly to new RDFStore::Model
# *	version 0.41
# *		- updated to use RDFStore::Model new API
# *

package RDFStore::Vocabulary::Generator;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.41';
use Carp;

#bit funny Sergey assuems that we have already these pre-generated....
use RDFStore::Vocabulary::RDFS;
use RDFStore::Vocabulary::DC;
use RDFStore::Vocabulary::DAML;

sub new {
	my ($pkg) = @_;

    	my $self = {};

	$self->{LICENSE} = qq|# *
# *     Copyright (c) 2000-2004 Alberto Reggiori <areggiori\@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx\@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
|;
	$self->{DEFAULT_PACKAGE_CLASS} = "UnspecifiedClass";
	$self->{NS_IMPORT} = "use RDFStore::Model;\nuse Carp;\n";
	$self->{DEFAULT_NODE_FACTORY} = "RDFStore::NodeFactory";
	$self->{NS_COMMENT} = "# \n" .
		"# This package provides convenient access to schema information.\n".
		"# DO NOT MODIFY THIS FILE.\n".
		"# It was generated automatically by RDFStore::Vocabulary::Generator\n#\n";
	$self->{NS_NSDEF} = "# Namespace URI of this schema";
	$self->{NS_ID} = "_Namespace";

	# some obvious reserved words
	$self->{reservedWords}=["package","use","require","BEGIN","END","sub","my","local",$self->{NS_ID}];

    	bless $self,$pkg;
};

# Schema as input parameter
# createVocabulary($packageClass, $all, $namespace, $outputDirectory, $factoryStr)
sub createVocabulary {
	croak "Model ".$_[2]." is not an instance of RDFStore::Model"
		unless( (defined $_[2]) &&
                	(ref($_[2])) && ($_[2]->isa("RDFStore::Model")) );

	my $packageName = '';
	my $className = '';

	$_[5] = $_[0]->{DEFAULT_NODE_FACTORY}
		unless(defined $_[5]);

	if($_[1] =~ /::/) {
		my @info = split("::",$_[1]);
		$className = pop @info;
		$packageName = join("::",@info);
	} else {
		$packageName = $_[1];
		$className = $packageName;
	};

	print "Creating interface " . $className . " within package ". $packageName .  ( (defined $_[4]) ? " in ". $_[4] : ""),"\n";

	my $packageDirectory;
	if(!(defined $_[4])) {
		$packageDirectory=undef;
	} else {
		$packageName = ""
			if(!(defined $packageName));

		croak "Invalid output directory: ".$_[4]
			unless(-d $_[4]);

		#make it
		$packageDirectory = $packageName;
		$packageDirectory = ''
			unless($packageDirectory =~ s/\:\:/\//g);
		$packageDirectory = $_[4].$packageDirectory;
		`mkdir -p $packageDirectory`;
	};
    
	my $out;
	if( defined $_[4] ) {
		open(OUT,">".$packageDirectory."/".$className.".pm");
		$out=*OUT;
	} else {
		$out = *STDOUT;
	};

	$_[0]->dumpVocabulary( $out, ($packageName eq $className) ? $packageName : $packageName.'::'.$className , $className, $_[2], $_[3], $_[5] );
	close($out);
};

sub toPerlName {
	my $reserved=0;
	map { $reserved=1 if($_ eq $_[1]); } @{$_[0]->{reservedWords}};
	return "_".$_[1]
		if($reserved);

	$_[1] =~ s/[\+\-\.]/_/g;
	$_[1] =~ s/^\d(.*)/_$1/g;
	return $_[1];
};

sub dumpVocabulary {
	my @els;
	my ($ee) = $_[4]->elements;
	for ( my $e = $ee->first; $ee->hasnext; $e= $ee->next ) {
		push @els,$e->subject();
		push @els,$e->object()
			if($e->object->isa("RDFStore::Resource"));
	};

	# write resource declarations and definitions
        my $r1;
        my @v1;
        my @pname;
        my $ns_match = $_[5];
        $ns_match =~ s/\+/\\\+/g;
        foreach $r1 ( @els ) {
                my $res = $r1->toString();
                if($res =~ /^$ns_match/) {
                        my $name=substr($res,length($_[5]));
                        if(length($name) > 0) { #NS already included as a string
                                my $isthere=0;
                                map { $isthere=1 if($_ eq $name); } @v1;
                                unless($isthere) {
					push @v1,$name;
        				push @pname,'$'.$_[0]->toPerlName($name);
				};
                	};
        	};
        };

	my $out=$_[1]; 
	print $out $_[0]->{LICENSE},"\n";
	print $out "package ".$_[2].";\n{\n";
	print $out "use vars qw ( \$VERSION ".join(" ",@pname)." );\n\$VERSION='$VERSION';\nuse strict;\n";
	print $out $_[0]->{NS_IMPORT},"\n";
	print $out $_[0]->{NS_COMMENT},"\n";
	print $out $_[0]->{NS_NSDEF},"\n";
	print $out '$'.$_[2].'::'.$_[0]->{NS_ID}.'= "'.$_[5].'";'."\n";
	print $out "use $_[6];\n";
	print $out '&setNodeFactory(new '.$_[6]."());\n";

	print $out '
sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($'.$_[2].'::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
';


	# write resource declarations and definitions
        my $r;
        my @v;
        #my $ns_match = $_[5];
        #$ns_match =~ s/\+/\\\+/g;
	my $destructors='';
	foreach $r ( @els ) {
		my $res = $r->toString();
		if($res =~ /^$ns_match/) {
			my $name=substr($res,length($_[5]));
			if(length($name) > 0) { #NS already included as a string
				my $isthere=0;
				map { $isthere=1 if($_ eq $name); } @v;
				unless($isthere) {
					push @v,$name;
					my $pname = $_[0]->toPerlName($name);
					# comment?
					my $tComment = $_[4]->find($r, $RDFStore::Vocabulary::RDFS::comment, undef )->elements->first;
					$tComment= $_[4]->find($r, $RDFStore::Vocabulary::DAML::comment, undef )->elements->first
						unless(	(defined $tComment) &&
							(ref($tComment)) &&
							($tComment->isa("RDFStore::Statement")) );
					$tComment = $_[4]->find($r, $RDFStore::Vocabulary::DC::description, undef )->elements->first
						unless(	(defined $tComment) &&
							(ref($tComment)) &&
							($tComment->isa("RDFStore::Statement")) );
					if(defined $tComment) {
						$tComment = $tComment->object->toString;
						$tComment =~ s/\s/ /g;
						print $out "\t# $tComment\n";
          				};
					print $out "\t\$$_[2]::".$pname.' = createResource($_[0], "'.$name."\");\n";
					$destructors .= "\t\$$_[2]::".$pname." = undef;\n";
				};
          		};
        	};
        };
	print $out "};\n";
	print $out "sub END {\n";
	print $out $destructors;
	print $out "};\n1;\n};";
};

1;
};

__END__

=head1 NAME

RDFStore::Vocabulary::Generator - implementation of the Vocabulary Generator RDF API

=head1 SYNOPSIS

 use RDFStore::Vocabulary::Generator;
my $generator = new RDFStore::Vocabulary::Generator();
# see vocabulary-generator.pl
$generator->createVocabulary($packageClass, $all, $namespace, $outputDirectory, $factoryStr);

=head1 DESCRIPTION

Generate Perl package with constants for resources defined in an RDF (Schema).


=head1 METHODS

=over 

=item B<new()>
 

 This is the constructor for RDFStore::Vocabulary::Generator.

=item B<createVocabulary(PACKAGECLASS, SCHEMA, NAMESPACE, OUTPUTDIRECTORY, NODE_FACTORY )>

 Generates a Perl 5 package (module) named PACKAGECLASS using SCHEMA in OUTPUTDIRECTORY using NODE_FACTORY.
 Properties and resources are prefixed with NAMESPACE.

=back

=head1 SEE ALSO

RDFStore::Vocabulary::RDF(3) RDFStore::Vocabulary::RDFS(3) RDFStore::Vocabulary::DC(3) RDFStore::Vocabulary::DAML(3)
RDFStore::SchemaModel(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
