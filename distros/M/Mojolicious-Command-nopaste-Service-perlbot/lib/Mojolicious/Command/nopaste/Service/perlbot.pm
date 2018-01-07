package Mojolicious::Command::nopaste::Service::perlbot;
use Mojo::Base 'Mojolicious::Command::nopaste::Service';
use Mojo::JSON qw/decode_json/;

use Getopt::Long;

our $VERSION = '0.006';

# ABSTRACT: Pastes stuff to https://perl.bot/

has name => 'anonymous';
has 'irc_handled' => 1;
has desc => 'I broke this';

has 'service_usage' => 
qq{perl.bot specific options:

  --get-channels     Ask the pastebin about what channels it knows, and exit
  --get-languages    Ask the pastebin about what languages it knows, and exit
};

sub run {
  my ($self, @args) = @_;

  my $p = Getopt::Long::Parser->new;
  $p->configure("no_ignore_case", "pass_through");
  $p->getoptionsfromarray( \@args,
    'get-channels'     => sub {$self->display_channels; exit(1)},
    'get-languages'    => sub {$self->display_languages; exit(1)},
  );

  $self->SUPER::run(@args);
}

sub display_channels {
  my $self = shift;
  my $tx = $self->ua->get( 'https://perl.bot/api/v1/channels');
 
  unless ($tx->res->is_success) {
    say "Failed to get channels, try again later.";
    exit 1;
  }

  my $response = decode_json $tx->res->body;

  my $output="Channels supported by perl.bot, all values subject to change.\n-----------------------------------\n";
  for my $channel (@{$response->{channels}}) {
      $output .= sprintf "%15s  %20s\n", $channel->{name}, $channel->{description};
  }

  print $output;
}

sub display_languages {
  my $self = shift;
  my $tx = $self->ua->get( 'https://perl.bot/api/v1/languages');
 
  unless ($tx->res->is_success) {
    say "Failed to get languages, try again later.";
  }

  my $response = decode_json $tx->res->body;

  my $output="Languages supported by perl.bot\n-----------------------------\n";
  for my $lang (@{$response->{languages}}) {
      $output .= sprintf "%15s  %20s\n", $lang->{name}, $lang->{description};
  }

  print $output;
}

sub paste {
  my $self = shift;

  my $tx = $self->ua->post( 'https://perl.bot/api/v1/paste', form => {
    paste    => $self->text,
    username => $self->name,
    language => $self->language || '',
    channel  => $self->channel || '',
    description => $self->desc || '',
  });
 
  unless ($tx->res->is_success) {
    say "Paste failed, try again later.";
    exit 1;
  }

  my $response = decode_json $tx->res->body;
  return $response->{url};
}
 
1;

__END__
=head1 NAME

Mojolicious::Command::nopaste::Service::perlbot - A Mojo-nopaste service for https://perl.bot/

=head1 AUTHOR
Ryan Voots L<simcop@cpan.org|mailto:SIMCOP@cpan.org>

=head1 CONTRIBUTORS

Dan Book 

=cut
