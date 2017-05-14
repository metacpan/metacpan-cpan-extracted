use inc::Module::Install 0.46;

name('OpenGL-QEng');
license('Perl');
#requires(perl => '5.8.3');
requires('OpenGL' => 0.54);
requires('OpenGL::Image');
requires('Math::Trig');
requires('Image::Magick' => '6.3.5');
requires('File::ShareDir');
test_requires('Test::More' => '0.47');

no_index( directory => qw< QEng auto html Attic > );

version_from('quest');
all_from('lib/Games/Quest3D.pm');

install_script('quest');
install_share('maps');
install_share('images');

WriteAll;

