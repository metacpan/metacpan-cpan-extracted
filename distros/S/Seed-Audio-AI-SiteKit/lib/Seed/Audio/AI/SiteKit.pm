package Seed::Audio::AI::SiteKit;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.1.0';
our @EXPORT_OK = qw(site seed_audio_url);

sub site {
  return {
    name => 'Seed Audio AI',
    homepage => 'https://seedaud.io/',
    description => 'Browser-based text-to-speech and AI voice generation workflow.',
    canonicalPages => {
      home => 'https://seedaud.io/',
      textToSpeech => 'https://seedaud.io/text-to-speech/',
      pricing => 'https://seedaud.io/pricing/',
      safety => 'https://seedaud.io/safety/',
      terms => 'https://seedaud.io/terms/',
    },
    tags => ['text-to-speech', 'ai-voice', 'voice-generator', 'site-kit'],
  };
}

sub seed_audio_url {
  my ($path) = @_;
  $path = '' unless defined $path;
  $path =~ s{^/+}{};
  $path =~ s{/+$}{};
  return 'https://seedaud.io/' if $path eq '';
  return 'https://seedaud.io/' . $path . '/';
}

1;

__END__

=head1 NAME

Seed::Audio::AI::SiteKit - unofficial metadata and URL helpers for Seed Audio AI

=head1 SYNOPSIS

  use Seed::Audio::AI::SiteKit qw(site seed_audio_url);
  my $homepage = site()->{homepage};
  my $pricing = seed_audio_url('pricing');

=head1 DESCRIPTION

Small unofficial metadata and URL helpers for Seed Audio AI at L<https://seedaud.io/>.
This module is not an official SDK for ByteDance, Seed, Volcengine, or any model provider.

=cut
