use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SDLx::Coro::REPL',
    VERSION_FROM      => 'lib/SDLx/Coro/REPL.pm', # finds $VERSION
    PREREQ_PM         => {
      SDLx::Controller::Coro => 0,
      Devel::REPL => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SDLx/Coro/REPL.pm', # retrieve abstract from module
       AUTHOR         => 'awwaiid <awwaiid@thelackthereof.org>') : ()),
);
