use strict;
use warnings;

use inc::Module::Install;

name 'MooseX-ExpiredAttribute';
abstract 'Expired and auto rebuilded attributes in Moose objects';

author 'Perlover <perlover@perlover.com>';
version_from 'lib/MooseX/ExpiredAttribute.pm';

auto_set_repository;
license 'perl';

requires 'Moose' => 2.1204;

build_requires 'Test::More';

WriteAll();

package MY;

sub distdir {
    my $inherited = shift->SUPER::distdir(@_);
    $inherited =~ s/^(create_distdir\s.*)/$& README/m;
    $inherited .= "README : lib/MooseX/ExpiredAttribute.pm\n\tperldoc -t \$< > \$@\n";
    return $inherited;
}
