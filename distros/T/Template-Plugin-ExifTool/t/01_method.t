use strict;
use Template::Test;
use Template::Plugin::ExifTool;

# file is not specified
eval {
    my $image = Template::Plugin::ExifTool->new() or
	die Template::Plugin::ExifTool->error;
};
chomp($@);
is($@, "file is not specified at t/01_method.t line 7.");

# No such file
my $file = './t/nonexist.jpg';
eval {
    my $image = Template::Plugin::ExifTool->new('context', $file) or
	die Template::Plugin::ExifTool->error;
};
chomp($@);
is($@, "$file: No such file at t/01_method.t line 16.");

# tmpl test
test_expect(\*DATA);

__END__
--test--
[% USE image = ExifTool('./t/sky.jpg') -%]
[% image.GetInfo('Make').Make %]
--expect--
DoCoMo

--test--
[% USE image = ExifTool('./t/sky.jpg') -%]
[% image.info.ImageHeight %] [% image.info.ImageWidth %]
--expect--
266 240

