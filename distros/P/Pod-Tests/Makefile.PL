use inc::Module::Install 0.75;

all_from       'lib/Pod/Tests.pm';
requires       'Test::More'    => '0.33';
requires       'Test::Harness' => '1.22';
install_script 'pod2test';

# Generate tests via pod2test to be run later
print "Running pod2test...\n";
system(qq{$^X "-Ilib" script/pod2test t/02_tests.t t/03_pod2test.t});
system(qq{$^X "-Ilib" script/pod2test t/foo t/i_should_not_be_written.t});

WriteAll;
