use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Z3950::FOLIO',
    VERSION_FROM      => 'lib/Net/Z3950/FOLIO.pm', # finds $VERSION
    PREREQ_PM         => {
	Net::Z3950::SimpleServer => 1.21,
	LWP::UserAgent => 6.05,
	LWP::Protocol::https => 6.04,
	Mozilla::CA => 20200520,
	Cpanel::JSON::XS => 4.08,
	MARC::Record => 2.0,
	MARC::File::XML => 1.0.5,
	Net::Z3950::ZOOM => 1.30,
	XML::Simple => 2.25,
	Net::Z3950::PQF => 1.0,
	Unicode::Diacritic::Strip => 0.13,
	Test::Differences => 0.61,
    },
    META_ADD => {
	no_index => {
	    namespace => [ 'Net::Z3950::RPN' ],
	},
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Z3950/FOLIO.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),

    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/folio-org/Net-Z3950-FOLIO.git',
                 web  => 'https://github.com/folio-org/Net-Z3950-FOLIO',
             },
             bugtracker => {
                 web => 'https://issues.folio.org/projects/ZF/issues',
             },
         }})
         : ()
    ),
);

sub MY::postamble {
    return q[
makemakerdflt: ModuleDescriptor.json

ModuleDescriptor.json: descriptors/ModuleDescriptor-template.json ./descriptors/transform-descriptor.pl
	rm -rf $@; 
	./descriptors/transform-descriptor.pl $< > $@
	chmod ugo-w $@

clean :: removeModuleDescriptor

removeModuleDescriptor:
	rm -f ModuleDescriptor.json

regen:
	zoomsh 'open @:9997/chicago' 'find @attr 1=12 6266559' 'set preferredRecordSyntax opac' 'show 0' quit > REGRESSION

regress:
	zoomsh 'open @:9997/chicago' 'find @attr 1=12 6266559' 'set preferredRecordSyntax opac' 'show 0' quit | diff REGRESSION -
];
}
