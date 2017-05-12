use inc::Module::Install;

#die "This RT Extension will kill your pets and steal your valuables. DO NOT USE IT YET";
RTx ('RT-Interface-Email-Filter-CheckMessageId');
author ('Olivier Thauvin <nanardon@nanardon.zarb.org>');
license('perl');

build_requires('Test::More');
build_requires('IPC::Open2');

# the patch for RT-3.4.5 has this requirement
# RT may be require it too, but put it here to be sure 
requires('UNIVERSAL::require');
requires('MIME::Entity' => '5.420');
auto_install();

sign;
WriteAll();
