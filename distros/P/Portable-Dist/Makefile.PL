use inc::Module::Install 1.04;

all_from       'lib/Portable/Dist.pm';
requires       'File::Spec'            => winlike() ? '3.2701' : '0.80';
requires       'File::Slurp'           => '9999.13';
requires       'Object::Tiny'          => '1.04';
requires       'Params::Util'          => '0.31';
requires       'File::Find::Rule'      => '0.30';
requires       'File::IgnoreReadonly'  => '0.01';
requires       'Win32::File::Object'   => '0.01' if     winlike();
requires       'File::chmod'           => '0.32' unless winlike();
build_requires 'Test::More'            => '0.47';
build_requires 'File::Remove'          => '1.42';
build_requires 'File::Copy::Recursive' => '0.35';

WriteAll;
