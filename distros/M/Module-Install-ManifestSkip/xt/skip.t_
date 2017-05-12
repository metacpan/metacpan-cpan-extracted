use TestML -run, -dev_test;

__DATA__
%TestML 1.0

Plan = 7;

Chdir('t/sample1');
RunCommand('make purge');
RunCommand('perl Makefile.PL');
RunCommand('make manifest');
manifest = Read('MANIFEST');

Label = 'MANIFEST has';
manifest ~~ "Makefile.PL";
manifest ~~ "lib/Sample1.pm";
manifest ~~ "MANIFEST";

Label = 'Manifest contains';
manifest.Has("MANIFEST.SKIP").Not.OK;
manifest.Has("ToDo").Not.OK;
manifest.Has(".DS_Store").Not.OK;
manifest.Has("Foo~").Not.OK;

RunCommand('make purge');
RunCommand('rm MANIFEST.SKIP');
