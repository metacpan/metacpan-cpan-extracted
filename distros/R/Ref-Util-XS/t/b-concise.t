use strict;
use warnings;
use Test::More;
use Ref::Util::XS 'is_arrayref';
require B::Concise;

plan skip_all => 'This version of B::Concise does not have "compile"'
    if !B::Concise->can('compile');

plan skip_all => 'nothing to do when no custom ops'
    if !Ref::Util::XS::_using_custom_ops();

plan tests => 2;

sub func { is_arrayref([]) }

my $walker = B::Concise::compile('-exec', 'func', \&func);
B::Concise::walk_output(\ my $buf);
eval { $walker->() };
my $exn = $@;

ok(!$exn, 'deparsing ops succeeded');
like($buf, qr/\b is_arrayref \b/x, 'deparsing found the custom op');
