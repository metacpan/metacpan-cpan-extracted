#!/usr/bin/env perl
use 5.14.0;
use lib "lib", "../lib";
use List::Util 'min';
use Parallel::Pipes;

=head1 DESCRIPTION

This script crawles a web page, and follows links with specified depth.

You can easily change

  * a initial web page
  * the depth
  * how many crawlers

Moreover if you hack Crawler class, then it should be easy to implement

  * whitelist, blacklist for links
  * priority for links

=cut

package URLQueue {
    use constant WAITING => 1;
    use constant RUNNING => 2;
    use constant DONE    => 3;
    sub new {
        my ($class, %option) = @_;
        bless {
            max_depth => $option{depth},
            queue => { $option{url} => { state => WAITING, depth => 0 } },
        }, $class;
    }
    sub get {
        my $self = shift;
        grep { $self->{queue}{$_}{state} == WAITING } keys %{$self->{queue}};
    }
    sub set_running {
        my ($self, $url) = @_;
        $self->{queue}{$url}{state} = RUNNING;
    }
    sub depth_for {
        my ($self, $url) = @_;
        $self->{queue}{$url}{depth};
    }
    sub register {
        my ($self, $result) = @_;
        my $url   = $result->{url};
        my $depth = $result->{depth};
        my $next  = $result->{next};
        $self->{queue}{$url}{state} = DONE;
        return if $depth >= $self->{max_depth};
        for my $n (@$next) {
            next if exists $self->{queue}{$n};
            $self->{queue}{$n} = { state => WAITING, depth => $depth + 1 };
        }
    }
}

package Crawler {
    use Web::Scraper;
    use LWP::UserAgent;
    use Time::HiRes ();
    sub new {
        bless {
            http => LWP::UserAgent->new(timeout => 5),
            scraper => scraper { process '//a', 'url[]' => '@href' },
        }, shift;
    }
    sub crawl {
        my ($self, $url, $depth) = @_;
        my ($res, $time) = $self->_elapsed(sub { $self->{http}->get($url) });
        if ($res->is_success and $res->content_type =~ /html/) {
            my $r = $self->{scraper}->scrape($res->decoded_content, $url);
            warn "[$$] ${time}sec \e[32mOK\e[m crawling depth $depth, $url\n";
            my @next = grep { $_->scheme =~ /^https?$/ } @{$r->{url}};
            return {url => $url, depth => $depth, next => \@next};
        } else {
            my $error = $res->is_success ? "content type @{[$res->content_type]}" : $res->status_line;
            warn "[$$] ${time}sec \e[31mNG\e[m crawling depth $depth, $url ($error)\n";
            return {url => $url, depth => $depth, next => []};
        }

    }
    sub _elapsed {
        my ($self, $cb) = @_;
        my $start = Time::HiRes::time();
        my $r = $cb->();
        my $end = Time::HiRes::time();
        $r, sprintf("%5.3f", $end - $start);
    }
}



my $queue = URLQueue->new(url => "http://www.cpan.org/", depth => 3);

my $pipes = Parallel::Pipes->new(5, sub {
    my ($url, $depth) = @{$_[0]};
    state $crawler = Crawler->new;
    return $crawler->crawl($url, $depth);
});

my $get; $get = sub {
    my $queue = shift;
    if (my @url = $queue->get) {
        return @url;
    }
    if (my @written = $pipes->is_written) {
        my @ready = $pipes->is_ready(@written);
        for my $result (grep $_, map { $_->read } @ready) {
            $queue->register($result);
        }
        return $queue->$get;
    } else {
        return;
    }
};

while (my @url = $queue->$get) {
    my @ready = $pipes->is_ready;
    if (my @written = grep { $_->is_written } @ready) {
        for my $result (grep $_, map { $_->read } @written) {
            $queue->register($result);
        }
    }
    for my $i ( 0 .. min($#url, $#ready) ) {
        my $url = $url[$i];
        my $ready = $ready[$i];
        $queue->set_running($url);
        $ready->write( [ $url, $queue->depth_for($url) ] );
    }
}

$pipes->close;
