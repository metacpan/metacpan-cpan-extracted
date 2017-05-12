use Test::More tests => 18;
use strict;
use warnings;

BEGIN { use_ok("Querylet::Query"); }

my $q = new Querylet::Query;

$q->bind(1,2,3);
is_deeply($q->{bind_parameters}, [ 1, 2, 3],    "bind parameters set nicely");

$q->bind_more(4,5,6);
is_deeply($q->{bind_parameters}, [1,2,3,4,5,6], "bind parameters push nicely");

is($q->output_filename,                undef, "no output filename defined");
is($q->output_filename('xyz.txt'), 'xyz.txt', "filename set properly");
is($q->output_filename,            'xyz.txt', "filename retrieved");
is($q->output_filename(undef),         undef, "filename unset");
is($q->output_filename,                undef, "no output filename defined");

is($q->output_type,                'csv', "default output format");
is($q->output_type('xyz'),         'xyz', "format set properly");
is($q->output_type,                'xyz', "format retrieved");
is($q->output_type(undef),         undef, "format unset");
is($q->output_type,                undef, "no output format defined");

is($q->input_type,                'term', "default input format");
is($q->input_type('xyz'),          'xyz', "format set properly");
is($q->input_type,                 'xyz', "format retrieved");
is($q->input_type(undef),          undef, "format unset");
is($q->input_type,                 undef, "no input format defined");
