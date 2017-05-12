package NLP::StanfordParser;

use 5.010000;
use feature ':5.10';
use common::sense;
use Carp ();

BEGIN {
    use Exporter();
    our @ISA     = qw(Exporter);
    our $VERSION = '0.02';

    # extract the path from the Package
    my $package = __PACKAGE__ . '.pm';
    $package =~ s/::/\//g;
    our $JarPath = $INC{$package};
    $JarPath =~ s/\.pm$//g;
    our $JarVersion = '2010-11-30';
}
use constant {
    MODEL_EN_FACTORED => "$NLP::StanfordParser::JarPath/englishFactored.ser.gz",
    MODEL_EN_PCFG     => "$NLP::StanfordParser::JarPath/englishPCFG.ser.gz",
    MODEL_EN_FACTORED_WSJ => "$NLP::StanfordParser::JarPath/wsjFactored.ser.gz",
    MODEL_EN_PCFG_WSJ     => "$NLP::StanfordParser::JarPath/wsjPCFG.ser.gz",
    PARSER_JAR          => "$NLP::StanfordParser::JarPath/stanford-parser.jar",
    PARSER_RELEASE_DATE => "$NLP::StanfordParser::JarVersion",
    PARSER_SOURCE_URI   => 'http://nlp.stanford.edu/software/stanford-parser-'
      . "$NLP::StanfordParser::JarVersion.tgz",
};
our @EXPORT = qw(
  MODEL_EN_FACTORED
  MODEL_EN_PCFG
  MODEL_EN_FACTORED_WSJ
  MODEL_EN_PCFG_WSJ
  PARSER_JAR
  PARSER_RELEASE_DATE
  PARSER_SOURCE_URI
);
use Inline (
    Java => << 'END_OF_JAVA_CODE',
	import java.util.*;
	import edu.stanford.nlp.trees.*;
	import edu.stanford.nlp.parser.lexparser.LexicalizedParser;

	class Java {
		LexicalizedParser parser;
		TreebankLanguagePack tlp;
		GrammaticalStructureFactory gsf;
		public Java (String model) {
			parser = new LexicalizedParser(model);
			parser.setOptionFlags("-retainTmpSubcategories");
			tlp = new PennTreebankLanguagePack();
			gsf = tlp.grammaticalStructureFactory();
		}
		public String parse(String sentence) {
			parser.parse(sentence);
			GrammaticalStructure gs = gsf.newGrammaticalStructure(parser.getBestParse());
            Collection <TypedDependency> collxn =
                                gs.typedDependenciesCollapsed();
            StringBuilder buf = new StringBuilder("[\n");
            for (TypedDependency td : collxn) {
                buf.append("{ relation => '").
                    append(td.reln().getLongName()).append("', from => '").
                    append(td.gov()).append("', to => '").
                    append(td.dep()).append("' },\n");
            }
            buf.append("]\n");
            return buf.toString();
		}
        public static String relations() {
            StringBuilder buf = new StringBuilder("{\n");
            List<GrammaticalRelation> list =
                                        EnglishGrammaticalRelations.values();
            for (GrammaticalRelation rel : list) {
                buf.append("   ").append(rel.getShortName()).append("    =>    '").
                    append(rel.getLongName()).append("',\n");
            }
            buf.append("}\n");
            return buf.toString();
        }
		public String parseold(String sentence) {
			parser.parse(sentence);
			return parser.getBestParse().toString();
		}
	}
END_OF_JAVA_CODE
    CLASSPATH       => PARSER_JAR,
    EXTRA_JAVA_ARGS => '-Xmx800m',
);
use Moose;
use namespace::autoclean;

has model => (
    is      => 'ro',
    isa     => 'Str',
    default => MODEL_EN_PCFG,
);

has parser => (
    is         => 'ro',
    lazy_build => 1,
    isa        => 'NLP::StanfordParser::Java',
);

sub _build_parser {
    my $self = shift;
    return new NLP::StanfordParser::Java( $self->model );
}

before '_build_parser' => sub {
    Carp::croak 'Unable to find ' . PARSER_JAR       unless -e PARSER_JAR;
    Carp::croak 'Unable to find ' . MODEL_EN_PCFG    unless -e MODEL_EN_PCFG;
    Carp::carp 'Unable to find ' . MODEL_EN_FACTORED unless -e MODEL_EN_FACTORED;
    Carp::carp 'Unable to find ' . MODEL_EN_PCFG_WSJ unless -e MODEL_EN_PCFG_WSJ;
    Carp::carp 'Unable to find ' . MODEL_EN_FACTORED_WSJ
      unless -e MODEL_EN_FACTORED_WSJ;
};

sub relations {
    my $str = NLP::StanfordParser::Java->relations();
    return {} unless (defined $str and length $str);
    my $href = eval $str or Carp::carp 'Unable to evaluate result for relations';
    return $str unless defined $href;
    return $href;
}

sub parse {
    my ($self, $sentence) = @_;
    return unless defined $sentence;
    my $str = $self->parser->parse($sentence);
    return unless (defined $str and length $str);
    return $str;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
COPYRIGHT: 2011. Vikas Naresh Kumar.
AUTHOR: Vikas Naresh Kumar
DATE: 6th March 2011
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 NAME

NLP::StanfordParser

=head1 SYNOPSIS

NLP::StanfordParser is a Java wrapper around Stanford's NLP libraries and data
files.

=head1 VERSION

0.02

=head1 EXPORTED CONSTANTS

=over

=item MODEL_EN_PCFG

The full path of the 'English PCFG' model data.

=item MODEL_EN_FACTORED

The full path of the 'English Factored' model data.

=item MODEL_EN_PCFG_WSJ

The full path of the 'WSJ PCFG' model data.

=item MODEL_EN_FACTORED_WSJ

The full path of the 'WSJ Factored' model data.

=item PARSER_JAR

The full path of the JAR file that is used by this module.

=item PARSER_RELEASE_DATE

The date of the release of the Stanford Parser.

=item PARSER_SOURCE_URI

URL for downloading the full package from if the user feels like.

=back 

=head1 OBJECT ATTRIBUTES

=over

=item B<model>

The model can be of 4 types as per the MODEL_* constants described above.
The default model is MODEL_EN_PCFG.

=item B<parser>

The actual parser object. This has a few methods that are exposed externally to
the actual class, most notably the I<parse()> method.

=item B<relations>

The list of grammatical relations supported by the Stanford Parser library.

=back

=head1 OBJECT METHODS

=over

=item B<parse()> 

The method that invokes the current parser object and parses the input array of
strings and returns the parsed output as a string as well.

=back

=head1 COPYRIGHT

Copyright (C) 2011. B<Vikas Naresh Kumar> <vikas@cpan.org>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Started on 6th March 2011.

