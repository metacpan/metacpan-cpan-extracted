use Test::More;
use SQL::Load::Util qw/
    name_list
/;

my @name_list_1 = name_list('foo_bar');
for my $name (@name_list_1) {
    like($name, qr/(FooBar|foo_bar|foo-bar)/, 'Test ' . $name . ' name to name_list_1 with foo_bar');
}

my @name_list_2 = name_list('baz-foo');
for my $name (@name_list_2) {
    like($name, qr/(BazFoo|baz_foo|baz-foo)/, 'Test ' . $name . ' name to name_list_2 with baz-foo');
}

my @name_list_3 = name_list('BarFoo');
for my $name (@name_list_3) {
    like($name, qr/(BarFoo|bar_foo|bar-foo)/, 'Test ' . $name . ' name to name_list_3 with BarFoo');
}

my $name_list_4 = name_list('folder/foo_bar');
for my $name (@$name_list_4) {
    like($name, qr!(Folder/FooBar|folder/foo_bar|folder/foo-bar)!, 'Test ' . $name . ' name to name_list_4 with folder/foo_bar');
}

my $name_list_5 = name_list('users/read');
for my $name (@$name_list_5) {
    like($name, qr!(Users/Read|users/read)!, 'Test ' . $name . ' name to name_list_5 with users/read');
}

my $name_list_6 = name_list('admin/users/find-all.sql');
for my $name (@$name_list_6) {
    like($name, qr!(Admin/Users/FindAll|admin/users/find_all|admin/users/find-all)!, 'Test ' . $name . ' name to name_list_6 admin/users/find-all.sql');
}

done_testing;
