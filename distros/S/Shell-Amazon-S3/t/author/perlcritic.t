use strict;
use Test::More;
eval { use Test::Perl::Critic -profile => 't/author/perlcriticrc' };
plan skip_all => "Test::Perl::Critic is not installed." if $@;

if ( my $all_code_files = Test::Perl::Critic->can('all_code_files') ) {
    no warnings 'redefine';
    *Test::Perl::Critic::all_code_files = sub {
        use Data::Dumper;
        my @files = $all_code_files->(@_);
        @files = grep { $_ !~ 'ConfigLoader' } @files;
        return @files;
    };
}

all_critic_ok('lib');
