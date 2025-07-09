use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'Query::Tags',
    VERSION_FROM     => 'lib/Query/Tags.pm',
    ABSTRACT_FROM    => 'lib/Query/Tags.pm',
    AUTHOR           => ['Tobias Boege <tobs@taboege.de>'],
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 'v5.16.0',
    META_MERGE       => {
       'meta-spec' => { version => 2 },
        resources  => {
            repository => {
                type => 'git',
                url  => 'https://github.com/taboege/perl-Query-Tags.git',
                web  => 'https://github.com/taboege/perl-Query-Tags',
            },
        }
    },
);

# Compile Pegex grammar
sub MY::postamble {
    <<EOF;
lib/Query/Tags/Grammar.pm : share/query-tags.pgx
\t\$(PERL) -Ilib -MQuery::Tags::Grammar=compile
EOF
}
