use strict;
use warnings;

use Test::More;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Weaver::Plugin::Exec;

my $str = do { local $/; <DATA> };

my $doc = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->new->transform_node($doc);
Pod::Elemental::Transformer::Exec->new->transform_node($doc);

is($doc->as_pod_string, <<'POD');
=pod

=head1 Welcome to Pod!

 1

 2

Right??

=cut
POD

note('POD: ' . $doc->as_pod_string);

done_testing;

__DATA__
=pod

=head1 Welcome to Pod!

=for exec
perl -E"say 1"

=for exec
perl -E"say 2"

Right??
