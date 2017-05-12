use ExtUtils::MakeMaker qw/WriteMakefile prompt/;
use strict;

my $online_tests = prompt('Do you want to perform online tests during "make test" phase?', 'no') =~ /^\s*(y)/i;
my $tests = join ' ' => glob ($online_tests ? 't/0*.t t/n*.t' : 't/0*.t');

WriteMakefile(
    NAME                => 'Scrabble::Dict',
    VERSION_FROM        => 'lib/Scrabble/Dict.pm', 
    PREREQ_PM           => {
      'LWP::UserAgent'  => 2.001
    }, 
    EXE_FILES           => [ qw(bin/scrabble_dict) ],
    test                => { TESTS => $tests },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'lib/Scrabble/Dict.pm', 
       AUTHOR           => 'Alan Grow <agrow+nospam@thegotonerd.com>') : ()),
);

