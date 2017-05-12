package inc::NetOscarMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub { +{
    %{ super() },
    EXE_FILES => ["oscartest"],
    PL_FILES => { 'xmlcache' => 'lib/Net/OSCAR/XML/Protocol.parsed-xml' },
} };

__PACKAGE__->meta->make_immutable;
