package Net::AozoraBunko;
use strict;
use warnings;
use utf8;
use Carp qw/croak/;

use URI;
use URI::Fetch;
use LWP::UserAgent;
use Encode qw/decode/;
use Web::Scraper;

our $VERSION = '0.05';

my $DOMAIN = 'http://www.aozora.gr.jp';
my $PAGES = {
    author_base_regex => qr!^\Q$DOMAIN\E/index_pages/!,
    text_base_regex   => qr!^\Q$DOMAIN\E/cards/\d+/.+\.(?:html|zip)$!,
    authors_index     => "$DOMAIN/index_pages/person_all_all.html",
    author_detail     => "$DOMAIN/index_pages",
};

my $ENCODE = {
    html => 'utf8',
    text => 'cp932',
};

my $UA = LWP::UserAgent->new(
    agent   => __PACKAGE__ . '/' . $VERSION,
    timeout => 10,
);

sub new {
    my $class = shift;
    my $args  = shift || +{};

    my $self = bless $args, $class;

    $self->ua($args->{ua} || $UA);

    return $self;
}

sub search_author {
    my $self    = shift;
    my $keyword = shift; # utf8 flagged

    return [] unless $keyword;

    my $authors = $self->authors;

    my @result;
    for my $r (@{$authors}) {
        if ($r->{name} =~ m!\Q$keyword\E!) {
            push @result, $r;
        }
    }

    return \@result;
}

sub search_work {
    my $self         = shift;
    my $author_page  = shift; # URL or ID(*** = /person***.html)
    my $keyword      = shift; # utf8 flagged

    return [] unless $author_page;
    return [] unless $keyword;

    if ($author_page =~ m!^\d+$!) {
        return $self->search_work(
            "$PAGES->{author_detail}/person$author_page.html",
            $keyword
        );
    }

    my $writings = $self->all_works($author_page);

    my @result;
    for my $r (@{$writings}) {
        if ($r->{title} =~ m!\Q$keyword\E!) {
            push @result, $r;
        }
    }

    return \@result;
}

sub authors {
    my $self = shift;

    my $authors = scraper {
        process 'li', 'authors[]' => scraper {
            process 'a', name => 'TEXT', url => '@href';
        };
    };

    my $uri = URI->new($PAGES->{authors_index});

    my $res = $authors->scrape($self->_fetch($uri, $ENCODE->{html}), $uri);

    return $res->{authors};
}

sub author {
    my $self = shift;
    my $uri  = shift;

    $self->_check_uri(\$uri);

    my $author = scraper {
        process 'table>tr', 'data[]' => sub {
            my $line = $_->as_HTML;
            my ($key, $value) = map {
                my $html = $_;
                $html =~ s/<[^>]+>//g;
                $html;
            } ($line =~ m!<td[^>]+>(.+)</td><td>(.+)</td>!);
            return { $key => $value };
        };
    };

    my $data = $author->scrape(
        $self->_fetch($uri, $ENCODE->{html}), $uri
    )->{data};

    my $person;
    for my $dat (@{$data}) {
        my @keys = keys %{$dat};
        $person->{$keys[0]} = $dat->{$keys[0]};
    }

    return $person;
}

sub works {
    my $self = shift;
    return $self->_get_works($_[0]);
}

sub all_works {
    my $self = shift;
    return $self->_get_works($_[0], 1);
}

sub _get_works {
    my $self = shift;
    my $uri  = shift;
    my $all  = shift;

    $self->_check_uri(\$uri);

    my $list = scraper {
        process 'li', 'list[]' => 'RAW';
    };

    my $works  = $list->scrape($self->_fetch($uri, $ENCODE->{html}), $uri);

    my $writings = [];
    if (ref $works->{list} eq 'ARRAY') {
        for my $work (@{$works->{list}}) {
            my $title = '';
            my $url   = '';
            if ($work =~ /^<a href/) {
                ($url, $title) = ($work =~ m!<a href="([^"]+)">([^<]+)</a>!);
                $url = URI->new_abs($url, $uri);
            }
            elsif ($all) {
                ($title, undef) = split /　（/, $work;
            }
            else {
                next;
            }
            push @{$writings}, { title => $title, url => $url, };
        }
    }

    return $writings;
}

sub get_text {
    my $self = shift;
    my $uri  = shift;

    my $zip = $self->_zip_uri($uri);

    require IO::Uncompress::Unzip;
    require IO::String;

    IO::Uncompress::Unzip::unzip(
        IO::String->new($zip) => my $out = IO::String->new
    );
    my $text = decode($ENCODE->{text}, ${$out->string_ref});

    return $text;
}

sub get_zip {
    my $self = shift;
    my $uri  = shift;

    my $zip = $self->_zip_uri($uri);

    return $zip;
}

sub _zip_uri {
    my $self = shift;
    my $uri  = shift;

    croak 'uri is blank' unless $uri;

    unless ($uri =~ /$PAGES->{text_base_regex}/) {
        croak "wrong uri: $uri";
    }

    if ($uri =~ /\.html$/) {
        my $html = $self->_fetch($uri, $ENCODE->{html});
        my ($zip_path) = ($html =~ m!<a href="(.+\.zip)">.+\.zip</a>!);
        my $zip_uri = URI->new_abs($zip_path, $uri);
        return $self->_zip_uri($zip_uri);
    }

    my $zip = $self->_fetch($uri);

    return $zip;
}

sub ua {
    my $self = shift;
    my $ua   = shift;

    if ($ua) {
        $self->{ua} = $ua if ref $ua eq 'LWP::UserAgent';
    }
    else {
        return $self->{ua};
    }
}

sub _fetch {
    my $self = shift;
    my $uri  = shift;
    my $char = shift;

    my $fetch_response = URI::Fetch->fetch(
        $uri,
        UserAgent => $self->ua,
    ) or croak "could not fetch [$uri]: $!";

    if ($char) {
        return decode($char, $fetch_response->content);
    }
    else {
        return $fetch_response->content;
    }
}

sub _check_uri {
    my $self = shift;
    my $uri  = shift;

    croak 'uri is blank' unless $$uri;

    unless ($$uri =~ m!$PAGES->{author_base_regex}!) {
        croak "not author's URL: $$uri";
    }
    else {
        $$uri = URI->new($$uri);
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Net::AozoraBunko - Perl Interface for accessing 青空文庫

=head1 SYNOPSIS

  use Net::AozoraBunko;
  $ab = Net::AozoraBunko->new;
  $authors = $ab->authors;
  $author = shift @{$authors};
  $author_info = $ab->author($author->{url});
  $works = $ab->works($author->{url});
  $all_works = $ab->works($author->{url});
  $text = $ab->get_text($works->[0]->{url});
  $zip  = $ab->get_zip($works->[0]->{url});
  $search_author_results = $ab->search_author('search_word');
  $search_work_results   = $ab->search_work($author->{url}, 'search_word');


=head1 DESCRIPTION

The Aozora Bunko (青空文庫) is the Internet electronic library where consideration is not requested from use. The one assumed to be work that the copyright disappears and "Do not care freely reading" is arranged by TEXT and XHTML (Part is HTML) forms.

C<Net::AozoraBunko> is Perl Interface for accessing 青空文庫.
This way it's possible to search authors and download TEXT.


=head1 METHODS

=over 4

=item new

  my $ab = Net::AozoraBunko->new;
  my $ab = Net::AozoraBunko->new({
      ua => LWP::UserAgent->new(timeout => 15)
  });

Creates a new Net::AozoraBunko object.

=item authors

  my $authors = $ab->authors;

get authors list

=item author

  my $author_info = $ab->author($author->{url});

get author's data

=item works

  my $works = $ab->works($author->{url});

get author's works list

=item all_works

  my $all_works = $ab->works($author->{url});

get author's all works list. The one under work is contained

=item get_text

  my $text = $ab->get_text($works->[0]->{url});

get a text

=item get_zip

  my $zip  = $ab->get_zip($works->[0]->{url});

get a text by zip

=item search_author

  my $search_author_results = $ab->search_author('search_word');

search authors by a keyword

=item search_work

  my $search_work_results   = $ab->search_work($author->{url}, 'search_word');

search works by a keyword from authors page.

=item ua

get/set user agent object

=back


=head1 REPOSITORY

C<Net::AozoraBunko> is hosted on github
L<http://github.com/bayashi/Net-AozoraBunko>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<http://www.aozora.gr.jp/>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=cut
