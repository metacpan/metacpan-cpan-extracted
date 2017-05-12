use inc::Module::Install 0.77;

all_from      'lib/Template/Plugin/Tooltip.pm';
requires      'Scalar::Util'              => '1.15';
requires      'Template'                  => '2.10';
requires      'HTML::Tooltip::Javascript' => '0.03';
test_requires 'Test::More'                => '0.47';
test_requires 'File::Spec'                => '0.80';

WriteAll;
