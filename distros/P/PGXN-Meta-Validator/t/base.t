use strict;
use warnings;
use Test::More tests => 28;
use File::Spec;

BEGIN {
    use_ok 'PGXN::Meta::Validator' or die;
}

my $file = File::Spec->catfile(qw(t META.json));

my $data = JSON->new->decode(do {
    local $/;
    open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
    <$fh>;
});

ok my $pmv = PGXN::Meta::Validator->new($data), 'Construct from data structure';
ok $pmv->is_valid, 'Structure should be valid';

ok $pmv = PGXN::Meta::Validator->load_file($file), 'Load from file';
ok $pmv->is_valid, 'File should be valid';

local $@;
eval {
    PGXN::Meta::Validator->load_file('nonexistent');
};
like $@, qr{^load_file\(\) requires a valid, readable filename},
    'Should catch exception for nonexistent file';

eval {
    PGXN::Meta::Validator->load_file('Changes');
};
like $@, qr{^malformed JSON string},
    'Should catch exception for invalid JSON';

# Make sure there's no autovivication.
delete $data->{no_index};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no no_index';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{no_index}, 'Should still have no no_index key';

delete $data->{prereqs}{runtime}{requires};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no requires';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{prereqs}{runtime}{requires}, 'Should still have no requires key';

delete $data->{prereqs}{runtime};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no runtime';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{prereqs}{runtime}, 'Should still have no runtime key';

delete $data->{prereqs};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no prereqs';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{prereqs}, 'Should still have no prereqs key';

delete $data->{resources}{bugtracker};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no bugtracker';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{resources}{bugtracker}, 'Should still have no bugtracker key';

delete $data->{resources}{repository};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no repository';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{resources}{repository}, 'Should still have no repository key';

delete $data->{resources};
ok $pmv = PGXN::Meta::Validator->new($data), 'Construct with no resources';
ok $pmv->is_valid, 'Structure should be valid';
ok !exists $data->{resources}, 'Should still have no resources key';
