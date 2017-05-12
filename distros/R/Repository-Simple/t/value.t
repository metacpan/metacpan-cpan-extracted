# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 14;

use_ok('Repository::Simple');

use IO::Scalar;

# Load repository
my $repository = Repository::Simple->attach(
    FileSystem => root => 't/root',
);
ok($repository);

# Load root node
my $root_node = $repository->root_node;
ok($root_node);

# Load properties
my %properties = map { ($_->name => $_) } $root_node->properties;
my $fs_uid = $properties{'fs:uid'};
ok($properties{'fs:uid'});

# Load value
my $value = $fs_uid->value;
ok($value);

# Check value's capabilities
can_ok($value, qw(
    get_scalar
    set_scalar
    get_handle
    set_handle
));

# Check get_scalar()
my $scalar_value = $value->get_scalar;
ok(defined $scalar_value);

# Check get_handle()
my $handle_value = $value->get_handle;
ok(defined $handle_value);
my $scalar_handle_value = join '', <$handle_value>;
ok(defined $scalar_handle_value);

# Check that get_scalar() and get_handle() are consistent
is($scalar_value, $scalar_handle_value);

# Setup some test strings for us to use
my $test_str1 =
    qq(You gonna eat your tots?\n);
my $test_str2 =
    qq(I like your sleaves; they're real big.\n);
my $test_str3 =
    qq(Your mom goes to college.\n);

# Remember the original value
my $fs_content = $repository->get_item('/foo/fs:content');
my $old_value = $fs_content->value->get_scalar;

# Check set_scalar()
$fs_content->value->set_scalar($test_str1);
$fs_content->save;
is($fs_content->value->get_scalar, $test_str1);

# Check write with get_handle()
my $fh = $fs_content->value->get_handle('>');
print $fh $test_str2;
$fs_content->save;
is($fs_content->value->get_scalar, $test_str2);

# Check set_handle()
$fh = IO::Scalar->new(\$test_str3);
$fs_content->value->set_handle($fh);
$fs_content->save;
is($fs_content->value->get_scalar, $test_str3);

# Return to normal
$fs_content->value->set_scalar($old_value);
$fs_content->save;
is($fs_content->value->get_scalar, $old_value);
