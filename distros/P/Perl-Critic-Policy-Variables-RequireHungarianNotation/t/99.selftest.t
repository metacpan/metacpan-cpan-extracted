#!perl

use strict;
use warnings;
use Test::More;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

eval "use File::Slurp";
if ($@) {
    plan skip_all => "File::Slurp required";
}
eval "use Module::Load";
if ($@) {
    plan skip_all => "Module::Load required";
}


my $s_policy = 'Variables::RequireHungarianNotation';

my $filename = find_source_file('Perl::Critic::Policy::Variables::RequireHungarianNotation');
my $s_perl   = File::Slurp::read_file($filename);

is(pcritique($s_policy, \$s_perl), 0, "Policy's code matches its own rules");

done_testing();

sub find_source_file {
    my $s_module = shift;
    my $s_filename = Module::Load::_to_file($s_module, 1);
    for my $s_path (@INC) {
        return $s_path . '/' . $s_filename if -f $s_path . '/' . $s_filename;
    }
    return;
}

exit 0;

__END__
