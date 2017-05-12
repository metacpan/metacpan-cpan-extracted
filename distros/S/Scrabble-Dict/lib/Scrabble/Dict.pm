package Scrabble::Dict;

use base qw/Exporter/;
use LWP::UserAgent;
use strict;

our @EXPORT_OK = qw/scrabble_define/;
our $VERSION = '0.01';

my %defaults = (
  host => 'www.hasbro.com',
  uri_home => '/games/adult-games/scrabble/home.cfm',
  uri_dict => '/games/adult-games/scrabble/home.cfm?page=Dictionary/dict',
  undefined_as => ''
);

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %init = @_ & 1 ? die "argument hash expected" : @_;

  my $self = {
    _host         => delete $init{host}         || $defaults{host},
    _uri_home     => delete $init{uri_home}     || $defaults{uri_home},
    _uri_dict     => delete $init{uri_dict}     || $defaults{uri_dict},
    _undefined_as => delete $init{undefined_as} || $defaults{undefined_as},
  };

  $self->{_ua} = LWP::UserAgent->new(%init, cookie_jar => {});

  return bless $self => $class;
}

sub define {
  my ($self, $word) = (shift, lc shift);
  my $ua = $self->{_ua};

  my %param = (
    type => 'dictionary',
    exact => 'on',
    Word => $word
  );

  # hasbro site forces us to eat ColdFusion cookies the first time

  my $url_home = "http://$self->{_host}$self->{_uri_home}";
  my $cookie_scan = sub { $_[1] eq 'CFID' && $_[4] eq $self->{_host} };

  $ua->get($url_home) if not $ua->cookie_jar->scan($cookie_scan);

  my $url_dict = "http://$self->{_host}$self->{_uri_dict}";
  my $html = '';

  $ua->post($url_dict, \%param, ':content_cb' => sub { $html .= shift });

  return $self->scrape_definition($html, $word);
}

sub scrape_definition {
  my ($self, $html, $word) = (shift, shift, shift);

  return $1 if $html =~
    m{<div \s+ id="dict_return">
        .*?
        <span \s+ .*?>
          \Q$word\E .*? \\ \s+ (.*?)
        </span>
        .*?
      </div>}xsm;

  return $self->{_undefined_as};
}

sub scrabble_define {
  my $word = shift;
  return __PACKAGE__->new(@_)->define($word);
}

1;

__END__

=head1 NAME

Scrabble::Dict - look up words in the official Scrabble dictionary

=head1 SYNOPSIS

  # procedural interface

  use Scrabble::Dict qw/scrabble_define/;

  print scrabble_define('quixotry')."\n";

  # OO interface

  use Scrabble::Dict;

  my $dict = Scrabble::Dict->new(env_proxy => 1);

  # example: look up all the two letter words

  for my $c0 ('a' .. 'z') {
    for my $c1 ('a' .. 'z') {
      my $def = $dict->define($c0.$c1);
      print "${c0}${c1} $def\n" if $def;
    }
  }

=head1 DESCRIPTION

I<Scrabble::Dict> is a screen-scraper interface to the Official Scrabble
Player's Dictionary (OSPD) available online at http://www.hasbro.com/scrabble.

=head1 METHODS

=over 4

=item $dict = Scrabble::Dict->new(%options, %lwp_options);

Construct a new Scrabble dictionary object. Recognized options are:

  host           hostname of Scrabble site
  uri_home       path of home page where we get cookies
  uri_dict       path + query of word lookup page
  undefined_as   return this when no definition is found

These default to values which work currently, but may stop working at any
given moment--this is screen-scraping after all. Any other key-value options
are passed on to the constructor of I<LWP::UserAgent>, giving you some
finer-grained control over the connection. Refer to I<LWP::UserAgent> for more.

Before the actual word lookup is performed, cookies must be obtained from
the Hasbro home page. The first call to define() on a I<Scrabble::Dict>
will take care of this. Subsequent calls on that object will be faster.

=item $dict->define($word)

Lookup the definition for a word. If no match is found, return the value
of the 'undefined_as' option.

=item $dict->scrape_definition($html, $word)

Internal: finds the needle in the haystack. You could subclass and override
if the page layout changes.

=back

=head1 FUNCTIONS

=over 4

=item scrabble_define($word, %options, %lwp_options)

Look up a word using a new I<Scrabble::Dict> object. See new() for a
description of available options. Note that the OO interface will be faster
for multiple lookups.

=back

=head1 AUTHOR

Alan Grow <agrow+nospam@thegotonerd.com>

=head1 COPYRIGHT AND LICENSE

This module is not endorsed by Hasbro Inc. The name Scrabble is a registered trademark of Hasbro Inc.

Copyright (C) 2007 by Alan Grow

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.3 or, at your option, any later version of Perl 5 you may have available.

