use strict;
use warnings;
use Test::More;

BEGIN {
    require Object::Proto;

    Object::Proto::register_type('TrimmedStr',
        sub { defined $_[0] && !ref $_[0] },
        sub { my $v = $_[0]; $v =~ s/^\s+|\s+$//g; $v }
    );

    Object::Proto::define('SlotInfoTest',
        'name:Str:required',
        'age:Int:default(0)',
        'bio:Str:lazy:builder(_build_bio)',
        'tag:Str:readonly',
        'label:TrimmedStr',
        'notes:Str:clearer:predicate',
    );
}

use Object::Proto;

# --- name slot ---
my $name_info = Object::Proto::slot_info('SlotInfoTest', 'name');
ok(ref $name_info eq 'HASH', 'slot_info returns hashref');
is($name_info->{type}, 'Str', 'name type is Str');
ok($name_info->{is_required}, 'name is required');
ok(!$name_info->{is_readonly}, 'name is not readonly');

# --- age slot ---
my $age_info = Object::Proto::slot_info('SlotInfoTest', 'age');
is($age_info->{type}, 'Int', 'age type is Int');
ok(!$age_info->{is_required}, 'age is not required');
ok($age_info->{has_default}, 'age has default');

# --- bio slot (lazy + builder) ---
my $bio_info = Object::Proto::slot_info('SlotInfoTest', 'bio');
ok($bio_info->{is_lazy}, 'bio is lazy');
ok($bio_info->{has_builder}, 'bio has builder');
is($bio_info->{builder}, '_build_bio', 'bio builder name correct');

# --- tag slot (readonly) ---
my $tag_info = Object::Proto::slot_info('SlotInfoTest', 'tag');
ok($tag_info->{is_readonly}, 'tag is readonly');

# --- label slot (custom type) ---
my $label_info = Object::Proto::slot_info('SlotInfoTest', 'label');
is($label_info->{type}, 'TrimmedStr', 'label type is TrimmedStr');
ok($label_info->{has_type}, 'label has_type flag set');

# --- notes slot (clearer + predicate) ---
my $notes_info = Object::Proto::slot_info('SlotInfoTest', 'notes');
ok($notes_info->{has_clearer}, 'notes has clearer');
ok($notes_info->{has_predicate}, 'notes has predicate');

# --- nonexistent slot returns undef ---
my $nope = Object::Proto::slot_info('SlotInfoTest', 'nonexistent');
ok(!defined $nope, 'nonexistent slot returns undef');

# --- nonexistent class returns undef ---
my $bad_class = Object::Proto::slot_info('NoSuchClass', 'whatever');
ok(!defined $bad_class, 'nonexistent class returns undef');

done_testing;
