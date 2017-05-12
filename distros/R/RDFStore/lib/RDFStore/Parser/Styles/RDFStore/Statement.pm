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
# *     version 0.1 - Tue Aug 24 16:15:10 CEST 2004
# *

package RDFStore::Parser::Styles::RDFStore::Statement;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.1';

use Carp;

sub Final {
	my $expat = shift;

	return 1;
	};

sub Assert {
	my ($expat,$st) = @_;

	print $st->toString."\n"
		if( (defined $st) && (ref($st)) && ($st->isa("RDFStore::Statement")) && (defined $expat->{'style_options'}->{'seevalues'}) );
	};

# we might use this callback for XSLT tansofrmations of xml-blobs :)
sub Start_XML_Literal {
	my $expat = shift;
	my $el = shift;

	$expat->{'XML_Literal_processed_namespaces'} = {}
		unless(exists $expat->{'XML_Literal_processed_namespaces'});

	my @current_ns_prefixes = $expat->current_ns_prefixes;

	my $ns_index = 1;

	my $xmlcn='';
	my $elns = $expat->namespace($el);
	if (defined $elns) {
		my $pfx;
		for my $p ( @current_ns_prefixes ) {
			if( $expat->expand_ns_prefix($p) eq $elns ) {
				$pfx = $p;	
				last;
				};
			};
		$pfx = 'n' . $ns_index++
			unless($pfx);

		if( exists $expat->{'XML_Literal_processed_namespaces'}->{ $pfx.$elns } ) {
			$xmlcn .= "<$el";
		} else {
			$xmlcn .= ( $pfx eq '#default' ) ? "<$el xmlns=\"$elns\"" : "<$pfx:$el xmlns:$pfx=\"$elns\"";
			$expat->{'XML_Literal_processed_namespaces'}->{ $pfx.$elns } = 1;
			};
	} else {
		$xmlcn .= "<$el";
		};

	if (@_) {
		for (my $i = 0; $i < @_; $i += 2) {
			my $nm = $_[$i];
			my $ns = $expat->namespace($nm);
			$_[$i] = defined($ns) ? "$ns\01$nm" : "\01$nm";
			};

    		my %atts = @_;
		my @ids = sort keys %atts;
		foreach my $id (@ids) {
			my ($ns, $nm) = split(/\01/, $id);
			my $val = $expat->xml_escape($atts{$id}, '"', "\x9", "\xA", "\xD");
			if (length($ns)) {
				my $pfx;
				for my $p ( @current_ns_prefixes ) {
					if( $expat->expand_ns_prefix($p) eq $ns ) {
						$pfx = $p;	
						last;
						};
					};
				$pfx = 'n' . $ns_index++
					unless($pfx);

				if( exists $expat->{'XML_Literal_processed_namespaces'}->{ $pfx.$ns } ) {
					$xmlcn .= " $nm=\"$val\"";
				} else {
					$xmlcn .= " $pfx:$nm=\"$val\" xmlns:$pfx=\"$ns\""; # '#default' namespace does not apply to attributes
					};
			} else {
				$xmlcn .= " $nm=\"$val\"";
				};
			};
		};

	$xmlcn .= '>';

	return $xmlcn;
	};

sub Stop_XML_Literal {
	my ($expat,$el) = @_;

	my @current_ns_prefixes = $expat->current_ns_prefixes;

	my $elns = $expat->namespace($el);
	if (defined $elns) {
		my $pfx;
		for my $p ( @current_ns_prefixes ) {
			if( $expat->expand_ns_prefix($p) eq $elns ) {
				$pfx = $p;	
				last;
				};
			};
		$pfx = 'n1' #wrong anyway
			unless($pfx);
		return ( $pfx eq '#default' ) ? "</$el>" : "</$pfx:$el>";
	} else {
		return "</$el>";
		};
	};

sub Char_Literal {
	my ($expat,$literal_text) = @_;

	return $expat->xml_escape($literal_text, '>', "\xD");	
	};

1;
}

__END__

=head1 NAME

RDFStore::Parser::Styles::RDFStore::Statement - This module is a RDFStore::Parser::SiRPAC(3) filter to generate RDFStore::Statements

=head1 SYNOPSIS

 
use RDFStore::Parser::SiRPAC;
use RDFStore::NodeFactory;
my $p=new RDFStore::Parser::SiRPAC(	
				ErrorContext => 2,
                                Style => 'RDFStore::Parser::Styles::RDFStore::Statement',
                                NodeFactory     => new RDFStore::NodeFactory()
                                );

if(defined $ENV{GATEWAY_INTERFACE}) {
        print "Content-type: text/html

";
        $p->parsefile($ENV{QUERY_STRING});
} else {
        my $input = shift;
        if($input =~ /^-/) {
                $p->parse(*STDIN);
        } else {
                $p->parsefile($input);
        };
};

=head1 DESCRIPTION

In the samples directory of the distribution you can find a set of a sample scripts to play with :)

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::Parser::SiRPAC. B<Options> are passed as key/value pairs. RDFStore::Parser::Styles::MagicTie supports B<all> the RDFStore::Parser::SiRPAC options plus the following:

=head1 NOTES

This module will probably be renamed to XML::SAX::RDF::RDFStore::Model when proper SAX2 support is added to the main RDFStore::Parser::SiRPAC parser

=head1 SEE ALSO

RDFStore::Parser::SiRPAC(3) RDFStore::Parser::Styles::RDFStore::Statement and RDFStore::Statement(3)

=head1 AUTHOR

Alberto Reggiori <areggiori@webweaving.org>
