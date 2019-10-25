package Test::BrewBuild::Constant;
use strict;
use warnings;

our $VERSION = '2.22';

require Exporter;
use base qw( Exporter );
our @EXPORT_OK = ();
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use constant {
    INSTANCE_INSTALL_TIMEOUT    => 600,
    MIN_PERL_VER                => '5.8.1',
    REPO_PREFIX                 => 'https://github.com/',
    BERRYBREW_LINK              => 'https://github.com/stevieb9/berrybrew',
    PERLBREW_LINK               => 'http://perlbrew.pl',
    BERRYBREW                   => 'berrybrew.exe',
    PERLBREW                    => 'perlbrew',
};

{
    my @const = qw(
        INSTANCE_INSTALL_TIMEOUT
        MIN_PERL_VER
        REPO_PREFIX
        BERRYBREW_LINK
        PERLBREW_LINK
        BERRYBREW
        PERLBREW
    );

    push @EXPORT_OK, @const;
}
1;
