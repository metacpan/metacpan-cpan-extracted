use Speech::Synthesis;
use Test::More;
use strict;
use warnings;
use Data::Dumper;
my @engines = Speech::Synthesis->InstalledEngines();
plan skip_all => "No Speech Engines installed" unless @engines;
my $tests = 0;
foreach my $engine (@engines)
{
    my @voices = Speech::Synthesis->InstalledVoices(engine => $engine,
                                                    host   => $ENV{FESTIVAL_HOST},
                                                    port   => $ENV{FESTIVAL_PORT});
    $tests+= scalar(@voices);
}
plan(tests => $tests) if $tests;
plan skip_all => "No voices can be found" unless $tests;

foreach my $engine (@engines)
{
    diag("Now testing $engine");
    diag("You can safely ignore the 'No such interface supported' messages for the TruVoice voices") if $engine eq 'SAPI4';
    my @voices = Speech::Synthesis->InstalledVoices(engine => $engine,
                                                    host   => $ENV{FESTIVAL_HOST},
                                                    port   => $ENV{FESTIVAL_PORT});
    my @avatars = Speech::Synthesis->InstalledAvatars(engine => $engine,
                                                      host   => $ENV{FESTIVAL_HOST},
                                                      port   => $ENV{FESTIVAL_PORT});
    foreach my $voice (@voices)
    {
        my %params = (  engine   => $engine,
                        avatar   => @avatars ? $avatars[0] : undef,
                        language => $voice->{language},
                        voice    => $voice->{id},
                        async    => 0,
                        host     => $ENV{FESTIVAL_HOST},
                        port     => $ENV{FESTIVAL_PORT}
                        );
        my $ss = Speech::Synthesis->new( %params );
        isa_ok($ss, 'Speech::Synthesis');
        $ss->speak($voice->{description}||"test");
        sleep($engine eq 'MSAgent'? 5 : 1);
    }
}