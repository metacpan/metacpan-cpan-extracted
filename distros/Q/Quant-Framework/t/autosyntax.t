use strict;

use Test::More;
use Test::Syntax::Aggregate;
use File::Find::Rule;
use Test::Perl::Critic -profile => 't/rc/.perlcriticrc';
use Test::Strict;
use Cwd;

my $pattern = $ARGV[0];    # confines test to just files matching this pattern.

subtest "Check modules in lib" => sub {
    for (sort File::Find::Rule->file->name(qr/\.p[lm]$/)->in(Cwd::abs_path . '/lib')) {
        /$pattern/ || next if $pattern;
        syntax_ok($_) if $_ =~ /\.pl$/;
        critic_ok($_);
    }
};

done_testing;
