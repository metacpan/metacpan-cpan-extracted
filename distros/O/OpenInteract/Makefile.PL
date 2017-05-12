use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts = (
    'NAME'	       => 'OpenInteract',
    'VERSION_FROM' => 'OpenInteract.pm',
    'EXE_FILES'    => [ qw( script/oi_manage ) ],
    'PREREQ_PM'    => {
      'Apache::Request'       => 0.31,
      'Apache::Session'       => 1.50,
      'Archive::Tar'          => 0,
      'Cache::Cache'          => 1.00,
      'Carp::Assert'          => 0,
      'Class::Accessor'       => 0,
      'Class::Date'           => 1.00,
      'Class::Fields'         => 0,
      'Class::Singleton'      => 1.03,
      'Compress::Zlib'        => 1.08,
      'Digest::MD5'           => 0,
      'File::Copy'            => 0,
      'File::Basename'        => 0,
      'File::MMagic'          => 0,
      'File::Path'            => 0,
      'File::Spec'            => 0,
      'HTML::Entities'        => 1.13,
      'HTTP::Request'         => 0,
      'IO::Zlib'              => 1.00,
      'Lingua::Stem'          => 0,
      'MIME::Lite'            => 2.00,
      'Mail::RFC822::Address' => 0.3,
      'Mail::Sendmail'        => 0.77,
      'Pod::POM'              => 0,
      'Pod::Usage'            => 1.12,
      'SPOPS'                 => 0.60,
      'Template'              => 2.04,
      'Text::Sentence'        => 0,
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com>';
    $opts{ABSTRACT} = 'Database-independent Apache/mod_perl web application server with security, theming and much more.';
}

WriteMakefile( %opts );
