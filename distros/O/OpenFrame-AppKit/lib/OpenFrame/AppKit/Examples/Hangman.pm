package OpenFrame::AppKit::Examples::Hangman;

use strict;
use Games::GuessWord;
use OpenFrame::AppKit::App;
use base qw(OpenFrame::AppKit::App);

sub entry_points {
  return {
    guess => ['guess'],
  };
}

sub wordlist {
  my $self  = shift;
  my $words = shift;
  if (defined($words)) {
    $self->{words} = $words;
    return $self;
  } else {
    return $self->{words};
  }
}

sub default {
  my $self  = shift;
  my $store = shift;
  delete $self->{message};

  # Start a new game if there isn't one already
  if (not $self->{game}) {
    my $words = $self->wordlist || die "No wordlist given!";
    my $game  = Games::GuessWord->new(file => $words);
    $self->{game} = $game; # save the game in our session
    $self->{guessed} = {};
  }
  return 1;
}

sub guess {
  my $self  = shift;
  my $store = shift;

  my $request = $store->get('OpenFrame::Request');

  delete $self->{message};

  # Retrieve the game and the guess
  my $game = $self->{game};
  my $guess = $request->arguments->{guess};

  if (not defined $game) {
    # We don't have a game, so set one up
    $self->default($store);
    return 1;
  }

  $game->guess(lc $guess);
  $self->{guessed}->{$guess} = 1;

  if ($game->won) {
    # They got the whole word
    $self->{message} = "You guessed the correct word: ".
      $game->answer;
    $game->new_word();
    $self->{guessed} = {};
  } elsif ($game->lost) {
    # They ran out of chances
    $self->{message} = "You didn't guess the word. It was: " .
      $game->secret;
    $self->{finalscore} = $game->score();
    # Remove the game from our session
    delete $self->{game};
  } else {
    # Show the results of the guess
  }
  return 1;
}

1;

__END__

=head1 NAME

OpenFrame::AppKit::Examples::Hangman - Hangman

=head1 DESCRIPTION

C<OpenFrame::AppKit::Examples::Hangman> is part of the simple hangman
web application. The module contains all the logic and presentation
for Hangman.

Note that the application has two main entry points: the default() and
the guess() subroutines. The C<$epoint> hash at the beginning of the
module sets up the call to guess() if a "guess" parameter is passed in
the request. Otherwise, default() is called.

Each entry point is given itself, the session, an abstract request,
and per-application configuration. They then contain application logic
- note that we store a Games::GuessWord object inside C<$self> and
that this is magically persistent between calls.

This code is small and clean as the output is generated by
C<OpenFrame::AppKit::Segment::TT2> later on in the slot process. Any
messages are passed in C<$self>.

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2001-2, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
