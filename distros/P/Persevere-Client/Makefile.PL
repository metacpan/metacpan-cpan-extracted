use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Persevere::Client',
    VERSION_FROM      => 'lib/Persevere/Client.pm', # finds $VERSION
    PREREQ_PM         => {JSON => 2.0, LWP::UserAgent => 5.8, HTTP::Request => 5.8, HTTP::Status => 5.8, HTTP::Response => 5.8, HTTP::Cookies => 5.8, Carp => 1.0, Encode => 2.12 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Persevere/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Nathanael Anderson <wirelessdreamer @t_gm[a]il d.t c[]m>') : ()),
);
