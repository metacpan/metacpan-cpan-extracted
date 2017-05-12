use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Rose::DBx::Garden::Catalyst',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/Rose/DBx/Garden/Catalyst.pm',
    ABSTRACT_FROM => 'lib/Rose/DBx/Garden/Catalyst.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                                => 0,
        'Rose::DBx::Garden'                         => '0.190',
        'Rose::DB::Object'                          => 0.770,
        'Rose::DBx::Object::MoreHelpers'            => 0.06,
        'Rose::DBx::AutoReconnect'                  => 0,
        'Rose::HTMLx::Form::Related'                => 0.12,
        'CatalystX::CRUD'                           => 0.43,
        'CatalystX::CRUD::YUI'                      => 0.017,
        'CatalystX::CRUD::Model::RDBO'              => 0.20,
        'Catalyst'                                  => 5.7,
        'Catalyst::Plugin::Static::Simple::ByClass' => 0,
        'Data::Dump'                                => 0,
        'Tree::Simple'                              => 0,
        'Tree::Simple::Visitor::ToNestedHash'       => 0,
        'IPC::Cmd'                                  => 0,
        'MRO::Compat'                               => 0,
        'Class::C3'                                 => 0,
        'File::Slurp::Tiny'                         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => {
        FILES => 'Rose-DBx-Garden-Catalyst-* t/lib/MyRDGC/lib/MyRDBO*
                                       t/lib/MyRDGC/lib/MyRDGC/Controller/CRUD*
                                       t/lib/MyRDGC/lib/MyRDGC/Model/*
                                       t/lib/MyRDGC/lib/MyRDGC/Base
                                       t/lib/MyRDGC/lib/MyRDGC/View/*
                                       t/lib/MyRDGC/root/crud 
                                       t/lib/MyRDGC/root/rdgc
                                       t/lib/MyRDGC/root/static

                            '
    },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44
        ? ()
        : ( META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/rose-dbx-garden-catalyst',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Garden-Catalyst',
                    repository =>
                        'https://github.com/karpet/rose-dbx-garden-catalyst',
                },
            }
        )
    ),
);
