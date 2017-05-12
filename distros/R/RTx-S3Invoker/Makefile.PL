use inc::Module::Install;

author('Jerrad Pierce <jpierce@cpan.org>');
abstract('Make it easier to access saved searches');
license('perl');

#requires 'RT' => 0;
RTx('RTx-S3Invoker');
WriteAll();

#perl -Mlib=lib -MRTx::S3Invoker -e 'print $RTx::S3Invoker::VERSION'
sub MY::postamble {
    return <<'EOHACK';
dist : predist distcheck
	@echo "Forced dependencies, ignore make's carping about overriding"
predist: all
	pod2readme lib/RTx/S3Invoker.pm > README
EOHACK
}
