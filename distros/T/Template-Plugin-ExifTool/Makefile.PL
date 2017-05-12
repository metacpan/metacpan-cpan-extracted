use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::ExifTool',
    'VERSION_FROM' => 'lib/Template/Plugin/ExifTool.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Template => 2.14,
	Image::ExifTool => 4.36,
    },
);
