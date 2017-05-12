
use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker;

my %prereq_pm = ( 'Test::More' => '1.302026' );

if ($^O eq 'MSWin32') {
    $prereq_pm{'Win32::API'} = '0.77';
    $prereq_pm{'Win32::TieRegistry'} = '0';
}

WriteMakefile( NAME          => 'Net::SSH::Any',
               VERSION_FROM  => 'lib/Net/SSH/Any.pm',
               PREREQ_PM     => \%prereq_pm,
               ABSTRACT_FROM => 'lib/Net/SSH/Any.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
               META_MERGE    => {
                   resources => {
                       repository => 'https://github.com/salva/p5-Net-SSH-Any', } },
             );

