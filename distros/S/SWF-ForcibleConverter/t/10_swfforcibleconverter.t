use strict;
#use Test::More tests => 1;
use Test::More qw(no_plan);

use constant MIN_BUF_SIZE => 4096;

use SWF::ForcibleConverter;

my $fc;

#-- buffer_size accessor

$fc = SWF::ForcibleConverter->new;

is( $fc->buffer_size, undef, 'property buffer size default');
is( $fc->get_buffer_size, MIN_BUF_SIZE, 'default buffer size via get_');

eval { $fc->set_buffer_size() };
ok( $@, 'set buffer undef');

eval { $fc->set_buffer_size(-1) };
ok( $@, 'set buffer negative value');

eval { $fc->set_buffer_size(MIN_BUF_SIZE -1) };
ok( $@, 'set buffer less than minimum');

eval { $fc->set_buffer_size(MIN_BUF_SIZE) };
ok( ! $@, 'set buffer more than minimum');

is( $fc->buffer_size(-1), -1, 'set buffer_size -1 to force' );
is( $fc->get_buffer_size, -1, 'get_buffer_size -1 to force' );
is( $fc->buffer_size(undef), undef, 'set buffer_size accepts undef');
is( $fc->get_buffer_size, MIN_BUF_SIZE, 'reset buffer size' );

$fc->set_buffer_size(MIN_BUF_SIZE * 2);
is( $fc->get_buffer_size, MIN_BUF_SIZE * 2, 'set and get buffer size');


#-- buffer_size with constructor

eval { $fc = SWF::ForcibleConverter->new({ buffer_size => undef }) };
ok( $@, 'create with buffer undef and die');

eval { $fc = SWF::ForcibleConverter->new({ buffer_size => -1 }) };
ok( $@, 'create with buffer -1 and die');

eval { $fc = SWF::ForcibleConverter->new({ buffer_size => MIN_BUF_SIZE }) };
ok( ! $@, 'create with buffer ok');


#-- stash

$fc = SWF::ForcibleConverter->new;
is( $fc->{_r_io}, undef, 'init statsh _r_io');
is( $fc->{_w_io}, undef, 'init statsh _w_io');
is( $fc->{_header}, undef, 'init statsh _header');
is( $fc->{_header_v9}, undef, 'init statsh _header_v9');
is( $fc->{_first_chunk}, undef, 'init statsh _first_chunk');


#-- TODO - more test

