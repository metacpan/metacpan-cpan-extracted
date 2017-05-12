use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::OAI::Harvester',
    'DISTNAME'		=> 'OAI-Harvester',
    'ABSTRACT'		=> 'A package for harvesting metadata using OAI-PMH',
    'LICENSE'		=> 'perl',
    'VERSION_FROM'	=> 'lib/Net/OAI/Harvester.pm', 
    'PMLIBDIRS'		=> [ qw( lib/ ) ],
    'AUTHOR'		=> 'Ed Summers <ehs@pobox.com>',
    'MIN_PERL_VERSION'	=> '5.8.0',
    'PERL_MALLOC_OK'	=> 1,
    'PREREQ_PM'		=> { 
			    'LWP::UserAgent'	=> '2.0',
			    'Storable'		=> '2.0',
			    'URI'		=> '1.3',
			    'XML::SAX'		=> '0.12',
			    'XML::SAX::Base'	=> '1.04',
			    'Carp'		=> 0,
			    'File::Temp'	=> 0,
			    'IO::File'		=> 0,
			    },
    'CONFIGURE_REQUIRES' => { 
			    'XML::SAX'		=> 0,
			    },
    EXE_FILES		=> [ 
			    'bin/oai-listsets',
			    'bin/oai-listrecords',
                            'bin/oai-dump'
			   ],
    PL_FILES		=> {},
    SIGN		=> 0,
);

## if they either don't have XML::SAX::ExpatXS or XML::SAX cannot locate it
## (there are notorious problems with respect to parserdetails.ini)
## tell them they might want to get it

eval( 'use XML::SAX' ); # existence was not enforced by the constructor above...
unless ( $@ ) { 
    my $found = 0;
    my $any = 0;
    foreach my $parser ( @{ XML::SAX->parsers() } ) { 
        $any ++;
	$found = 1 if $parser->{ Name } eq 'XML::SAX::ExpatXS';
      };

    if ( $any ) {
        unless ( $found ) { 
	    print <<MESSAGE;

Note: It looks like you don't have XML::SAX::ExpatXS installed. 
      This is ok since we have XML::SAX::PurePerl to fall back to.
      You might want to consider installing XML::SAX::ExpatXS if you 
      want to boost Net::OAI::Harvester's performance and reliability.

MESSAGE
        }
     }
   else {
	print <<MESSAGE;

WARNING: It looks like you don't have any XML::SAX parsers installed.

      Please check ParserDetails.ini if appropriate for your version
      of XML::SAX::ParserFactory.

      OAI-Harvester will resort to XML::SAX::PurePerl which has the
      appropriate properties and comes with the XML::SAX distribution.

      For the Build test you may force a specific parser as follows:

NOH_ParserPackage=XML::SAX::PurePerl make test

MESSAGE
    }
}


## a general message about needing to be connected to the net for tests

print 
<<MESSAGE;

Note: for 'make test' to work you must be connected to the Internet. The
tests use the OAI-PMH repositories at the Library of Congress and OCLC.

MESSAGE

