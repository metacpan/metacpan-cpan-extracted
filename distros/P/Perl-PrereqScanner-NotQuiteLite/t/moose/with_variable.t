use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('with variable', <<'END', {Mouse => 0});
use Mouse;
sub load_plugin {
    my ($self, $plugin) = @_;

    my $plug = 'TheEye::Plugin::'.$plugin;
    print STDERR "Loading $plugin Plugin\n" if $self->is_debug;
    with($plug);
    return;
}
END

done_testing;
