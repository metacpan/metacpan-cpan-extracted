use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::QMQP',
    'VERSION_FROM' => 'QMQP.pm', # finds $VERSION
    'PREREQ_PM' => {'Class::Accessor' => 0,'IO::Socket' => 0}
);
