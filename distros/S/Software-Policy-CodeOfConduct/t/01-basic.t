
use v5.20;
use warnings;

use Test2::V0;

use Test::File::ShareDir -share => {
    -module => {
        "Software::Policy::CodeOfConduct" => "share"
    }
};

use Software::Policy::CodeOfConduct;

ok my $policy = Software::Policy::CodeOfConduct->new( contact => 'bogon@example.com' ), 'constructor';

ok $policy->template_path, "template_path";

ok $policy->text, "text";

note $policy->text;

done_testing;
