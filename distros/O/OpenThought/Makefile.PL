use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
#use ExtUtils::AutoInstall (
#    'Dependencies for the Demo Application (optional)' => [
#        'Apache::Session'     => '',
#        'HTML::Template'      => '',
#    ],
#);

require ExtUtils::AutoInstall;

my @version;
if($] >= 5.00503) {
    push @version, "Dependencies for version/api checks, could make upgrades less painful (optional)";
    push @version, [ -default => 0, 'version' => '', 'version::Limit' => '0.03' ];
}

ExtUtils::AutoInstall->import(
    'Dependencies for the Demo Application (optional)' => [
        'Apache::Session'     => '',
        'HTML::Template'      => '',
    ],
    @version,
);

WriteMakefile(
    NAME                => 'OpenThought',
    DISTNAME            => 'OpenThought',
    AUTHOR              => 'Eric Andreychek <eric@openthought.net>',
    VERSION_FROM        => 'lib/OpenThought.pm',
    ABSTRACT_FROM       => 'lib/OpenThought.pm',
);

