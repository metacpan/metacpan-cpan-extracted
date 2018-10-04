use ExtUtils::MakeMaker;

my $have_Term_ReadKey = 1;
eval 'require "Term/ReadKey.pm"';
if ($@) { $have_Term_ReadKey = 0; }

my $have_Term_Size = 1;
eval 'require "Term/Size.pm"';
if ($@) { $have_Term_Size = 0; }

if (!$have_Term_ReadKey) { print <<'EOT'; }
The CPAN module Term::ReadKey is not installed;
it's optional, but it should improve portability.

EOT

if (!$have_Term_Size && !$have_Term_ReadKey) { print <<'EOT'; }
The CPAN module Term::Size is not installed either;
again, it's optional, but it should improve portability.

EOT

WriteMakefile(
  NAME             => 'Term::Clui',
  VERSION_FROM     => 'lib/Term/Clui.pm',
  AUTHOR           => [
                        'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
                        'Graham Ollis <plicease@cpan.org>',
                      ],
  ABSTRACT_FROM    => 'lib/Term/Clui.pm',
  MIN_PERL_VERSION => '5.006000',
  LICENSE          => 'perl',
  PREREQ_PM        => {
    'Term::ReadLine'      => 0,
    'File::Copy'          => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.56',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web  => 'https://github.com/plicease/Term-Clui/issues',
      },
      homepage => 'https://metacpan.org/pod/Term-Clui',
      repository => {
        type => 'git',
        url  => 'https://github.com/plicease/Term-Clui.git',
        web  => 'https://github.com/plicease/Term-Clui',
      },
    }
  },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  clean => { FILES => 'Term-Clui-*' },
);
