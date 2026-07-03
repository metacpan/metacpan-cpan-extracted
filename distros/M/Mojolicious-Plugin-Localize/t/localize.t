#!usr/bin/env perl
use lib '../lib';
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t = Test::Mojo->new;
my $app = $t->app;

$ENV{MOJO_LOCALIZE_DEBUG} = 0;

my $languages = sub  { [qw/pl en de/] };

plugin 'Localize' => {
  dict => {
    welcome => {
      _ => $languages,
      en => 'Welcome!'
    }
  }
};

my $d = app->localize->dictionary;
is(${$d->{welcome}->{en}}, 'Welcome!', 'Welcome');

is(ref $d->{welcome}->{_}, 'CODE', 'Subroutine');
is($d->{welcome}->{_}->()->[0], 'pl', 'Lang');
is($d->{welcome}->{_}->()->[1], 'en', 'Lang');
is($d->{welcome}->{_}->()->[2], 'de', 'Lang');
ok(!exists $d->{welcome}->{de}, 'Kein Willkommen');

plugin Localize => {
  dict => {
    welcome => {
      de => 'Willkommen'
    }
  }
};

is(${ $d->{welcome}->{en}}, 'Welcome!', 'Welcome');
is(ref $d->{welcome}->{_}, 'CODE', 'Subroutine');
is(${ $d->{welcome}->{de}}, 'Willkommen', 'Willkommen');

plugin Localize => {
  dict => {
    welcome_pl => 'Serdecznie witamy, <%= stash "name" %>!'
  }
};

is(${ $d->{welcome}->{en}}, 'Welcome!', 'Welcome');
is(${ $d->{welcome}->{de}}, 'Willkommen', 'Willkommen');
is($d->{welcome}->{pl}, 'Serdecznie witamy, <%= stash "name" %>!', 'Willkommen (pl1)');

plugin Localize => {
  dict => {
    welcome => {
      de => 'Herzlich Willkommen!'
    }
  }
};

is(${ $d->{welcome}->{en} }, 'Welcome!', 'Welcome');
is(${ $d->{welcome}->{de} }, 'Willkommen', 'Willkommen');
is($d->{welcome}->{pl}, 'Serdecznie witamy, <%= stash "name" %>!', 'Willkommen (pl2)');

plugin Localize => {
  dict => {
    welcome_de => 'Herzlich Willkommen!'
  },
  override => 1
};

is(${ $d->{welcome}->{en}}, 'Welcome!', 'Welcome');
is(${ $d->{welcome}->{de}}, 'Herzlich Willkommen!', 'Willkommen');
is($d->{welcome}->{pl}, 'Serdecznie witamy, <%= stash "name" %>!', 'Willkommen (pl3)');

is(app->loc('welcome', name => 'Peter'), 'Serdecznie witamy, Peter!', 'Polish');

is(app->loc('welcome_de', name => 'Peter'), 'Herzlich Willkommen!', 'German');
is(app->loc('welcome_en', name => 'Peter'), 'Welcome!', 'English');


plugin Localize => {
  dict => {
    greeting => {
      '-en' => '<%=loc "welcome" %> Nice to meet you!'
    }
  }
};

is(app->loc('greeting', name => 'Peter'),
   'Serdecznie witamy, Peter! Nice to meet you!',
 'Combined template');

is(app->loc('welcome_de', name => 'Peter'), 'Herzlich Willkommen!', 'German');

plugin Localize => {
  dict => {
    greeting => {
      pl => '<%=loc "welcome" %> (polish)',
      _ => $languages
    }
  }
};

app->defaults(name => 'Michael');
is(app->loc('greeting'), 'Serdecznie witamy, Michael! (polish)', 'Polish');

plugin Localize => {
  dict => {
    greeting => {
      de => '<%=loc "welcome_de" %> Schön, dass Du da bist!',
      _ => $languages
    }
  }
};

is(app->loc('greeting_de'), 'Herzlich Willkommen! Schön, dass Du da bist!', 'Deutsch');

plugin Localize => {
  dict => {
    greeting => {
      _ => '<%= "en" %>'
    }
  },
  override => 1
};

is(app->loc('greeting'), 'Serdecznie witamy, Michael! Nice to meet you!',
   'Polish/English');

plugin Localize => {
  dict => {
    greeting => {
      -en => '<%=loc "welcome_en" %> Nice to meet you!'
    }
  },
  override => 1
};

is(app->loc('greeting'), 'Welcome! Nice to meet you!',
   'English');

plugin 'Localize' => {
  dict => {
    greeting => {
      _ => $languages
    }
  },
  override => 1
};

is(app->loc('greeting'), 'Serdecznie witamy, Michael! (polish)',
   'Polish');


is(app->loc, '', 'Lookup helper no longer returns dictionary');

# Override preferred key
plugin 'Localize' => {
  dict => {
    greeting => {
      _ => sub  { [qw/xx/] }
    }
  },
  override => 1
};

is(app->loc('greeting'), 'Welcome! Nice to meet you!',
   'English (default)');


# Override default key
plugin 'Localize' => {
  dict => {
    greeting => {
      '-' => 'de'
    }
  },
  override => 1
};

is(app->loc('greeting'), 'Herzlich Willkommen! Schön, dass Du da bist!',
   'German (default)');

# Override default key in short notation
plugin 'Localize' => {
  dict => {
    'greeting_-fr' => 'Bienvenue à! Nous sommes heureux que vous soyez ici!'
  },
  override => 1
};

is(app->loc('greeting'), 'Bienvenue à! Nous sommes heureux que vous soyez ici!',
   'French (default)');

# Override preferred key
plugin 'Localize' => {
  dict => {
    greeting => {
      _ => sub  { [qw/de en fr/] }
    }
  },
  override => 1
};

is(app->loc('greeting'), 'Herzlich Willkommen! Schön, dass Du da bist!',
   'German (preferred)');

# Override preferred key in short notation
plugin 'Localize' => {
  dict => {
    greeting_ => sub  { [qw/en pl fr/] }
  },
  override => 1
};

is(app->loc('greeting'), 'Welcome! Nice to meet you!',
   'English (preferred)');


# Override default key in short notation
plugin Localize => {
  dict => {
    'welcome_-de' => 'Grüß Dich!'
  },
  override => 1
};

is(app->loc('greeting_de'), 'Grüß Dich! Schön, dass Du da bist!',
   'German (direct)');

# Nested defaults
plugin Localize => {
  dict => {
    sorry => {
      -en => {
	-long => q{I'm very sorry!},
	short => q{I'm sorry!}
      },
      de => {
	-long => q{Tut mir sehr leid!},
	short => q{Tut mir leid!}
      }
    }
  }
};

is(app->loc('sorry'), 'I\'m very sorry!',
   'English (default)');
is(app->loc('sorry_short'), 'I\'m sorry!',
   'English (default)');
is(app->loc('sorry_de_short'), 'Tut mir leid!',
   'German short (direct)');
is(app->loc('sorry_de'), 'Tut mir sehr leid!',
   'German short (direct)');
is(app->loc('thx'), '', 'Nothing found');

plugin Localize => {
  dict => {
    Nested => {
      _ => [qw/de fr en/],
      de => {
        bye => 'Auf Wiedersehen!',
        tree => {
          -sg => 'Baum'
        }
      },
      fr => {
        welcome => 'Bonjour!',
        bye => 'Au revoir!'
      },
      -en => {
        welcome => 'Welcome!',
        bye => 'Good bye!',
        tree => {
          _ => [qw/pl/],
          -sg => 'Tree',
          pl => 'Trees'
        }
      }
    }
  }
};


is(app->loc('Nested_de_bye'), 'Auf Wiedersehen!', 'Nested de');
is(app->loc('Nested_fr_bye'), 'Au revoir!', 'Nested fr');
is(app->loc('Nested_en_bye'), 'Good bye!', 'Nested en');



is(app->loc('Nested_fr_welcome'), 'Bonjour!', 'Nested fr');
is(app->loc('Nested_en_welcome'), 'Welcome!', 'Nested en');
is(app->loc('Nested_de_welcome'), '', 'Nested de - not there');

is(app->loc('Nested_welcome'), 'Bonjour!', 'Nested');
is(app->loc('Nested_tree'), 'Baum', 'Nested');

# Check empty requests
is(app->loc(), '', 'Nothing');
is(app->loc(undef), '', 'Undef');
is(app->loc(undef, undef, undef), '', 'Undefs');

plugin Localize => {
  dict => {
    ampersand => '<%= "Cool" %> & <%= "not cool" %>'
  }
};

is(app->loc('ampersand'), 'Cool & not cool', 'No escaping');


plugin Localize => {
  dict => {
    DeepNested => {
      _ => [qw/de en/],
      de => {
        a => {
          b => {
            '.' => 'Das ist nur ab!',
            c => 'Das ist c!'
          }
        },
        test1 => {
          _ => [qw/foo/],
          bar => "Das ist bar!"
        },
        test2 => {
          _ => [qw/foo bar/],
          bar => {
            xxx => 'Das ist de_test2_bar_xxx'
          }
        }
      },
      -en => {
        a => {
          b => {
            '.' => 'This is ab only!',
            c => 'This is c!',
            d => 'This is d!'
          }
        },
        test1 => {
          _ => [qw/foo bar/],
          bar => "This is bar!",
          foo => "This is foo!"
        },
        test2 => {
          _ => [qw/foo bar/],
          bar => {
            yyy => 'This is en_test2_bar_yyy'
          }
        },
        test3 => {
          _ => [qw/foo bar/],
          '.' => 'Funny',
          'foo' => 'Check'
        }
      }
    }
  }
};

is(app->loc('DeepNested_a_b_c'), 'Das ist c!', 'Deeply Nested found');
is(app->loc('DeepNested_de_a_b_c'), 'Das ist c!', 'Deeply Nested exact');
is(app->loc('DeepNested_a_b_d'), 'This is d!', 'Deeply Nested backtrack');
is(app->loc('DeepNested_de_a_b_d'), '', 'Deeply Nested exact not found');
is(app->loc('DeepNested_a_b'), 'Das ist nur ab!', 'Deeply Nested found');


# Check default message
is(app->loc('DeepNested_de_a_b_d', 'Default message'),
   'Default message', 'Deeply Nested exact not found');

is(app->loc('DeepNested_de_a_b_d', 'Default message', user => 'Peter'),
   'Default message', 'Deeply Nested exact not found');
is(app->loc('DeepNested_de_a_b_d'), '', 'Deeply Nested exact not found');


is(app->loc('DeepNested_test1'), 'This is foo!', 'Deeply Nested test1');
is(app->loc('DeepNested_test1_bar'), 'Das ist bar!', 'Deeply Nested test1');

is(app->loc('DeepNested_test2_xxx'), 'Das ist de_test2_bar_xxx', 'Deeply Nested test2');
is(app->loc('DeepNested_test2_yyy'), 'This is en_test2_bar_yyy', 'Deeply Nested test2');

is(app->loc('DeepNested_test3'), 'Funny', 'Deeply Nested test3');
is(app->loc('DeepNested_test3_foo'), 'Check', 'Deeply Nested test3_foo');
is(app->loc('DeepNested_test3_xy'), 'Check', 'Deeply Nested test3_xy');


# Reset dictionary
%{app->localize->dictionary} = ();

# Test subroutines
plugin Localize => {
  dict => {
    welcome => sub {
      return 'Cool'
    },
    welcome2 => sub {
      my $c = shift;
      my %stash = @_;
      return 'Welcome, guest #' . $stash{number};
    },
    welcomeLink => q!Hello <%= link_to 'Me' => 'https://sojolicious.example' %>!
  }
};

is(app->loc('welcome'), 'Cool', 'Function');
is(app->loc('welcome2', number => 2000), 'Welcome, guest #2000', 'Function');
is(app->loc('welcomeLink'), 'Hello <a href="https://sojolicious.example">Me</a>', 'Link');

# Reset dictionary
%{app->localize->dictionary} = ();


# Check prefered key problem
plugin 'Localize' => {
  dict => {
    _ => [qw/de en/],
    en => {
      example => {
        -short => 'Example',
        desc => 'Example sentence'
      }
    },
    'de_example_-short' => 'Beispiel',
    'de_example_-desc' => ' das ist ein Beispiel'
  }
};

is(app->loc('example_short'), 'Beispiel', 'Example check');
is(app->loc('example_desc'), ' das ist ein Beispiel', 'Example desc');


# Check end key

# Reset dictionary
%{app->localize->dictionary} = ();

plugin 'Localize' => {
  dict => {
    welcome => {
      '.' => 'Welcome!!!',
      _ => [qw/en de/],
      de => 'Willkommen!',
      en => 'Welcome!'
    }
  }
};

is(app->loc('welcome'), 'Welcome!!!', 'End key');
is(app->loc('welcome_en'), 'Welcome!', 'End key');
is(app->loc('welcome_pl'), 'Welcome!', 'End key');
is(app->loc('welcome_de'), 'Willkommen!', 'End key');

done_testing;
