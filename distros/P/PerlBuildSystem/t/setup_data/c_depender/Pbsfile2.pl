
PbsUse('Configs/Compilers/gcc');
PbsUse('Rules/C');

AddRule 'test-c', [ 'test-c.exe' => '1.o', '2.o' ]
	=> '%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
