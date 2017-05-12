
use Test::More;

eval "use Test::Expect";
plan skip_all => "Test::Expect required for testing" if $@;

# test pirl and its many quit commands

plan( tests => 2*6 );

unless ($ENV{TERM}) {    # help when TERM is not setup
    diag qq{TERM not set, using "dumb"};
    $ENV{TERM} = 'dumb';
}

for my $quit_command ( ':quit', ':q', ':exit', ':x', 'exit', 'quit' ) {

    expect_run(
        command => "$^X -Mblib blib/script/pirl --noornaments",
        prompt  => 'pirl @> ',
        quit    => $quit_command,
    );

    expect_like(
        qr/\A
           (?: Using .*? blib \n )?   # cope with noisy 5.6 blib
           Welcome
          /msx,
        "welcome message"
   );

}
