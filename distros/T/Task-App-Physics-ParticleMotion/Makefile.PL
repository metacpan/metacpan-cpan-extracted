use inc::Module::Install;

name('Task-App-Physics-ParticleMotion');
abstract('All modules required for the tk-motion application');
author('Steffen Mueller');
version_from('lib/Task/App/Physics/ParticleMotion.pm');
license('perl');
build_requires('Test::Pod' => 1.00);
build_requires('Test::Pod::Coverage' => 1.00);

requires('perl' => 5.006001);
requires('Math::Symbolic' => 0.163);
requires('Config::Tiny');
requires('Math::Project3D');
requires('Math::RungeKutta');
requires('Tk');
requires('Tk::Cloth');
requires('App::Physics::ParticleMotion');

auto_install();
&WriteAll();
