use strict;
use warnings;

use Test::More 0.88;
use Test::Differences;

use PPI;
use Pod::Weaver;
use Pod::Elemental;

my $weaver = Pod::Weaver->new_from_config({
    root => 'corpus',
});

# add configured encoding if not there yet
{
    my $doc = Pod::Elemental->read_string(<<'EOP');
=head1 foo

bar
EOP

    my $woven = $weaver->weave_document({
        pod_document => $doc,
    });

    eq_or_diff($woven->as_pod_string, <<'EOP');
=pod

=encoding wtf-8

=head1 foo

bar

=cut
EOP
}

# don't add anything if =encoding is already there
{
    my $doc = Pod::Elemental->read_string(<<'EOP');
=head1 foo

bar

=encoding UTF-8

=head1 bar

baz
EOP

    my $woven = $weaver->weave_document({
        pod_document => $doc,
    });

    eq_or_diff($woven->as_pod_string, <<'EOP');
=pod

=head1 foo

bar

=encoding UTF-8

=head1 bar

baz

=cut
EOP
}

done_testing;
