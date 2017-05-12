use strict;
use Test::More tests => 6;
#use Test::More qw(no_plan);

use SWF::ForcibleConverter;
ok( defined $SWF::ForcibleConverter::VERSION, 'defined VERSION');
isa_ok( SWF::ForcibleConverter->new, 'SWF::ForcibleConverter');

my $buf;
isa_ok( SWF::ForcibleConverter::create_io_file, 'IO::File' );
isa_ok( SWF::ForcibleConverter::create_io_handle, 'IO::Handle' );
isa_ok( SWF::ForcibleConverter::create_io_uncompress(\$buf), 'IO::Uncompress::Inflate' );
isa_ok( SWF::ForcibleConverter::create_io_compress(\$buf), 'IO::Compress::Deflate' );
