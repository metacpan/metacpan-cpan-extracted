package Redis::Bayes;
use Redis;
use v5.10;
use List::Util qw/sum/;
use Carp;
use Moo;
use Lingua::StopWords qw/getStopWords/;
use strict;

our $VERSION = '0.024';

has stopwords => (
  is => 'rw',
  lazy => 1,
  builder => '_build_stopwords',
);

has redis => (
  is => 'ro',
  builder => '_build_redis',
);

has prefix => (
  is => 'ro',
  default => sub {'bayes:'},
);

has tokenizer => (
  is => 'rw',
  lazy => 1,
  builder => '_build_tokenizer',
);

sub _build_redis {
  return Redis->new(
    reconnect => 2, 
    every => 100
  );
}

sub _build_stopwords {
  return getStopWords('en');
}

sub _build_tokenizer {
  my $self = shift;
  return sub {
    my ($txt) = @_;
    my @words = grep {
      !$self->stopwords->{$_}
    } grep { $_ } split /[\W_-]+/, lc $txt;
    return @words;
  };
}

sub _tokenize {
  my ($self,$txt) = @_;
  return $self->tokenizer->($txt);
}

sub _word_counts {
  my ($self, @words) = @_;
  my %counts;
  $counts{$_}++ for @words;
  return \%counts;
}

sub flush {
  my $self = shift;
  for my $cat ($self->redis->smembers($self->prefix . 'categories')) {
    $self->redis->del($self->prefix . $cat);
  }
  $self->redis->del($self->prefix . 'categories');
  return 1;
}

sub train {
  my ($self,$category,$text) = @_;
  $self->redis->sadd($self->prefix . 'categories', $category);
  my $wc = $self->_word_counts($self->_tokenize($text));
  while (my ($w,$c) = each(%$wc)) {
    $self->redis->hincrby($self->prefix . $category, $w, $c);
  }
  return 1;
}

sub untrain {
  my ($self, $category, $text) = @_;
  my $wc = $self->_word_counts($self->_tokenize($text));
  my ($cur,$new);
  while (my ($w,$c) = each(%$wc)) {
    $cur = $self->redis->hget($self->prefix . $category, $w);
    if ($cur) {
      $new = int($cur) - $c;
      if ($new > 0) {
        $self->redis->hset($self->prefix . $category, $w, $new)
      }else{
        $self->redis->hdel($self->prefix . $category, $w);
      }
    }
  }
  if ($self->_total($category) == 0) {
    $self->redis->del($self->prefix . $category);
    $self->redis->srem($self->prefix . 'categories', $category);
  }
  return 1;
}

sub classify {
  my ($self, $text, $args) = @_;
  $args //= {};
  my $scores = $self->_score($text);
  return if (not $scores);
  my @d = sort { $scores->{$b} <=> $scores->{$a} } keys %$scores;
  return 'empty data store' if (not @d);
  if ($args->{return_all}) {
    return join ',', map { "$_:" . $scores->{$_} } @d;
  }
  return ($scores->{$d[0]} ? $d[0] : 'unclassified');
}

sub _score {
  my ($self, $text) = @_;
  my $wc = $self->_word_counts($self->_tokenize($text));
  my %scores;
  for my $category ($self->redis->smembers($self->prefix . 'categories')) {
    my $total = $self->_total($category);
    next if ($total == 0);
    $scores{$category} = 0.0;
    while (my ($w,$c) = each %$wc) {
      my $score = $self->redis->hget($self->prefix . $category, $w);
      croak "invalid values in Redis" unless (not $score or $score > 0); 
      next if not $score;
      $scores{$category} += $score / $total;
    }
  }
  return \%scores;
}

sub _total {
  my ($self, $category) = @_;
  my $total = sum($self->redis->hvals($self->prefix . $category));
  return 0 if (not $total);
  croak "error in hvals" unless ($total >= 0);
  return $total;
}



1;

__END__
=head1 NAME

Redis::Bayes - Bayesian classification on Redis

=head1 SYNOPSIS

EXAMPLES:
    
  my $rb = Redis::Bayes->new;
  $rb->train('apple_computer',q{I'm going to pick up a new retina display MacBook!});
  $rb->train('apple_fruit',q{That thing is rotten at the seeds.});
  my $result = $rb->classify("retina display");


=head1 DESCRIPTION

This module is an implementation of naive Bayes on Redis.

=head1 METHODS

=head2 new

  my $rb = Redis::Bayes->new; # defaults to Redis->new(reconnect => 2, every => 100);
  # or
  my $rb = Redis::Bayes->new(
    prefix => 'yourownprefixhere:',
    stopwords => {blah => 1, whatever => 1},
    tokenizer => \&tokenize,
    redis => $redis,
  );

=over 4

=item B<prefix>

Redis database prefix. The default is 'bayes:'.

=item B<stopwords>

The set of words to filter when training. The default uses Lingua::StopWords.

=item B<tokenizer>

The package is equipped with its own tokenizer. But you may override this by supplying your own as a coderef either at creation or after instantiation.

=item B<redis>

Defaults to Redis->new(reconnect => 2, every => 100). Otherwise, use delegation here.

=back

=head2 train

  $rb->train('apple','sauce');

Train using <label, document>.

=head2 untrain

  $rb->untrain('apple','sauce');

Untrains <label, document>.

=head2 flush

  $rb->flush;

Flushes all trained data.

=head2 classify

  $rb->classify(q{there's a computer on the desk});

Returns the label with the highest confidence metric for the given document.

=head1 SEE ALSO

L<Redis>

=head1 ACKNOWLEDGEMENTS

This module is ported loosely from other such packages in node and python,
i.e. https://github.com/harthur/classifier and https://github.com/jart/redisbayes
and https://github.com/didip/bayes_on_redis, with some modifications.

=head1 AUTHOR

Andrew Shapiro, C<< <trski@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-redis-bayes at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Redis-Bayes>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Andrew Shapiro.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut


