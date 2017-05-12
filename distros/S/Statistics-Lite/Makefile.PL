use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
  NAME	          => 'Statistics::Lite',
  AUTHOR          => 'Brian Lalonde (brian@webcoder.info)',
  LICENSE         => 'perl',
  VERSION_FROM    => 'Lite.pm', 
  ABSTRACT_FROM   => 'Lite.pm',

  ($mm_ver <= 6.45
    ? ()
    : (META_MERGE => {
      'meta-spec' => { version => 2 },
        resources => {
          repository  => {
            type => 'git',
            web  => 'https://github.com/brianary/Statistics-Lite',
            url  => 'https://github.com/brianary/Statistics-Lite.git',
          },
        },
      })
  ),

);
