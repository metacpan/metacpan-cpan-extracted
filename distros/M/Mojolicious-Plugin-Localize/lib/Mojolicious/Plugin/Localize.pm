package Mojolicious::Plugin::Localize;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/decode/;
use Mojo::File qw/path/;
use Mojolicious::Plugin::Config;
use File::Spec::Functions 'file_name_is_absolute';
use List::MoreUtils 'uniq';

# TODO:
#   Wrap http://search.cpan.org/~reneeb/Mojolicious-Plugin-I18NUtils-0.05/lib/Mojolicious/Plugin/I18NUtils.pm
# TODO:
#   do not backtrack on upper case dictionary keys
# TODO:
#   Support prefixes in dictionary
# TODO:
#   Support locale sub in dictionary
# TODO:
#   'd' is probably better than 'loc'
#   'd' for dictionary lookup
# TODO:
#   use Hash::Merge or Hash::Merge::Small
# TODO:
#   Use Mojo::Template directly
# TODO:
#   deal with:
#   <%= numsep $g_count %> <%= quant $g_count, 'guest', 'guests' %> online.'
# TODO:
#   Deal with bidirectional text

use constant DEBUG => $ENV{MOJO_LOCALIZE_DEBUG} || 0;
our $VERSION = '0.23';

has 'log';

# Warning: This only works for default EP templates
our $TEMPLATE_INDICATOR = qr/(?:^\s*\%)|<\%/m;

# Register plugin
sub register {
  my ($self, $mojo, $param) = @_;

  my (@dict, @resources);
  @dict      = ($param->{dict})       if $param->{dict};      # Hashes
  @resources = @{$param->{resources}} if $param->{resources}; # File names

  $self->log($mojo->log);

  # Not yet initialized
  unless ($mojo->renderer->helpers->{loc}) {

    # Load parameter from config file
    if (my $c_param = $mojo->config('Localize')) {

      # Prefer the configuration dictionary
      push @dict, $c_param->{dict} if $c_param->{dict};

      # Prefer the configuration override parameter
      $param->{override} = $c_param->{override} if $c_param->{override};

      # Add configuration resources
      if ($c_param->{resources}) {
        unshift @resources, @{$c_param->{resources}};
      };
    };

    # Load default helper
    $mojo->plugin('Localize::Quantify');
    $mojo->plugin('Localize::Locale');

    # Add 'generate dictionary' command
    push @{$mojo->commands->namespaces}, __PACKAGE__ . '::Command';

    # Lookup a dictionary key and return the value
    $mojo->helper(
      loc => sub {
        my $c = shift;

        # Nothing to look up
        return ''  unless scalar @_ && $_[0];

        my $key = [split('_', shift)];

        if (DEBUG) {
          _debug($c->app, '[LOOKUP] Search for "' . join('_',  @$key) . '"');
        };

        # If a default entry is given, get it
        my $default_entry = shift if @_ && @_ % 2 != 0;

        # Store all other values in the stash
        my %stash = @_;

        # Return dictionary entry or default entry
        return _lookup($c, \%stash, $c->stash('localize.dict'), $key, 0) ||
          $default_entry // '';
      }
    );


    # Return the dictionary reference
    $mojo->helper(
      'localize.dictionary' => sub {
        # Return the complete dictionary in case no parameter is defined
        # This is not documented and may change in further versions
        return $_[0]->stash('localize.dict');
      }
    );

    # Return the prefered path
    $mojo->helper(
      'localize.preference' => sub {
        my $c = shift;

        my $stash = $c->stash;
        return $stash->{'localize.preference'} if $stash->{'localize.preference'};

        my $key = [split('_', shift // '')];
        my $dict = $c->stash('localize.dict');

        if (DEBUG) {
          _debug($c->app, '[PREF] Look for prefered key for "' . join('_', @$key) . '"');
        };

        # If a default entry is given, get it
        my $default_entry = shift;

        # Return dictionary key - so pass the "find_pref" parameter
        $stash->{'localize.preference'} = _lookup($c, {}, $c->stash('localize.dict'), $key, 0, 1) ||
          $default_entry // '';
        return $stash->{'localize.preference'};
      }
    );

    $mojo->defaults('localize.dict' => {});
  };

  # Merge dictionary resources
  if (@resources) {

    # Create config loader
    my $config_loader = Mojolicious::Plugin::Config->new;
    my $home = $mojo->home;

    # Load files
    foreach my $file (uniq @resources) {

      $file = $home->rel_file($file) unless file_name_is_absolute $file;

      if (DEBUG) {
        _debug($mojo, "Load dictionary $file");
      };

      if (-e $file) {
        if (my $dict = $config_loader->load($file, undef, $mojo)) {
          unshift @dict, [$dict, $file];
          _debug($mojo, qq!Successfully loaded dictionary "$file"!);
          next;
        };
      };
      $mojo->log->warn(qq!Unable to load dictionary file "$file"!);
    };
  };

  my $dict_global = $mojo->defaults('localize.dict');

  # Merge dictionary hashes
  foreach (@dict) {
    my $is_array = ref $_ && ref $_ eq 'ARRAY';

    if (DEBUG) {
      _debug(
        $mojo,
        '[MERGE] Start merging' .
          ($is_array ? (' of ' . $_->[1]) : '')
        );
    };

    # Merge to global dictionary
    $self->_merge($dict_global, $is_array ? $_->[0] : $_, $param->{override});
  };
};


# Unflatten short notation
sub _unflatten {
  my ($key, $dict) = @_;
  my $k = $$key;
  my $g_hash = $dict->{$k};

  # Check for preferred key
  if (substr($k, -1, 1) eq '_') {
    $g_hash = { _  => $g_hash };
    chop $k;
  };

  # Build verbose tree
  $g_hash = { $1 => $g_hash } while $k =~ s/_([^_]+)$//;

  # Set root key
  $$key = $k;
  $dict->{$k} = $g_hash;
};


# Store value as string or code reference
sub _store {
  my $value = $_[0];

  # Is template - store as reference
  return $value if ref $value || $value =~ $TEMPLATE_INDICATOR;
  return \$value;
};


# Merge dictionaries
sub _merge {
  my ($self, $dict_global, $dict, $override) = @_;

  # Iterate over all keys
  foreach my $k (keys %$dict) {

    # This is a short notation key
    if (index($k, '_') > 0) {
      _debug($self, qq![MERGE] Unflatten "$k"!) if DEBUG;

      # Unflatten short notation
      _unflatten(\$k, $dict);
    }

    # Set preferred key
    elsif ($k eq '_') {

      # If override or not set yet, set the new preferred key
      if ($override || !defined $dict_global->{_}) {

        _debug($self, qq![MERGE] Override "_"!) if DEBUG;
        $dict_global->{_} = $dict->{_};
      };

      next;
    };

    # This is a default key
    if (index($k, '-') == 0) {
      my $standalone = 0;

      _debug($self, qq![MERGE] Try to set default key with "$k"!) if DEBUG;

      # This is a prefixed default key
      if (length($k) > 1) {
        $k = substr($k, 1);
        $dict->{$k} = delete $dict->{"-$k"};
      }

      # This is a standalone default key
      else {
        $k = $dict->{'-'};
        $standalone = 1;
      };

      # If override or not set yet, set the new default key
      if ($override || !defined $dict_global->{'-'}) {

        _debug($self, qq![MERGE] Override default key with "$k"!) if DEBUG;
        $dict_global->{'-'} = $k;
      };

      next if $standalone;
    };

    # Insert key - if it not yet exists
    if (!$dict_global->{$k}) {

      # Merge the tree
      if (ref $dict->{$k} eq 'HASH') {
        $self->_merge($dict_global->{$k} = {}, $dict->{$k}, $override);
      }

      # Store the plain value
      else {
        $dict_global->{$k} = _store($dict->{$k});
      };
    }

    # Merge key, when both are hashes
    elsif (ref($dict_global->{$k}) eq ref($dict->{$k}) && ref($dict_global->{$k}) eq 'HASH') {
      $self->_merge($dict_global->{$k}, $dict->{$k}, $override);
    }

    # Override global and store the plain value
    elsif ($override) {
      $dict_global->{$k} = _store($dict->{$k});
    };
  };
};

sub _mark {
  my ($keys, $level) = @_;
  my @x = ();
  for (my $i = 0; $i <= $#$keys; $i++) {
    if ($i == $level) {
      push @x, '[' . $keys->[$i] . ']';
    }
    else {
      push @x, $keys->[$i];
    };
  };

  return join('_',@x);
};

# Lookup dictionary entry recursively
sub _lookup {
  my ($c, $stash, $dict, $key, $level, $find_pref) = @_;
  # $c         is the controller object
  # $stash     contains a hash reference of stash values
  # $dict      contains the dictionary at the current level
  # $key       is the key array passed to the resolver
  # $level     is the current position in the key
  # $find_pref is a boolean value indicating that no value is looked up

  # Get the current input element to consume
  my @keys;
  if (my $primary = $key->[$level]) {
    @keys = ($primary);

    if (DEBUG) {
      _debug($c->app, qq![LOOKUP] There is a primary key "$primary" at input level [$level]!);
      _debug($c->app, qq![LOOKUP] at "! . _mark($key, $level) . '"');
    };
  };

  # No primary key given

  # Check all possibilities
  my $pos = 0;
  my $lazy = 0;


  # Iterate over all possible key fragments
  while () {

    # No more keys
    if (!$keys[$pos]) {

      if (DEBUG) {
        _debug(
          $c->app,
          "[LOOKUP] There is no more key at position $pos on input level [$level]"
        );
      };

      if ($lazy && $find_pref && $level >= $#{$key}) {
        return $keys[$pos-1];
      };

      # Stop processing
      return if $lazy;

      # There is a stop value defined and no primary exists
      push @keys, '.' if $dict->{'.'} && !$keys[0];

      # Lazy load further keys
      # Add preferred keys
      if ($dict->{'_'}) {
        my @matches = _get_pref_keys($c, $dict->{'_'}, $stash);
        if ($matches[0]) {
          if (DEBUG) {
            _debug(
              $c->app,
              qq![LOOKUP] But there are preferred keys "@matches"!
            );
          };
          push @keys, @matches;
        };
      };

      # Add default key
      if ($dict->{'-'}) {
        my $match = $dict->{'-'};
        if (DEBUG) {
          _debug($c->app, qq![LOOKUP] But there is a default key "$match"!);
        };
        push @keys, $match if $match;
      };

      return unless $keys[$pos];

      # There may be items set multiple times
      @keys = uniq @keys;

      _debug($c->app, qq![LOOKUP] Check non-manual keys "@keys"!) if DEBUG;

      $lazy = 1;
    };

    # Key has a match
    if (my $match = $dict->{$keys[$pos]}) {

      # Debug information
      if (DEBUG) {
        _debug(
          $c->app,
          qq![LOOKUP] Found entry for "$keys[$pos]" on input level [$level]!
        );
      };

      # The match is final
      if ((!ref($match) || ref($match) eq 'SCALAR' || ref($match) eq 'CODE') && !$find_pref) {

        # Everything is cosumed - fine
        if ($level >= $#{$key}) {

          # Value is scalar
          if (ref $match eq 'SCALAR') {
            if (DEBUG) {
              _debug(
                $c->app,
                qq![LOOKUP] Found scalar value "$$match"!
              );
            };
            return $$match;
          }

          # Value is a subroutine
          elsif (ref $match eq 'CODE') {
            my $value = $match->($c, %$stash);
            if (DEBUG) {
              _debug(
                $c->app,
                qq![LOOKUP] Found subroutine value as "$value"!
              );
            };
            return $value;
          };

          # Value is a template
          my $value = $c->render_to_string(inline => $match, %$stash);
          chomp($value) unless delete $stash->{no_trim};
          if (DEBUG) {
            _debug(
              $c->app,
              qq![LOOKUP] Found template value as "$value"!
            );
          };
          return $value;
        };

        # Check another path
      }

      # Get the relevant key if everything is consumed
      elsif (ref($match) && $find_pref && $level > $#{$key}) {

        if (DEBUG) {
          _debug(
            $c->app,
            '[PREF] Found key "' . $keys[$pos] . '"'
          );
        };

        return $keys[$pos];
      }

      # No final match found - go on
      else {

        my $level_up = $level;

        # If the primary key was consumed or not given, level up
        if (!$pos || !$key->[$level]) {
          $level_up++;
          if (DEBUG) {
            _debug($c->app, "[LOOKUP] Forward to input level [$level_up]");
          };
        };

        # Call lookup recursively
        my $found = _lookup(
          $c, $stash, $match, $key, $level_up, $find_pref
        );

        # Found something
        return $found if $found;
      };
    };

    # Get next key
    $pos++;
    if (DEBUG) {
      _debug($c->app, "[LOOKUP] Forward to next key at position $pos");
    };
  };
};


# Debug messages
sub _debug {
  my ($app, $msg) = @_;

  # If the value is 2 - debug to stderr
  if (DEBUG == 2) {
    print STDERR "$msg\n";
  }

  # Otherwise debug to log
  else {
    $app->log->debug($msg);
  }
};


# Return preferred keys
sub _get_pref_keys {
  my ($c, $index, $stash) = @_;

  return unless $index;

  # Preferred key is a template
  unless (ref $index) {

    my $key = $c->render_to_string(inline => $index, %$stash);
    chomp($key) unless delete $stash->{no_trim};
    return $key;
  }

  # Preferred key is a subroutine
  elsif (ref $index eq 'CODE') {

    local $_ = $c->localize;
    my $pref = $index->($c);
    return ref $pref ? @$pref : ($pref);
  }

  # Preferred key is an array
  elsif (ref $index eq 'ARRAY') {
    return @{$index};
  };

  # No preferred keys or invalid notation
  return;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Localize - Localization for Mojolicious


=head1 SYNOPSIS

  # Register the plugin with a defined dictionary
  plugin  Localize => {
    dict => {
      _  => sub { $_->locale },
      -de => {
        welcome => "Willkommen in <%=loc 'App_name' %>!",
        bye => 'Auf Wiedersehen!'
      },
      en => {
        welcome => "Welcome to <%=loc 'App_name' %>!",
        bye => 'Good bye!'
      },
      App => {
        name => {
          -long => 'Mojolicious',
          short => 'Mojo',
          land  => 'MojoLand'
        }
      }
    }
  };

  # Lookup dictionary entries from templates
  %= loc 'welcome'

  # If the user has a preferred locale of 'en',
  # the output is 'Welcome to Mojolicious!'


=head1 DESCRIPTION

L<Mojolicious::Plugin::Localize> is a localization framework for
Mojolicious, heavily inspired by Mozilla's L<l20n|http://l20n.org/>.
Instead of being a reimplementation it uses L<Mojo::Template> for string interpolation,
L<Mojolicious::Plugin::Config> for dictionaries and L<helpers|Mojolicious/helper>
for template functions.


=head1 METHODS

L<Mojolicious::Plugin::Localize> inherits all methods
from L<Mojolicious::Plugin> and implements the following
new ones.

=head2 register

  app->plugin(Localize => {
    dict => {
      _  => sub { $_->locale },
      de => {
        welcome => 'Willkommen!',
        bye => 'Auf Wiedersehen!',
      },
      en => {
        welcome => 'Welcome!',
        bye => 'Good bye!'
      }
    },
    override  => 1,
    resources => ['myapp.fr.dict', 'myapp.pl.dict']
  });

Called when registering the plugin.

Expects a parameter C<dict> containing a localization L<dictionary|/DICTIONARIES>.
Further dictionary files to be loaded can be passed as an array reference
using the C<resources> parameter.

The plugin can be registered multiple times, and defined dictionaries will be merged.

Already existing key definitions won't be overridden in that way
unless an additional C<override> parameter is set to a C<true> value.
Dictionary entries from resource files, on the other hand, will always override,
so the order of the given array is of relevance.

All parameters can be set either on registration or in a configuration file
with the key C<Localize> (loaded only on first registration).


=head1 HELPERS

In addition to the listed helpers,
L<Mojolicious::Plugin::Localize> loads further helpers by default,
see L<quant|Mojolicious::Plugin::Localize::Quantify> and
L<localize-E<gt>locale|Mojolicious::Plugin::Localize::Locale/locale>.


=head2 loc

  # Lookup a dictionary entry as a controller method
  my $entry = $c->loc('welcome');

  %# Lookup a dictionary entry in templates
  %= loc 'welcome'
  %= loc 'welcome', 'Welcome to the site!'
  %= loc 'welcome', user => 'Peter'
  %= loc 'welcome', 'Welcome to the site!', user => 'Peter'

Makes a dictionary lookup and returns a string.

Expects a dictionary key, an optional fallback message and optional stash values.


=head2 localize-E<gt>dictionary

  print $c->localize->dictionary->{welcome}->{en};

Nested helper in the C<localize> namespace.
Returns the merged dictionary hash.

L<Mojolicious::Plugin::Localize> loads further plugins establishing nested helpers,
see L<localize-E<gt>locale|Mojolicious::Plugin::Localize::Locale/locale>.


=head2 localize-E<gt>preference

  # Dictionary:
  # {
  #   '_' => ['de','en'],
  #   '-en' => {
  #     welcome => 'Welcome'
  #   },
  #   'de' => {
  #     welcome => 'Willkommen'
  #   },
  #   'pl' => {
  #     welcome => 'Serdecznie witamy'
  #   }
  # }

  print $c->localize->preference;
  # 'de'

Return the prefered existing key for a given dictionary path.
In case the first level of a dictionary path is a language code
and the preferred keys are the user's preferred locales,
this will return the preferred existing language code for a user.

I<This helper is EXPERIMENTAL!>


=head1 COMMANDS

=head2 localize

  $ perl app.pl localize en pl

Generate a new dictionary template for a certain locale based on an existing dictionary.
See L<Mojolicious::Plugin::Localize::Command::localize|localize> for further information.


=head1 DICTIONARIES

  {
    dict => {
      _ => sub { $_->locale },
      -en => {
        welcome => 'Welcome!'
      },
      de => {
        welcome => 'Willkommen!'
      }
    },
    resources => ['myapp.fr.dict']
  };

  # myapp.fr.dict
  {
    fr => {
      welcome => 'Bonjour!'
    }
  };

Dictionaries can be loaded by registering the plugin either as a passed C<dict> value
or in separated files using the C<resources> parameter.

=head2 Notation

  {
    en => {
      tree => {
        singular => 'Tree',
        plural => 'Trees'
    },
    de => {
      tree => {
        singular => 'Baum',
        plural => 'Bäume'
      }
    }
  }

Dictionaries are nested hash references.
On each level, there is a key that can either lead to a subdictionary
or to a value.

  {
    en => {
      welcome => 'Welcome!',
      greeting => '<%= loc "en_welcome" %> Nice to meet you, <%= $user %>!'
    },
    de => {
      welcome => 'Willkommen!',
      greeting => '<%= loc "de_welcome" %> Schön, Dich zu sehen, <%= $user %>!'
    }
  }

Values are L<Mojo::Template> strings (with default configuration)
or code references (with the controller object passed when evaluating,
followed by further parameters as a hash). In case a string is passed as a scalar
reference, it won't be interpolated as a L<Mojo::Template>.

As you see above, values may fetch further dictionary entries using the L<loc|/loc> helper.
To fetch entries from the dictionary using the L<loc|/loc> helper,
the user has to pass the key structure in so-called I<short notation>, by adding
underscores following they key's path.
The short notation for the entry C<Bäume> in the first example is C<de_tree_plural>.

  %= loc 'de_tree_plural'
  %# 'Bäume'

The short notation can also be used to add new dictionary entries
using dictionary files or the C<dict> parameter of the plugins registration handler.
The following dictionary definitions are therefore equal:

  {
    de => {
      welcome => 'Willkommen!'
    }
  };

  # or
  {
    de_welcome => 'Willkommen!'
  };

There is no limitation for nesting of dictionary entries.
The order in a dictionary is irrelevant as well.

Keys need to contain alphanumeric characters only,
as special characters are reserved for later use.


=head2 Preferred Keys

The underscore is a special key, marking preferred keys on the dictionary level,
in case no matching key can be found on that level
(which is the case when a key in short notation is underspecified).

  {
    welcome => {
      _ => 'en',
      de => 'Willkommen!'
      en => 'Welcome!'
    }
  }

In case the key C<welcome_de> is requested with the above dictionary established,
the value C<Willkommen!> will be returned.
But if the underspecified key C<welcome> is requested without a matching key on the
final level, the preferred key C<en> will
be used instead, returning the value C<Welcome!>.

Preferred keys can exist on any level of the nesting and are always called when
there is no matching key as part of the short notation.

Preferred keys may contain the key as a string, a L<Mojo::Template>, an array reference
of keys (in order of preference), or a subroutine returning either a string or an array
reference.

  # The preferred key is 'en'
  _ => 'en'

  # The preferred key is the stash value of 'user_status' (e.g. 'mod' or 'admin')
  _ => '<%= $user_status %>'
  _ => sub { shift->stash('user_status') }

  # The preferred key is 'en', and in case this isn't defined, it's 'de' etc.
  _ => [qw/en de/]
  _ => sub { [qw/en de/] }

The first parameter passed to subroutines is the controller object,
and the local variable C<$_> is set to the L<nested helper object|/localize>,
which eases calls to, for example,
the L<localize-E<gt>locale|Mojolicious::Plugin::Localize::Locale/locale> helper

  # The preferred key is based on the user agent's localization
  _ => sub { $_->locale }

Preferred keys in I<short notation> have a trailing underscore:

  # Set the preferred key in nested notation:
  {
    greeting => {
      _ => sub { $_->locale },
      en => 'Hello!',
      de => 'Hallo!'
    }
  }

  # Set the preferred key in short notation:
  {
    greeting_ => sub { $_->locale },
    greeting_en => 'Hello!',
    greeting_de => 'Hallo!'
  }


=head2 Default Keys

The dash symbol is a special key, marking default keys on the dictionary level,
in case no matching or preferred key can be found on that level.
They can be given in addition to preferred keys.

  {
    welcome => {
      _   => 'pl',
      '-' => 'en',
      en  => 'Welcome!',
      de  => 'Willkommen!'
    }
  }

In case the key C<welcome_de> is requested with the above dictionary
established, the value C<Willkommen!> will be returned.
But if the underspecified key C<welcome> is requested without a
matching key on the final level, and the preferred key C<pl>
isn't defined in another dictionary, the default key C<en> will
be used instead, returning the value C<Welcome!>.

Default keys can be alternatively marked with a leading dash symbol.

  {
    welcome => {
      _   => 'pl',
      -en => 'Welcome!',
      de  => 'Willkommen!'
    }
  }

To define default keys in I<short notation>, prepend a dash to each subkey in question.

  {
    'welcome_-en' => 'Welcome!',
    'welcome_de'  => 'Willkomen!'
  }

Preferred and default keys are specific to subtrees.
That means in the following dictionary C<loc('title')>
will return the string C<My Sojolicious> for the locale C<en>
and nothing for the locale C<de>, as no matching path is found.
In case there is a list of locales like C<de,en>, the call will
trigger backtracking and return C<My Sojolicious> as well.

  {
    _ => sub { $_->locale }
    en => {
      title => {
        -short => 'My Sojolicious',
        desc => 'A federated social web toolkit'
      }
    },
    de => {
      title => {
        short => 'Mein Sojolicious',
        desc => 'Ein Werkzeugkasten für das Social Web'
      }
    }
  }

To return C<Mein Sojolicious> in case of C<loc('title')> for the locale
C<de>, the second C<short> key needs to be prefixed as well.


=head2 End Keys

The period sign is a special key, marking an end value on the final dictionary level.
This prevents preferred and default keys to be searched, when the key is already consumed.
End keys can only point to values.

  {
    welcome => {
      '.' => 'Welcome!!!',
      _ => [qw/en de/],
      de => 'Willkommen!',
      en => 'Welcome!'
    }
  }

Here the key C<welcome> will return the value C<Welcome!!!>, while
C<welcome_de> will return C<Willkommen!> and C<welcome_pl> will
return C<Welcome!>.


=head2 Forcing Preferred and Default Keys

  {
    Lang => {
      _ => [qw/en de pl/],
      -en => {
        de => 'German',
        en => 'English'
      },
      de => {
        de => 'Deutsch',
        en => 'Englisch'
      }
    }
  }

When looking up an entry in the dictionary tree,
the consumption precedence is
C<primary E<gt> preferred E<gt> default>.

But in rare occasions a lookup has to force the
usage of preferred or default keys over primary key access,
for example, in the above dictionary a call to C<Lang_de>,
expecting the value C<German>, will fail, as the C<de> will
be consumed on the second level and will therefore be missing on the third.
To force the usage of the preferred or the default key on the second level,
simply prepend another underscore to the second partial key
(to consume an empty partial key) and call C<Lang__de> with the expected result.


=head2 Hints and Conventions

L<Mojolicious::Plugin::Localize> let you decide, how to nest
your dictionary entries. For internationalization purposes,
it is a good idea to have the language key on the first
level, so you can establish further entries relying on that
structure (see, e.g., the example snippet in L<SYNOPSIS>).

Instead of passing default messages using the L<loc|/loc> helper,
you should always define default dictionary entries.

Dictionary keys should always be lower case, and plugins,
that provide their own dictionaries, should prefix their keys
with a namespace (e.g. the plugin's name) in camel case,
to prevent clashes with other dictionary entries.
For example the C<welcome> message for this plugin should
be named C<Localize_welcome>.

Template files can be registered as dictionary keys to be
looked up for rendering.

  # Create dictionary keys for templates
  {
    Template => {
      _ => sub { $_->locale },
      -en => {
        start => 'en/start'
      },
      de => {
        start => 'de/start'
      }
    }
  }

  # Lookup dictionary entry for rendering
  $c->render($c->loc('Template_start'), variant => 'mobile');


=head1 TODO

=over 2

=item

Support for L<CLDR|https://metacpan.org/pod/Locale::CLDR>

=back

=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Localize


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2026, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
