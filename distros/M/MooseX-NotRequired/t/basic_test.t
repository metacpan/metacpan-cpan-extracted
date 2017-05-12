use Test::Most;

use FindBin;
use lib "$FindBin::Bin/lib";

use ObjectA;
use MooseX::NotRequired;

throws_ok {
    my $old_class = ObjectA->new();
} qr'Attribute.*is required'i, 'Type constraints still work on original class';

my $o = ObjectA->new({ required => 'a', optional => 3 });
my $new_class = MooseX::NotRequired::make_optional_subclass('ObjectA');
ok my $no = $new_class->new({ optional => 4, semi_required => undef});
is $no->optional, 4;
ok !$no->required;

# check required constraint works
throws_ok {
    my $old_class = ObjectA->new();
} qr'Attribute.*is required'i, 'Type constraints still work on original class';

# check setting Str to undef blows up
throws_ok {
    my $old_class = ObjectA->new({ required => 'a', semi_required => undef });
} qr'does not pass the type constraint because'i, 'Type constraints still work on original class';

# the new class should also barf on the type constraint for required.
throws_ok {
    my $new_obj = $new_class->new({ optional => 'a', required => 'a', semi_required => undef });
} qr'does not pass the type constraint because'i, 'Type constraints still work on original class';

done_testing;

