use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Example::Plan qw(validate_plan);
my $root = '/srv/example';
my $input = {name => 'app_1', path => "$root/config.ini", content => "enabled=true\n"};
my $plan = validate_plan($input, $root);
is_deeply($plan, $input, 'valid plan retained');
isnt($plan, $input, 'returns independent hash');
is($input->{path}, "$root/config.ini", 'input is unchanged');
for my $path ('relative', '/etc/config', '/srv/example-other/config',
              '/srv/example/../secret', '/srv/example/./secret',
              '/srv/example//secret', '/srv/example/', "/srv/example/a\0b") {
    my $ok = eval { validate_plan({%$input, path => $path}, $root); 1 };
    ok(!$ok, "rejects invalid path: " . ($path =~ /\0/ ? 'NUL case' : $path));
}
for my $bad ({%$input, unknown => 1}, {%$input, name => 'BAD;name'},
             {%$input, content => []}, {%$input, content => undef},
             {%$input, content => 'x' x 65537}) {
    ok(!eval { validate_plan($bad, $root); 1 }, 'rejects invalid plan data');
}
ok(!eval { validate_plan([], $root); 1 }, 'rejects non-hash input');
ok(!eval { validate_plan($input, '/'); 1 }, 'rejects filesystem root as approval boundary');
my $empty = validate_plan({%$input, content => ''}, "$root/");
is($empty->{content}, '', 'empty content is legitimate');
done_testing;
