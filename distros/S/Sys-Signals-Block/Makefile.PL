use 5.008;
use ExtUtils::MakeMaker;

eval {
    require POSIX;
    POSIX::SigSet->new;
};
if ($@) {
    die "This module requires POSIX signals.",
        "Your platform does not implement them, sorry.\n";
}

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME              => 'Sys::Signals::Block',
    VERSION_FROM      => 'lib/Sys/Signals/Block.pm',
    PREREQ_PM         => {
        'Class::Accessor' => 0,
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'POSIX'           => 0
    },
    ABSTRACT_FROM  => 'lib/Sys/Signals/Block.pm',
    AUTHOR         => 'Michael Schout <mschout@cpan.org>'
);
