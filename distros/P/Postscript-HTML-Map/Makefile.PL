use inc::Module::Install;

# Define metadata
name   		'Postscript-HTML-Map';

# Specific dependencies
requires 'HTML::Element';
requires 'Math::Bezier';

version_from 'lib/Postscript/HTML/Map.pm';

auto_install;
WriteAll;
