use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Mknod',
    'VERSION_FROM'	=> 'Mknod.pm',
    ($] >= 5.005 ?
       (AUTHOR     => 'Raoul Zwart <rlzwart@cpan.org>') : ()),
    'INC'		=> '-I.',
    'TYPEMAPS' => [qw{typemap}],
);
