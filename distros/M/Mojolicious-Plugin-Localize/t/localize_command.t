#!usr/bin/env perl
use Mojolicious::Lite;
use Mojolicious::Commands;
use Data::Dumper;
use Test::Output qw/:stdout :stderr :functions/;
use Test::More;
use Test::Mojo;
use Mojo::Util qw/decode encode/;
use File::Temp 'tempdir';

my $t = Test::Mojo->new;
my $app = $t->app;
$app->moniker('localizetest');

my $dir = tempdir CLEANUP => 1;
chdir $dir;

$ENV{MOJO_LOCALIZE_DEBUG} = 0;

use_ok('Mojolicious::Plugin::Localize::Command::localize');
my $dict = Mojolicious::Plugin::Localize::Command::localize->new;
$dict->app($app);

like($dict->usage, qr/Usage: APPLICATION/, 'Usage');

my ($cmds, $stdout, $template, $filename);

$app->plugin('Localize' => {
  dict => {
    welcome => {
      _ => sub { $_->locale },
      en => 'Welcome!',
      de => 'Willkommen!'
    },
    thankyou => {
      _ => sub { $_->locale },
      en => '»Thank you!«',
      de => '»Danke!«',
      fr => '»Merci!«'
    },
    _ => sub { $_->locale },
    de => {
      bye => 'Auf Wiedersehen!',
      user => {
        _ => sub { [qw/technical communitiy/] },
        technical => 'Nutzer',
        community => 'Mitglied'
      }
    },
    en => {
      bye => 'Good bye!'
    },
    fr => {
      hello => 'Bonjour!'
    },
    Q => {
      _ => sub { 'example1' },
      example1 => {
        query => 'Baum'
      },
      example2 => {
        query => 'Garten'
      }
    }
  }
});

$cmds = $app->commands;

like(
  join(' ', @{$cmds->namespaces}),
  qr!Mojolicious::Command!,
  'Namespace is set'
);

like(
  join(' ', @{$cmds->namespaces}),
  qr!Mojolicious::Plugin::Localize::Command!,
  'Namespace is set'
);

stdout_like(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;
    $cmds->run;
  },
  qr/localize/,
  'Show generate'
);

stdout_like(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;
    $cmds->run('localize');
  },
  qr/app\.pl localize/,
  'SYNOPSIS'
);

# {
#   # welcome_fr => 'Welcome!',
#   # fr_bye => 'Good bye',
#   # # fr_user_technical => '',
#   # # fr_user_community => ''
# }

$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'fr', '--base' => 'en');
  }
);

like($stdout, qr/localizetest\.fr\.dict/, 'Correctly written');

$template = $dict->rel_file('localizetest.fr.dict')->slurp;

like($template, qr/\"welcome_fr\"\s*=\>\s*\"Welcome!\"/, 'welcome_fr');
like($template, qr/\"fr_bye\"\s*=\>\s*\"Good bye!\"/, 'fr_bye');
unlike($template, qr/\"thankyou_fr\"/, 'thankyou_fr');

# Reset dictionary
%{$app->localize->dictionary} = ();

# Use synopsis dictionary
$app->plugin('Localize' => {
  dict => {
    _ => sub { $_->locale },
    de => {
      welcome => 'Willkommen!',
      thankyou => '»Danke!«'
    },
    fr => {
      thankyou => '»Merci!«'
    },
    -en => {
      welcome => 'Welcome!',
      thankyou => '»Thank you!«',
    },
    MyPlugin => {
      bye => {
        _ => sub { $_->locale },
        de => 'Auf Wiedersehen!',
        en => 'Good bye!'
      },
      user => {
        _ => sub { $_->locale },
        de => 'Nutzer'
      }
    }
  }
});

$filename = 'mydict';

# Use en as base
$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'fr', '--base' => 'en', '--output' => $filename);
  }
);

like($stdout, qr/mydict/, 'Correctly written');
$template = $dict->rel_file($filename)->slurp;

like($template, qr/\"fr_welcome\"\s*=\>\s*\"Welcome!\"/, 'welcome_fr');
like($template, qr/\"MyPlugin_bye_fr\"\s*=\>\s*\"Good bye!\"/, 'fr_bye');
unlike($template, qr/\"fr_thankyou\"/, 'No merci');

$filename = 'mydict2';

# Use en as base
$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'fr', '-b' => 'de', '-o' => $filename);
  }
);

like($stdout, qr/mydict2\" written/, 'Correctly written');

# Do it again - but the file exists already
my $stderr = stderr_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'ro', '-b' => 'de', '-o' => $filename);
  }
);

like($stderr, qr/mydict2\" already exists and is not/, 'Not overwritten');

$template = $dict->rel_file($filename)->slurp;

like($template, qr/\"fr_welcome\"\s*=\>\s*\"Willkommen!\"/, 'welcome_fr');
like($template, qr/\"MyPlugin_bye_fr\"\s*=\>\s*\"Auf Wiedersehen!\"/, 'fr_bye');
like($template, qr/\"MyPlugin_user_fr\"\s*=\>\s*\"Nutzer\"/, 'fr_bye');
unlike($template, qr/\"fr_thankyou\"/, 'No merci');

$app->plugin('Localize' => {
  dict => {
    fr_welcome => 'Bienvenue!'
  }
});

$filename = 'mydict3';

# Use en as base
$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the german dictionary
    $cmds->run('localize', 'fr', '-b' => 'de', '-o' => $filename);
  }
);

like($stdout, qr/mydict3\" written/, 'Correctly written');
$template = $dict->rel_file($filename)->slurp;

unlike($template, qr/\"fr_welcome\"/, 'welcome_fr');
like($template, qr/\"MyPlugin_bye_fr\"\s*=\>\s*\"Auf Wiedersehen!\"/, 'fr_bye');
like($template, qr/\"MyPlugin_user_fr\"\s*=\>\s*\"Nutzer\"/, 'fr_bye');


# Reset dictionary
%{$app->localize->dictionary} = ();


# Check for multiple locales in a path - although this is really bad design!
$app->plugin('Localize' => {
  dict => {
    _ => sub { $_->locale },
    de => {
      welcome => 'Willkommen!',
      tree => {
        _ => sub { $_->locale },
        en => 'Tree',
      }
    },
    -en => {
      welcome => 'Welcome!',
      tree => {
        _ => sub { $_->locale },
        -en => 'Tree',
        de => 'Baum'
      }
    }
  }
});

$filename = 'mydict4';

# Use en as base
$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'de', '-b' => 'en', '-o' => $filename);
  }
);

like($stdout, qr/mydict4/, 'Correctly written');
$template = $dict->rel_file($filename)->slurp;

like($template, qr/\"de_tree_de\"/, 'de_tree_de');
unlike($template, qr/\"en_tree_de/, 'en_tree_de');

is($app->loc('tree'), 'Tree', 'Baum');


# Reset dictionary
%{$app->localize->dictionary} = ();

# Use synopsis dictionary
$app->plugin('Localize' => {
  dict => {
    _ => sub { $_->locale },
    -en => {
      thankyou => '»Thank you!«',
    }
  }
});


$filename = 'mydict5';

# Use en as base
$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'fr', '-b' => 'en', '-o' => $filename);
  }
);

like($stdout, qr/mydict5\" written/, 'Correctly written');
$template = $dict->rel_file($filename)->slurp;

# Reset dictionary
%{$app->localize->dictionary} = ();

# Check for correct encoding of created file
$app->plugin('Localize' => {
  resources => [$dict->rel_file($filename)]
});

like(decode('utf8',$template), qr/"»Thank you!«"/, 'Fine encoding');

# Reset dictionary
%{$app->localize->dictionary} = ();

# Always mark default entries
$app->plugin('Localize' => {
  dict => {
      _ => sub { $_->locale },
      en => {
        title => {
          -short => 'My Sojolicious',
          desc => 'A federated social web toolkit'
        }
      }
    }
});

$filename = 'mydict6';

# Use 'en' as base and respect default keys
$stdout = stdout_from(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;

    # Get a template for french based on the english dictionary
    $cmds->run('localize', 'fr', '-b' => 'en', '-o' => $filename);
  }
);

like($stdout, qr/mydict6\" written/, 'Correctly written');
$template = $dict->rel_file($filename)->slurp;

like($template, qr!# "fr_title_desc" => "A federated social web toolkit"!, 'desc');
like($template, qr!# "fr_title_-short" => "My Sojolicious"!, 'desc');


done_testing;
__END__


