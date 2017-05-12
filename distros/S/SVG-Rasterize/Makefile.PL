use inc::Module::Install;

name     'SVG-Rasterize';
all_from 'lib/SVG/Rasterize.pm';
author   q{Lutz Gehlen <perl@lutzgehlen.de>};
license  'perl';

no_index directory => 'examples';

requires           'Class::Accessor'  => '0.30';
configure_requires 'Cairo'            => '1.061';
configure_requires 'Pango'            => '1.220';
requires           'Params::Validate' => '0.91';
requires           'Scalar::Util'     => '1.19';
requires           'Exception::Class' => '1.29';

test_requires      'SVG'              => '2.37';
test_requires      'Test::More'       => '0.80';
test_requires      'Test::Exception'  => '0.27';
test_requires      'Test::Warn'       => '0.08';

# for systems not supporting configure_requires we require Pango
# within an eval statement
if(eval { require Cairo }) {
    if(Cairo->VERSION < Cairo->VERSION_ENCODE (1, 8, 8)) {
	print("SVG::Rasterize requires the Cairo C library at least ",
	      "in version 1.8.8. Please upgrade.\n");
	print(STDERR "NA: Unable to build distribution on this ".
	      "platform.\n");
	exit(0);
    }
}
else {
    print("The execution of the SVG::Rasterize Makefile.PL requires ", 
	  "the presence of the Cairo module. Your system does not seem ",
	  "to support configure_requires entries in META.YML. Please ".
	  "install Cairo before installing SVG::Rasterize.\n");
    print(STDERR "NA: Unable to build distribution on this ".
	  "platform.\n");
    exit(0);
}

# for systems not supporting configure_requires we require Pango
# within an eval statement
if(eval { require Pango }) {
    if(!Pango->CHECK_VERSION(1, 22, 4)) {
	print("SVG::Rasterize requires the Pango C library at least ",
	      "in version 1.22.4. Please upgrade.\n");
	print(STDERR "NA: Unable to build distribution on this ".
	      "platform.\n");
	exit(0);
    }
}
else {
    print("The execution of the SVG::Rasterize Makefile.PL requires ", 
	  "the presence of the Pango module. Your system does not seem ",
	  "to support configure_requires entries in META.YML. Please ".
	  "install Pango before installing SVG::Rasterize.\n");
    print(STDERR "NA: Unable to build distribution on this ".
	  "platform.\n");
    exit(0);
}

WriteAll;
