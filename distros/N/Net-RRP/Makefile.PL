use strict;
use ExtUtils::MakeMaker;

WriteMakefile ( NAME      => 'Net::RRP',
                VERSION   => '0.05',
                PREREQ_PM => { 'IO::Socket::SSL'   => '0.73',
                               'Net::Daemon::SSL'  => '1.00',
                               'Proc::Application' => '0.01' } );

package MY;

sub libscan
{
    my ( $this, $path ) = @_;
    return '' if $path =~ m/.(pl|dtd|sgml)$/;
    return '' if $path =~ m:\bCVS/:;
    return '' if $path =~ m/~$/;
    $path;
}

1;

