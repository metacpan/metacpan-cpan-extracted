use inc::Module::Install;

name('Task-Math-Symbolic');
abstract('Math::Symbolic with lots of plugins');
author('Steffen Mueller');
version_from('lib/Task/Math/Symbolic.pm');
license('perl');
build_requires('Test::Pod' => 1.00);
build_requires('Test::Pod::Coverage' => 1.00);

requires('perl' => 5.006);
requires('Math::Symbolic' => 0.163);
requires('Math::Symbolic::Custom::Contains');
requires('Math::Symbolic::Custom::ErrorPropagation');
requires('Math::Symbolic::Custom::Pattern');
requires('Math::Symbolic::Custom::Simplification');
requires('Math::Symbolic::Custom::Transformation');
requires('Math::SymbolicX::BigNum');
requires('Math::SymbolicX::Complex');
requires('Math::SymbolicX::Inline');
requires('Math::SymbolicX::NoSimplification');
requires('Math::SymbolicX::ParserExtensionFactory');
requires('Math::SymbolicX::Statistics::Distributions');
recommends('Math::Symbolic::Custom::CCompiler');
auto_install();
#&WriteMakefile;
&WriteAll(sign=>1);
