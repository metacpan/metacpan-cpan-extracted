use Test::Most;
use OpusVL::Text::Util qw/mask_text/;

is mask_text('*', '(\d{4}).*(\d{3})', '456456564654654'), '4564********654', 'Mask card';
is mask_text('*', '.(\d{4}).*(\d{3}).', '456456564654654'), '*5645******465*', 'Mask card';

is mask_text('*', '(\d{4}).*(\d{3})', 'rabbits'), '*******', 'fail secure';
is mask_text('*', '(.*)', 'rabbits'), 'rabbits', 'No op';

my $multiline = << "DONE";
A multi line value.
Works fine.
DONE

is mask_text('*', '(.*)', $multiline), $multiline, 'Should be able to deal with multi-line values';

done_testing;
