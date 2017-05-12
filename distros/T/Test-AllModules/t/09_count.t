use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {
    all_ok(
        search_path => 'MyApp',
        lib => [ File::Spec->catfile('t','lib') ],
        check => +{
            'count' => sub {
                my ($class, $count) = @_;
                return $class && $count =~ m!^\d$!;
            },
        },
    );
}
