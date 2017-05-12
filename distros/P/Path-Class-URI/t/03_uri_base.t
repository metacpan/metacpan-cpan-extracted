use strict;
use Test::Base;

use Path::Class;
use Path::Class::URI;
plan tests => 2 * blocks;

filters 'chomp';
filters { input => 'eval' };

run {
    my $block = shift;
    my $f = 'file';
    my $base_path = $block->input;
    my $abs = URI->new_abs($f, $base_path->uri);
    is $abs, $block->expected;

    my $abs_path = file_from_uri($abs);
    is $abs_path, file($block->abs_path);
};

__END__

===
--- input
Path::Class::dir('/path/to');
--- expected
file:///path/to/file
--- abs_path
/path/to/file

===
--- input
Path::Class::file('/path/to/other_file');
--- expected
file:///path/to/file
--- abs_path
/path/to/file
