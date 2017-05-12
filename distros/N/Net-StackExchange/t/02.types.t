use strict;
use warnings;

use Test::More tests => 4;

use Moose;
use Net::StackExchange::Types;

has 'boolean' => (
    is     => 'rw',
    isa    => 'Boolean',
    coerce => 1,
);

my $se = __PACKAGE__->new();
is( $se->boolean(1      ), 'true',  q{boolean(1) returned 'true'}        );
is( $se->boolean(0      ), 'false', q{boolean(0) returned 'false'}       );
is( $se->boolean('true' ), 'true',  q{boolean('true') returned 'true'}   );
is( $se->boolean('false'), 'false', q{boolean('false') returned 'false'} );

__PACKAGE__->meta()->make_immutable();

no Moose;
