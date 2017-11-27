use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

# ITUB/Chemistry-Mol-0.37/Mol.pm
test('VERSION < number', <<'END', {Storable => 0});
use Storable;
sub clone {
    my ($self) = @_;
    my $clone = dclone $self;
    $clone->_weaken if Storable->VERSION < 2.14;
    $clone;
}
END

test('in the main package', <<'END', {'Test::More' => 0.98}, {}, {});
require Test::More; Test::More->VERSION('0.98');
END

test('if block', <<'END', {}, {}, {'Test::More' => 0.98});
if (1) { require Test::More; Test::More->VERSION('0.98'); }
END

# PEVANS/Scalar-List-Utils-1.49/lib/Scalar/Util.pm
test('variable', <<'END', {'List::Util' => 0});
use List::Util;
List::Util->VERSION( $VERSION );
END

# CJM/HTML-Tree-5.03/lib/HTML/TreeBuilder.pm
test('numerical version', <<'END', {'LWP::UserAgent' => '5.815'});
use LWP::UserAgent;
LWP::UserAgent->VERSION( 5.815 );
END

# LEONT/Dist-Zilla-Plugin-PPPort-0.007/lib/Dist/Zilla/Plugin/PPPort.pm
test('return value', <<'END', {'Devel::PPPort' => 0});
use Devel::PPPort;
Devel::PPPort->VERSION($self->version);
END

test('eval block or die', <<'END', {}, {'Test::More' => 0.98});
eval { require Test::More; Test::More->VERSION('0.98') } or die;
END

done_testing;
