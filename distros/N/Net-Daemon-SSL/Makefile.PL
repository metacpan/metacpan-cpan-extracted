use strict;
use ExtUtils::MakeMaker;

WriteMakefile ( NAME      => 'Net::Daemon::SSL',
                VERSION   => '1.0',
                PREREQ_PM => { 'IO::Socket::SSL' => '0.73',
                               'Net::Daemon'     => '0.30' } );

package MY;

sub libscan
{
    my ( $this, $path ) = @_;
    return '' if $path =~ m/.(pl|dtd|sgml)$/;
    return '' if $path =~ m:\bCVS/:;
    return '' if $path =~ m/~$/;
    $path;
}

sub postamble {
    qq{

pm_to_blib: README

README: lib/Net/Daemon/SSL.pm
\tpod2text lib/Net/Daemon/SSL.pm >README

}
}

1;

