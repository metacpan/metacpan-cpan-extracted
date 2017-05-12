# $Id: Makefile.PL 4117 2009-03-08 09:21:04Z andrew $

use ExtUtils::MakeMaker;

my %opts = (
    'NAME'         => 'Pod::POM::View::DocBook',
    'VERSION_FROM' => 'lib/Pod/POM/View/DocBook.pm',
    'PREREQ_PM'    => { 

        'List::MoreUtils'     => 0,
        'Pod::POM::Constants' => 0,
        'Pod::POM::View'      => 0,
        'Text::Wrap'          => 0,

        # Required for testing:
        'Class::Accessor'     => 0,
        'File::Slurp'         => 0,
        'FindBin'             => 0,
        'Test::XML'           => 0,
        'XML::LibXML'         => 0,
        'YAML::Any'           => 0,
    },
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },

);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andrew Ford <A.Ford@ford-mason.co.uk>';
    $opts{ ABSTRACT } = 'DocBook View for POD Object Model',
}

WriteMakefile( %opts );

