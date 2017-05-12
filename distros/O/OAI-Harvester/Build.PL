use Module::Build;

my $build = Module::Build->new(
    dist_name	=> 'OAI-Harvester',
    module_name	=> 'Net::OAI::Harvester',
    license	=> 'perl',
    requires	=> {
	'perl'			=> '5.8.0',
	'LWP::UserAgent'	=> '2.0',
	'Storable'		=> '2.0',
	'URI'			=> '1.3',
	'XML::SAX'		=> '0.12',
	'XML::SAX::Base'	=> '1.04',
	'Carp'			=> 0,
	'File::Temp'		=> 0,
	'IO::File'		=> 0,
      },
    configure_requires => {
	'XML::SAX'		=> 0,  # we want to comment on the correct setup here
	'Module::Build'		=> 0,  # ExtUtils::MakeMaker still an option...
	'version'		=> '0.77',
      },
    test_requires => {
	'XML::SAX::Writer'	=> 0,
	'File::Path'		=> 0,
	'IO::Dir'		=> 0,
	'LWP::Protocol::https'	=> 0,
      },
    recommends => {
	'XML::SAX::ExpatXS'	=> 0,
	'XML::SAX::Writer'	=> 0,
      },
    script_files => [
	'bin/oai-listmetadata',
	'bin/oai-listsets',
	'bin/oai-listrecords',
	'bin/oai-dump'
      ],
    sign => 0,
    meta_merge => {
	keywords	=> [ qw( OAI-PMH metadata harvesting protocol )],
	resources	=> {
	    bugtracker	=> {
		web	=> 'http://rt.cpan.org/Public/Dist/Display.html?Name=OAI-Harvester',
		mailto	=> 'bug-OAI-Harvester@rt.cpan.org',
	      },
	    repository	=> {
		url	=> 'https://svn.code.sf.net/p/oai-harvester/code/trunk',
		web	=> 'https://sourceforge.net/p/oai-harvester/code/HEAD/tree/oai-harvester/trunk/',
		type	=> 'svn',
	      },
	    homepage	=> 'http://oai-harvester.sourceforge.net/',
	  },
      }
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
      }

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

NOH_ParserPackage=XML::SAX::PurePerl ./Build test

MESSAGE
      
     }
}


## a general message about needing to be connected to the net for tests

print <<MESSAGE;

Note: for './Build test' to work you must be connected to the Internet.
The tests use the OAI-PMH repositories at the Library of Congress and OCLC.

MESSAGE


$build->create_build_script;
