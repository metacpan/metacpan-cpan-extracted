use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::FTPTurboSync',
    VERSION_FROM      => 'lib/Net/FTPTurboSync.pm', # finds $VERSION
    clean => { FILES => '*.tar *.tar.gz Makefile.old' },    
    EXE_FILES => [ qw(scripts/turbo-ftp-sync) ],    
    PREREQ_PM         => {
        'base' => 2.14,
        'Cwd' => 3.33,
        'DBI' => 1.611,
        'Exception::Class' => 1.32,
        'Exception::Class::Base' => 1.32,
        'Exception::Class::TryCatch' => 1.12,
        'File::Find' => 1.14,
        'Net::FTP' => 2.77,
        'Net::Netrc' => 2.12,
        'strict' => 1.04,
        'Test::More' => 0.92,
        'warnings' => 1.06
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/FTPTurboSync.pm', # retrieve abstract from module
       AUTHOR         => 'Daneel <rtfm.rtfm.rtfm@gmail.com>') : ()),
);
