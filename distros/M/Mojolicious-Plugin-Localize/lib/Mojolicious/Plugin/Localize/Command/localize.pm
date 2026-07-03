package Mojolicious::Plugin::Localize::Command::localize;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw/quote encode/;
use Mojo::Date;
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);

# TODO:
#   Probably do:
#   http://irclog.perlgeek.de/mojo/2016-09-22#i_13257554

has description => 'Generate dictionary files for Localize';
has usage       => sub { shift->extract_usage };

our $SPECIAL = '!SPECIAL!'; # Special locale

use constant DEBUG => $ENV{MOJO_LOCALIZE_DEBUG} || 0;

has [qw/base lang controller/];


# Generate dictionary template
sub run {
  my ($self, $lang, @args) = @_;

  $self->lang($lang);

  my $app = $self->app;

  GetOptionsFromArray \@args,
    'b|base=s'   => \(my $base = 'en'),
    'o|output=s' => \(my $output = '');

  # Unknown command
  print $self->usage and return unless $self->lang;

  # Set base language
  $self->base($base);

  # Initialize key store
  $self->{keys} = {};

  # Get generated dictionary
  my $dict = $app->localize->dictionary;

  # Set controller
  $self->controller($app->build_controller);

  # Setting an unlikely locale
  $self->controller->stash('localize.locale' => [$SPECIAL]);

  # Recursive investigate the dictionary
  $self->_investigate($dict, [], 0);

  my $data = '# Dictionary template generated ';
  $data .= Mojo::Date->new(time);
  $data .= "\n\n{\n" . $self->_filter->_print . "};\n";

  $output ||= $app->moniker . '.' . $self->lang . '.dict';

  # Generate file
  if (-e $output) {
    warn quote($output) . " already exists and is not overwritten.\n\n"
  }
  elsif ($self->write_rel_file($output, encode('UTF-8', $data))) {
    say quote($output) . " written.\n";
  };
  print "\n";
};


# Investigate dictionary entry and check for usage
sub _investigate {
  my ($self, $dict, $path, $level) = @_;

  if (!ref $dict || ref $dict eq 'SCALAR' || ref $dict eq 'CODE') {

    # Check elements of the path
    my @elements = @{$path}[0..$level - 1];

    # Key is not localed
    return unless grep /[\*\+]/, @elements;

    # Join the missing key
    my $key = join('_', @elements);

    $self->{keys}->{$key} = $dict;

    return;
  }

  elsif (ref $dict eq 'ARRAY') {
    warn 'Arrays are not valid dictionary values';
    return;
  };

  # Set local $_ to nested helber for preferred subroutines
  local $_ = $self->controller->localize;

  # Define the example branch
  my $locale_example;

  # There is a locale branch
  my $loc_act;
  if (($loc_act = $dict->{_}) &&
        (ref($loc_act) eq 'CODE') &&
        ($loc_act = $dict->{_}->($self->controller)) &&
        (ref($loc_act) eq 'ARRAY') &&
        ($loc_act->[0] eq $SPECIAL)) {

    # The output already exists
    if (exists $dict->{$self->lang}) {
      $path->[$level] = '+';
      $locale_example = $self->lang;

      if (DEBUG) {
        warn '[DICT] Locale branch at path ' .
          quote(_key($path, $level + 1)) . " and level [$level]";
      };

      # Follow the locale
      $self->_investigate(
        $dict->{$locale_example},
        $path,
        $level + 1
      );
    };

    # Define the output for the path
    $path->[$level] = '*';

    # The input example branch exists
    if ($dict->{$self->base}) {
      $locale_example = $self->base;
    }

    # A default branch exists
    elsif ($dict->{'-'} && $dict->{$dict->{'-'}}) {
      $locale_example = $dict->{'-'};
    };

    # Example path is missing - can't follow!
    unless ($locale_example) {
      warn '[DICT] No example path defined for locale branch ' .
        quote(_key($path, $level + 1)) if DEBUG;
      return;
    };

    if (DEBUG) {
      warn '[DICT] Locale branch at path ' .
        quote(_key($path, $level + 1)) . ' and level [' . $level . ']';
    };

    # Follow the locale
    $self->_investigate(
      $dict->{$locale_example},
      $path,
      $level + 1
    );
  };


  # FOLLOW ALL KEYS!
  foreach (grep { $_ ne '-' && $_ ne '_' } keys %$dict) {

    # The key is a default key
    if ($dict->{'-'} && $_ eq $dict->{'-'}) {

      # Prefix key value with default prefix
      $path->[$level] = '-' . $_;
    }

    # Set key value in path
    else {
      $path->[$level] = $_;
    };

    $self->_investigate($dict->{$_}, $path, $level + 1);
  };
};


# Return the current key
sub _key {
  return join('_', @{$_[0]}[0..$_[1] - 1])
};


# Filter all locale keys already defined
sub _filter {
  my $self = shift;

  # Iterate over all locale given keys
  foreach (grep { index($_, '+') >= 0 } keys %{$self->{keys}}) {

    # Delete all given keys
    delete $self->{keys}->{$_};

    # Delete all keys locale keys that are not already given
    $_ =~ tr/\+/\*/;
    delete $self->{keys}->{$_};
  };

  return $self;
};


# Print out all keys
sub _print {
  my $self = shift;

  my $out = $self->lang;

  my %new_keys;
  while (my ($key, $value) = each %{$self->{keys}}) {
    $key =~ s/\*/$out/g;
    $new_keys{$key} = $value;
  };

  my $template = '';

  # Iterate over all stored keys
  foreach my $key (sort { lc($a) cmp lc($b) } (keys %new_keys)) {

    $template .= '  # ' . quote($key) . ' => ';

    my $value = $new_keys{$key};

    # Print example entry
    if (!ref $value) {
      $template .= quote($value) . ",";
    }

    # Print scalar value
    elsif (ref $value eq 'SCALAR') {
      $template .= quote($$value) . ",";
    }

    # Print sub
    elsif (ref $value eq 'CODE') {
      $template .= "sub { ... },";
    };

    # Add newline
    $template .= "\n"
  };

  return $template;
};


1;

__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Localize::Command::localize - Generate dictionary files for Localize

=head1 SYNOPSIS

  Usage: APPLICATION localize <lang> [OPTIONS]

    perl app.pl localize pl

  Options:
    -h, --help            Show this summary of available options
    -b, --base <lang>     Base language locale, defaults to "en"
    -o, --output <file>   Output file for dictionary, defaults to
                          the moniker, the locale and the extension 'dict'


=head1 DESCRIPTION

Generates a localized dictionary template based on an existent
dictionary.

Given the following merged dictionary of an application:

  {
    _ => sub { $_->locale },
    de => {
      welcome => 'Willkommen!',
      thankyou => 'Danke!'
    },
    fr => {
      thankyou => 'Merci!'
    },
    -en => {
      welcome => 'Welcome!',
      thankyou => 'Thank you!',
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

To create a translation template for the locale french based on all
entries of the english locale, call ...

  $ perl app.pl localize fr --base en

The created dictionary template in short notation will look like this:

  {
    # "fr_welcome" => \"Welcome!",
    # "MyPlugin_bye_fr" => \"Good Bye!",
  };


=head1 ATTRIBUTES

L<Mojolicious::Plugin::Localize::Command::localize> inherits all attributes
from L<Mojolicious::Command> and implements the following new ones.


=head2 description

  my $description = $localize->description;
  $localize = $localize->description('Foo!');

Short description of this command, used for the command list.


=head2 usage

  my $usage = $localize->usage;
  $localize = $localize->usage('Foo!');

Usage information for this command, used for the help screen.


=head1 METHODS

L<Mojolicious::Plugin::Localize::Command::localize> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.


=head2 run

  $localize->run;

Run this command.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Localize


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, L<Nils Diewald||http://nils-diewald.de>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

The documentation is based on L<Mojolicious::Command::eval>,
written by Sebastian Riedel.

=cut
