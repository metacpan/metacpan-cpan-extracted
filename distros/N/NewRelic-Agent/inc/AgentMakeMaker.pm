package inc::AgentMakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

use File::Spec;

override _build_WriteMakefile_args => sub {
    my ($self) = @_;

    my $curdir = File::Spec->curdir;
    my $sdk    = File::Spec->catdir($curdir, 'sdk');

    my $CC  = 'g++';
    my @INC = (
        $curdir,
        File::Spec->catdir($sdk, 'include'),
    );

    my $sdklib = File::Spec->catdir($sdk, 'lib');

    my @LIBS = map {
        "-L$sdklib -l$_"
    } qw/newrelic-common newrelic-collector-client newrelic-transaction/;

    return +{
        %{ super() },
        depend        => { 'WithAgent.c' => 'NewRelic-Agent.xsp' },
        CC            => $CC,
        INC           => join(' ', map { "-I$_" } @INC),
        LD            => '$(CC)',
        LIBS          => join(' ', @LIBS),
        OBJECT        => '$(O_FILES)',
        PMLIBDIRS     => ['lib', '$(BASEEXT)', $sdklib],
        XSOPT         => '-C++ -hiertype',
    };
};

__PACKAGE__->meta->make_immutable;
