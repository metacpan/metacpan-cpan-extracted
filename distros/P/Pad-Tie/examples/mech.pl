#!perl

use WWW::Mechanize;
use Pad::Tie;

my $mech = WWW::Mechanize->new;

my $binding = Pad::Tie->new(
  $mech,
  [
    scalar => [
      get => { -as => 'url' },
      qw(content title),
    ],
    'self',
  ],
);

$binding->call(\&get_and_print);

sub get_and_print {
  my $url = "http://www.listbox.com";
  print my $title, "\n";
  my $self->follow_link(text_regex => qr/features/i);
  print "$_\n" for my $content =~ /(Compose[^<]+)/;
};
