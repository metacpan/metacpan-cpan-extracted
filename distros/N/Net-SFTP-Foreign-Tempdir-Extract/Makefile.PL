use ExtUtils::MakeMaker;
my $repo = "perl-Net-SFTP-Foreign-Tempdir-Extract";
WriteMakefile(
    NAME         => 'Net::SFTP::Foreign::Tempdir::Extract',
    VERSION_FROM => 'lib/Net/SFTP/Foreign/Tempdir/Extract.pm',
    AUTHOR       => 'Michael R. Davis (mrdvt@cpan.org)',
    ABSTRACT_FROM=> 'lib/Net/SFTP/Foreign/Tempdir/Extract.pm',
    LICENSE      => "mit",
    PREREQ_PM    => {
                     'Test::Simple'       => 0.44,
                     'Package::New'       => 0,
                     'Net::SFTP::Foreign' => 0,
                     'File::Tempdir'      => 0,
                     'Path::Class'        => 0.34,
                     'Archive::Extract'   => 0,
                    },
    META_MERGE   => {
          'meta-spec' =>  { version => 2 },
          'resources' =>  {
                            homepage   => "https://github.com/mrdvt92/$repo",
                            bugtracker => {
                                web  => "https://github.com/mrdvt92/$repo/issues",
                            },
                            repository => {
                                type => 'git',
                                url  => 'git@github.com:mrdvt92/'."$repo.git",
                                web  => "https://github.com/mrdvt92/$repo.git",
                            },
                          },
                        },

);
