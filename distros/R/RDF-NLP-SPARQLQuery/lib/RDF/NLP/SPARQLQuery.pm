package RDF::NLP::SPARQLQuery;

use utf8;
use strict;
use warnings;

our $VERSION='0.1';

use Data::Dumper;
use Config::General;

use RDF::NLP::SPARQLQuery::Question;

# DOC
sub new {
    my $class = shift;
    my %args = @_;

    binmode(STDERR, ":utf8");
    binmode(STDOUT, ":utf8");
    binmode(STDIN, ":utf8");

    my $NLQuestion = {
	"files" => {
	    'config' => undef,
	    # 'questions' => undef,
	    'semtypecorresp' => undef,
	},
	'config' => undef,
	'questions' => undef,
	'semtypecorresp' => {},
	'format' => "XML",
	'verbose' => 0,
    };
    
    bless $NLQuestion, $class;
    return($NLQuestion);
}

sub _files {
    my ($self) = @_;
    
    return($self->{'files'});
}

sub configFile {
    my $self = shift;
    
    if (@_) {
	$self->_files->{'config'} = shift;
    }
    return($self->_files->{'config'});
}

sub format {
    my $self = shift;
    
    if (@_) {
	$self->{'format'} = shift;
    }
    return($self->{'format'});
}

# DOC
sub verbose {
    my $self = shift;
    
    if (@_) {
	$self->{'verbose'} = shift;
    }
    return($self->{'verbose'});
}

sub config {
    my ($self) = @_;
    
    return($self->{'config'});
}

# sub _questionsFile {
#     my $self = shift;

#     if (@_) {
# 	$self->_files->{'questions'} = shift;
#     }
#     return($self->_files->{'questions'});
# }

sub _semtypecorrespFile {
    my $self = shift;
    my $lang = shift;

    return($self->config->{'NLQUESTION'}->{'language="'. uc($lang) . '"'}->{'SEMANTICTYPECORRESPONDANCE'});
}

sub semtypecorresp {
    my ($self, ) = @_;

    if (!defined $self->{'semtypecorresp'}) {
	$self->{'semtypecorresp'} ={};
    }

    return($self->{'semtypecorresp'});
}

# DOC
sub loadConfig {

    my ($self, ) = @_;
    my $language;

    my $cg = new Config::General('-ConfigFile' => $self->configFile,
				 '-InterPolateVars' => 1,
				 '-InterPolateEnv' => 1
	);
    
    my %config = $cg->getall;

    $self->_printVerbose(Dumper(\%config),2);

    $self->{'config'} = \%config;

    foreach $language (keys %{$config{'NLQUESTION'}}) {
	if ($language =~ /language=\"?(?<lang>[^"]+)\"?/) {
	    $self->_loadSemtypecorresp(lc($+{lang}));
	}
    }

    return($self->config);
}

# DOC
sub loadInput {

    my ($self, $filename) = @_;
    my $line;
    my $docId;
    my $language;
    my @sentences;
    my @postags;
    my @semanticUnits;
    my $word;
    my $postag;
    my $lemma;
    my $start_offset;
    my $semanticUnit;
    my $canonical_form;
    my $semanticTypes;
    my %semTypes;
    my $end_offset;
    my $semf;
    my $question;
    my $id;

    open FILE, "<:utf8", $filename or die "No such file $filename\n";
#    warn "filename: $filename\n";
    while($line = <FILE>) {
	chomp($line);
	if ($line !~ /^\s*#/) {
	    if ($line =~ /^DOC:\s?(?<id>.*)/) {
		$docId = $+{id}; #'
		# warn "docId: $docId\n";
	    }
	    if ($line =~ /^language:\s?(?<lang>.*)/) {
		$language = $+{lang}; #'
	    }
	    if ($line =~ /^sentence:\s/) {
		while($line = <FILE>) {
		    chomp($line);
		    if (($line !~ /^\s*#/) && ($line !~ /^\s*$/)) {
			if ($line ne "_END_SENT_") {
			    push @sentences, $line;
			} else {
			    last;
			}
		    }		    
		}
	    }
#	    warn "line: $line\n";
	    if ($line =~ /^word information:/) {
		$id=0;
		while($line = <FILE>) {
		    chomp($line);
		    if (($line !~ /^\s*#/) && ($line !~ /^\s*$/)) {
			if ($line ne "_END_POSTAG_") {
			    ($word, $postag, $lemma, $start_offset) = split /\t/, $line;
#			    push @postags, $line;
			    push @postags, {
				"id" => $id,
				"word" => $word,
				"postag" => $postag,
				"lemma" => $lemma,
				"start_offset" => $start_offset,
				"line" => $line,
			    };
			    $id++;
			} else {
			    last;
			}
		    }		    
		}
	    }
	    if ($line =~ /^semantic units:/) {
		$id = 0;
		my %lines;
		while($line = <FILE>) {
		    chomp($line);
		    if (($line !~ /^\s*#/) && ($line !~ /^\s*$/)&&(!exists $lines{$line})) {
			if ($line ne "_END_SEM_UNIT_") {
			$lines{$line}++;
			($semanticUnit, $canonical_form, $semanticTypes, $start_offset, $end_offset) = split /\t/, $line;
#			    push @semanticUnits, $line;
			    %semTypes=();
			    foreach $semf (split /:/, $semanticTypes) {
				$semTypes{$semf} = [split /\//, $semf];
			    }
			    # warn $semanticUnit . " ($semanticTypes)\n";
			    # warn "\t" . join('::', keys(%semTypes)) . "\n";
			    push @semanticUnits, {
				"id" => $id,
				"semanticUnit" => $semanticUnit,
				"canonical_form" => $canonical_form,
				"semanticTypes" => {%semTypes},
				"start_offset" => $start_offset,
				"end_offset" => $end_offset,
				"line" => $line,
			    };
			    $id++;
			} else {
			    last;
			}
		    }		    
		}
	    }
	    if ($line eq "_END_DOC_") {
		$question = RDF::NLP::SPARQLQuery::Question->new("docId" => $docId,
								       'verbose' => $self->verbose,
								       "language" => uc($language),
								       "sentences" => \@sentences,
								       "postags" => \@postags,
								       "semanticUnits" => \@semanticUnits,
								       "config" => $self->config,
		    );
		$self->_addQuestion($question->{'docId'}, $question);
		$docId = undef;
		$language = undef;
		@sentences = ();
		@postags = ();
		@semanticUnits = ();
	    }
	}

    }
    
    close FILE;

    return(scalar($self->questionIds));
}

sub questions {
    my $self = shift;

    if (!(defined $self->{'questions'})) {
	$self->{'questions'} = {};
    }
    return($self->{'questions'});
}

sub getQuestionList {
    my $self = shift;

    return(values %{$self->{'questions'}});
}

sub questionIds {
    my $self = shift;

    return(keys %{$self->{'questions'}});
}

sub getQuestionFromId {
    my $self = shift;
    my $docId;

    if (@_) {
	$docId = shift;
	if (exists $self->questions->{$docId}) {
	    return($self->questions->{$docId});
	}
    }
    return(undef);
}

sub _addQuestion {
    my $self = shift;
    my $docId = shift;

    if (!defined $docId) {
	return(undef);
    }

    if (@_) {
	$self->questions->{$docId} = shift;
    }
    
    return($self->questions->{$docId});
}


sub _loadSemtypecorresp {
    my ($self, $lang) = @_;

    my $cg = new Config::General('-ConfigFile' => $self->_semtypecorrespFile($lang),
				 '-InterPolateVars' => 1,
				 '-InterPolateEnv' => 1
	);
    
    my %resource = $cg->getall;

    $self->semtypecorresp->{uc($lang)} = \%resource;

    $self->_printVerbose( Dumper($self->semtypecorresp->{uc($lang)}), 3);

    return($self->semtypecorresp->{uc($lang)});
}

# DOC
sub Questions2Queries {
    my $self = shift;
    my $outStr = shift;
    my $question;
    my $questionCount = 0;
    my $docHeadId;
    my $docId;
    my $outStr2;
    my $answer;

    if ($self->format eq "XML") {
	$$outStr = '<?xml version="1.0" ?>' . "\n";
	# warn $self->getQuestionList;
	$docId = ($self->getQuestionList)[0]->docId;
	# warn $docId;
	$docId =~ /\-([\d\w]+)$/;
	$docHeadId = $`;

	$$outStr .= '<dataset id="' . $docHeadId . '">' . "\n";
    }
    foreach $question ($self->getQuestionList) {
#	warn $self->semtypecorresp;
	# $self->format, 
	$self->_printVerbose($question->docId . "\n");
	$questionCount += $question->Question2Query($self->semtypecorresp);
	$self->_printVerbose($question->query->queryString);
	# $$outStr .= $outStr2;
	if ($self->format eq "XML") {
	    # warn $question->query->queryXMLString;
	    $$outStr .= $question->query->queryXMLString;
	}	
	if ($self->format eq "SPARQL") {
	    # warn $question->query->queryString;
	    $$outStr .= $question->query->queryString;
	}	
	if ($self->format eq "SPARQLANSWERS") {
	    $question->query->getQueryAnswers;
	    $$outStr .= "\n" . $question->docId . "\n";
	    $$outStr .= join("\n",keys(%{$question->query->queryAnswers}));
	}
	if ($self->format eq "XMLANSWERS") {
	    $$outStr .= $question->query->queryXMLString;
	    $$outStr =~ s!</question>\n!!;

	    $question->query->getQueryAnswers;
	    $$outStr .= "<answers>\n";
	    foreach $answer (keys(%{$question->query->queryAnswers})) {
		$$outStr .= "<answer>\n";
		$$outStr .= "<uri>$answer</uri>\n";
		$$outStr .= "</answer>\n";
	    }
	    $$outStr .= "</answers>\n";
	    $$outStr .= "</question>\n";
	}
    }
    if ($self->format eq "XML") {
	$$outStr .= '</dataset>' . "\n";
    }

    return($questionCount);
}

sub _printVerbose {
    my($self, $msg, $level) = @_;

    if (!defined $level) {
	$level = 1;
    }

    if (($self->verbose > 0) && ($self->verbose >= $level)) {
	warn "$msg";
    }

}




1;

__END__

=head1 NAME

RDF::NLP::SPARQLQuery - Perl extension for converting Natural Language Questions in SPARQL queries

=head1 SYNOPSIS

use RDF::NLP::SPARQLQuery;

my $NLQuestion = RDF::NLP::SPARQLQuery->new();

$NLQuestion->configFile("t/nlquestion.rc");

$NLQuestion->loadConfig;

$NLQuestion->format("SPARQL");

$NLQuestion->loadInput("examples/example1.qald");

my $outStr;
$NLQuestion->Questions2Queries(\$outStr);

print $outStr;



=head1 DESCRIPTION

This module aims at querying RDF knowledge base with questions
expressed in Natural language. Natural language questions are
converted in SPARQL queries. The method is based on rules and
resources.  Resources are provided for querying the Drugbank
(<http://www.drugbank.ca >), Diseasome (<http://diseasome.eu>) and
Sider (<http://sideeffects.embl.de>).

The Natural language question has been already annotated with
linguistic and semantic information. Input file provides this
information (see details regarding the format in the section INPUT
FORMAT).

The object 6 fields: 

=over 4

=item *

C<files> is a hashtablecontaining the name of the three files which are useful for running the converter (the configuration filename in the key C<config> and the file name where the semantic correspondance and the rewriting rules are defined in the key C<semtypecorresp>).

=item *

C<config> contains the configuration structure.

=item *

C<questions> contains the list of natural language questions.

=item *

C<semtypecorresp> contains the semantic correspondance and the rewriting rules to egenerate the SPARQL queries.

=item *

C<format> contains the format of the output. Accepted values are C<SPARQL> (the SPARQL query), C<XML> (the SPARQL query in the QALD challenge XML format), C<SPARQLANSWERS> (the answers return by the SPARQL query), C<XMLANSWERS> (the answers return by the SPARQL query in the QALD challenge XML format).

=item *

C<verbose> specifies the verbose level.

=back

=head1 METHODS

=head2 new()

    new();

The method creates and returns a new converter for translating natural language questions in SPARQL queries.

=head2 format()

    format($formatValue);

The method sets or returns the format of the output (accepted values are C<XML>, C<SPARQL>, C<XMLANSWERS> and C<SPARQLANSWERS>).

=head2 verbose()

    verbose($verboseLevel);

The method sets or returns the level of theverbose mode (accepted values: 0 to 2)

=head2 loadConfig()

    loadConfig();

The method loads the configuration from the file indicated in field C<files/config> (and returned by configFile).

=head2 loadInput()

    loadInput($questionFile);

The method loads the questions from the file indicated in argument (C<$questionFile>). The method can be called several times to load several question files.

=head2 Questions2Queries()

    Questions2Queries(\$outputStr);

The method runs the converter on the questions recorded in the field C<questions>. The results are returned in the variable C<$outputStr>).

=head2 config()

    config();


The method sets or returns the configuration structure.


=head2 configFile()

    configFile();

The method sets or returns the name of the configuration file.

=head2 semtypecorresp()

    semtypecorresp();

The method sets or returns the semantic correspondance and the rewriting rules used to convert the natural language questions in SPARQL queries.


=head2 questions()

    questions();

The methods returns the hashtable containing the natural language
questions or initialises the hashtable. The keys are the identifier of
the questions and the values are objects C<RDF::NLP::SPARQLQuery::Question>).

=head2 getQuestionList()

    getQuestionList();

The method returns the list of questions (each question is an object C<RDF::NLP::SPARQLQuery::Question>).

=head2 questionIds()

    questionIds();

The method returns the identifiers of the questions.


=head2 getQuestionFromId()

    getQuestionFromId($questionId);

The method returns the question corresponding to the identifier C<$questionId>.


=head1 INPUT FORMAT

The input file is composed of several parts providing linguistic and semantic information on the natural language question:

=over 4

=item *

the identifier of the question is introduced by C<DOC:> on one line. For instance:

 DOC: question1


=item *

the definition of the language of the question is defined with C<language:> on one line. For instance: 

 language: EN

=item *

the list of the sentence(s) is introducted by the keyword C<sentence:> and ends with the keyword C<_END_SENT_> (both in one line). For instance:


 sentence:
 Which diseases is Cetuximab used for?
 _END_SENT_


=item *

the morpho-syntactic information associated to each word is introduced by the keyword C<word information:> ends with the keyword C<_END_POSTAG_> (both in one line). Each line contains 4 information separated by tabulations: the inflected form of the word, its part-of-speech tag, its lemma and its offset (in number of characters). For instance:


 word information:
 Which	WDT	which	10	
 diseases	NNS	disease	16	
 is	VBZ	be	25	
 Cetuximab	VBN	Cetuximab	28	
 used	VBN	use	38	
 for	IN	for	43	
 ?	SENT	?	46	
 _END_POSTAG_


=item *

the semantic entities and associated semantic information is introduced by the keyword C<semantic units:> ends with the keyword C<_END_SEM_UNIT_> (both in one line). Each line contains 5 information separated by tabulations: the semantic entity, its canonical form, its semantic types (separated by column), its start offset and its end offset (in number of characters). For instance:



 semantic units:
 # term form<tab>term canonical form<tab>semantic features<tab>offset start<tab>offset end (ended by _END_SEM_UNIT_)
 diseases	diseas	disease:disease	16	23
 Cetuximab	Cetuximab	drug/drugbank/gen/DB00002:drug/drugbank/gen/DB00002	28	36
 used for	used for	possibleDrug:possibleDrug	38	45
 Cetuximab	Cetuximab	drug/drugbank/gen/DB00002:drug/drugbank/gen/DB00002	28	36
 diseases	diseas	disease:disease	16	23
 used for	used for	possibleDrug:possibleDrug	38	45
 _END_SEM_UNIT_

Semantic types can be decomposed in subtypes. They are coded in the
same way as a unix file path.

=back

NB: Comments are introduced by the character C<#>. Empty lines are ignored.

Examples of files are available in the C<example> of the archive.

=head1 CONFIGURATION FILE FORMAT

The configuration file format is similar to the Apache configuration
format. The module C<Config::General> is used to read the file.  There
are sections named C<NLQUESTION> for each language (identified with
the attribute C<language>). Each section defines the following
variables defining the behaviour of the script:

=over 4

=item *

C<VERBOSE>: it defines the verbose mode level similarly to the option C<--verbose>. It is overwritten by this option.

=item *

C<REGEXFORM>: this boolean variable indicates if in case of use of regex, the inflected form (value 1) or canonical form (value 0) is used.

=item *

C<UNION>: this boolean variable indicates if the union is used or not

=item *

C<SEMANTICTYPECORRESPONDANCE>: this variable defines the file containing the semantic information (rewriting rules, semantic correspondance, etc.) to generate the SPARQL queries

=item *

C<URL_PREFIX>: it specifies the begining of the URL (before the SPARQL query) when the query is sent to a virtuoso server.

=item *

C<URL_SUFFIX>: it specifies the end of the URL (before the SPARQL query) when the query is sent to a virtuoso server.

=back


=head1 SEE ALSO

QALD challenge web page: <http://greententacle.techfak.uni-bielefeld.de/~cunger/qald/index.php?x=task2&q=4>

Natural Language Question Analysis for Querying Biomedical Linked Data
Thierry Hamon, Natalia Grabar, and Fleur Mougin. Natural Language
Interfaces for Web of Data (NLIWod 2014). 2014. To appear.


=head1 AUTHORS

Thierry Hamon, E<lt>hamon@limsi.frE<gt>

=head1 LICENSE

Copyright (C) 2014 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

