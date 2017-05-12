use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Weaver::Plugin::Exec;

my $str = do { local $/; <DATA> };

my $doc = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->new->transform_node($doc);

my $e = exception {
   Pod::Elemental::Transformer::Exec->new->transform_node($doc)
};

ok $e, 'correctly got exception';
like $e, qr/STDOUT: station!/, 'STDOUT included';
like $e, qr/STDERR: got an error :\(/, 'STDERR included';
like $e, qr/Command 'perl -E.*' failed/, 'Command included';

note "Exception: $e";


done_testing;

__DATA__
=pod

=head1 Welcome to Pod!

=for exec
perl -E"say 'station!'; die 'got an error :('"

Right??
