configure_requires 'ExtUtils::MakeMaker::CPANfile';

requires 'parent';
requires 'X::Tiny';
requires 'Module::Runtime';
requires 'Call::Context';
requires 'IO::Framed' => 0.16;
requires 'IO::SigGuard';
requires 'Promise::ES6';

# Perl 5.10.1 ships 1.82, which mishandles
# abstract-namespace Linux sockets.
# … and pre-2.011 mishandled UNIX socket length
# on cygwin.
requires Socket => 2.011;

test_requires 'autodie';
test_requires 'FindBin';
test_requires 'File::Which';
test_requires 'Test::Exception';
test_requires 'Test::More';
test_requires 'Test::Deep';
test_requires 'Test::FailWarnings';
test_requires 'Test::SharedFork';
