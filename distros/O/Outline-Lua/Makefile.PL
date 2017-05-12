
use inc::Module::Install;
use ExtUtils::PkgConfig;

name      'Outline-Lua';
all_from  'lib/Outline/Lua.pm';
author    'Alastair Douglas <altreus@perl.com>';
version   '0.11';

my (%liblua, %liblualib, $cflags, $libs);

if(eval { 
    %liblua = ExtUtils::PkgConfig->find('lua50');
    %liblualib = ExtUtils::PkgConfig->find('lualib50') }
  ) {
  $cflags = $liblua{cflags};
  $libs   = $lublua{libs};
  $cflags .= ' ' . $liblualib{cflags};
  $libs .= ' ' . $liblualib{libs};
}
else {
  checklibs      lib => 'lua', header => 'lua.h';
}
checklibs      lib => 'm';
checklibs      lib => 'dl';

configure_requires "ExtUtils::PkgConfig" => 1.12;

build_requires  'Test::More';
build_requires  'Test::Class';

requires  'List::Util';
requires  'Scalar::Util';
requires  'overload';

makemaker_args( LIBS => q( -lm -ldl -llua ) );

auto_provides;
auto_install;


WriteMakefile(INC => $cflags, LIBS => $libs);
