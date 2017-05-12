use strict;
use Test::More;
use Test::Exception;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;

my @list;

@list = pandoc->input_formats;
ok scalar @list > 5, 'input_formats';

@list = pandoc->output_formats;
ok scalar @list > 5, 'output_formats';

done_testing;
