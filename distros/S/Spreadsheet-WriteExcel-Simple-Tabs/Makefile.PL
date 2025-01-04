use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Spreadsheet::WriteExcel::Simple::Tabs',
    VERSION_FROM => 'lib/Spreadsheet/WriteExcel/Simple/Tabs.pm',
    AUTHOR       => 'Michael R. Davis',
    LICENSE      => 'perl',
    ABSTRACT     => 'Simple Interface to the Spreadsheet::WriteExcel Package',
    PREREQ_PM    => {
                     'Test::Simple'            => 0.44,
                     'IO::Scalar'              => 0, #package is IO-stringy
                     'Spreadsheet::WriteExcel' => 0,
                    },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Spreadsheet-WriteExcel-Simple-Tabs.git',
        'url' => 'git@github.com:mrdvt92/perl-Spreadsheet-WriteExcel-Simple-Tabs.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Spreadsheet-WriteExcel-Simple-Tabs',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Spreadsheet-WriteExcel-Simple-Tabs/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }
);
