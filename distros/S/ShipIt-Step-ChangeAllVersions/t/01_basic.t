#!perl -w

use strict;
use Test::More;
use Fatal qw(open close chdir);
use File::Spec;

my $new_version;

BEGIN{ # Fake Term::ReadLine, which is hard coded in ShipIt::Util
    package Term::ReadLine;
    sub new{ bless {}, shift }
    sub readline{ $new_version };
    $INC{'Term/ReadLine.pm'} = __FILE__;
}

use ShipIt;
use ShipIt::VC;
use ShipIt::Step::ChangeAllVersions;

chdir 't/test';

{
    package ShipIt::VC::Dummy;

    sub new { bless {} } # intentinaly one-arg bless
    sub exists_tagged_version{ 0 }

    no warnings 'redefine';
    *ShipIt::VC::new = \&ShipIt::VC::Dummy::new;
}

close STDOUT;

sub f{
    File::Spec->catfile(split /\//, $_[0]);
}


for(
    {new_version => '0.001_01', current_version => '0.001'    },
    {new_version => '0.001',    current_version => '0.001_01' },
) {
    my $stdout = '';
    open STDOUT, '>', \$stdout;

    $new_version = $_->{new_version};

    my $conf  = ShipIt::Conf->parse('.shipit');
    my $state = ShipIt::State->new($conf);

    foreach my $step( $conf->steps ){
        ok $step->run($state), $step;

        if($step->isa('ShipIt::Step::ChangeAllVersions')){
            ok $step->changed_version_variable->{f 'lib/Foo.pm'}, 'VERSION variable in Foo.pm changed';
            ok $step->changed_version_variable->{'Bar.pm'},       'VERSION variable in Bar.pm changed';
            ok $step->changed_version_variable->{f 'script/qux'}, 'VERSION variable in script/qux changed';

            ok $step->changed_version_section->{f 'lib/Foo.pm'},  'VERSION section in Foo.pm changed';
            ok $step->changed_version_section->{'Bar.pm'},        'VERSION section in Bar.pm changed';
            ok $step->changed_version_section->{'Baz.pod'},       'VERSION section in Baz.pod changed';
        }
    }

    like $stdout, qr/^Update \s+ \$VERSION/xms;
    like $stdout, qr/^Update \s+ the \s+ VERSION \s+ section/xms;

    require './lib/Foo.pm';
    require './script/qux';
    require './Bar.pm';

    if($new_version eq '0.001_01'){ # on the first step
        no warnings 'once';

        is $Foo::VERSION, $new_version, '$Foo::VERSION has been updated';
        is $Bar::VERSION, $new_version, '$Bar::VERSION has been updated';
        is $App::qux::VERSION, $new_version, '$App::qux::VERSION has been updated';

        isnt $Bar::version, $new_version, '$version is not touched';
        isnt $Bar::Version, $new_version, '$Version is not touched';
    }
}

done_testing;

