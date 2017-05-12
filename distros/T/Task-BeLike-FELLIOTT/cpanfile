requires 'perl', '5.008001';

# these all come with perlbrew, but I like to install them
# so I can keep track of changes with cpan-outdated & cpan-listchanges
requires 'App::cpanminus';

# feature 'Basic Tools',
requires 'App::Ack';
# requires 'App::perlfind';  # fails to install
requires 'App::cpanoutdated';
requires 'App::cpanlistchanges';
requires 'App::ph'; # init github remotely, seems fun

# handy modules
requires 'Carp::Always';
requires 'Carp::Always::Color';
requires 'Devel::Confess';
requires 'Test::Pretty', '0.23';
requires 'Git::CPAN::Patch';
# requires 'Term::ReadLine::Gnu'; # up/down/tab work in perl -d # fails to install

# Hey Hey!  Term::ReadLine::Gnu won't install on stock OS X.  To get
# it to work with libreadline from Homebrew do::
#
#  $ brew link --force readline
#  $ cpanm Term::ReadLine::Gnu
#  $ brew unlink readline

# Devel::Cover + associated
requires 'Devel::Cover';
requires 'PPI::HTML'; # useful for Devel::Cover HTML reports
requires 'Perl::Tidy'; # ditto
requires 'Pod::Coverage';
requires 'Pod::Coverage::CountParents';
requires 'Devel::CoverX::Covered'; # map tests and files

# Devel::REPL
requires 'Devel::REPL';
requires 'Lexical::Persistence';
requires 'B::Keywords';
requires 'Module::Refresh';
requires 'Devel::REPL::Plugin::DataPrinter';

on 'test' => sub {
    requires 'Test::EOL';
    requires 'Test::Pod', '1.41';
    requires 'Test::More', '0.98';
    requires 'Test::NoTabs';
};

