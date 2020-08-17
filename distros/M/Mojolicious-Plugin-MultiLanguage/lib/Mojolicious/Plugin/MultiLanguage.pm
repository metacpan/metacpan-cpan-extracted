package Mojolicious::Plugin::MultiLanguage;
use Mojo::Base "Mojolicious::Plugin";

use Mojo::Collection 'c';
use HTTP::AcceptLanguage;

our $VERSION = "0.01";
$VERSION = eval $VERSION;

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{cookie}     //= {path => "/"};
  $conf->{languages}  //= [qw/es fr de zh-tw/];
  $conf->{api_prefix} //= ["/api"];

  state $langs_enabled = c(
    'en', @{$conf->{languages}}
  )->map(sub { lc $_ })->flatten->uniq;

  state $langs_available = c(
    # English
    {
      code    => 'en',
      name    => "English",
      native  => "English",
      dir     => 'ltr',
      index2  => 1,
      index3  => 1,
    },

    # Spanish
    {
      code    => 'es',
      name    => "Spanish",
      native  => "Español",
      dir     => 'ltr',
      index2  => 2,
      index3  => 2,
    },

    # German
    {
      code    => 'de',
      name    => "German",
      native  => "Deutsch",
      dir     => 'ltr',
      index2  => 3,
      index3  => 3,
    },

    # French
    {
      code    => 'fr',
      name    => "French",
      native  => "Français",
      dir     => 'ltr',
      index2  => 4,
      index3  => 4,
    },

    # Portuguese
    {
      code    => 'pt-br',
      name    => "Portuguese",
      native  => "Português",
      dir     => 'ltr',
      index2  => 5,
      index3  => 5,
    },

    # Italian
    {
      code    => 'it',
      name    => "Italian",
      native  => "italiano",
      dir     => 'ltr',
      index2  => 6,
      index3  => 6,
    },

    # Polish
    {
      code    => 'pl',
      name    => "Polish",
      native  => "Polskie",
      dir     => 'ltr',
      index2  => 7,
      index3  => 7,
    },

    # Russian
    {
      code    => 'ru',
      name    => "Russian",
      native  => "Русский",
      dir     => 'ltr',
      index2  => 8,
      index3  => 8,
    },

    # Ukrainian
    {
      code    => 'uk',
      name    => "Ukrainian",
      native  => "Українська",
      dir     => 'ltr',
      index2  => 9,
      index3  => 9,
    },

    # Finnish
    {
      code    => 'fi',
      name    => "Finnish",
      native  => "Finnish",
      dir     => 'ltr',
      index2  => 10,
      index3  => 10,
    },

    # Greek
    {
      code    => 'el',
      name    => "Greek",
      native  => "Ελληνικά",
      dir     => 'ltr',
      index2  => 11,
      index3  => 11,
    },

    # Turkish
    {
      code    => 'tr',
      name    => "Turkish",
      native  => "Türk",
      dir     => 'ltr',
      index2  => 12,
      index3  => 12,
    },

    # Arabic
    {
      code    => 'ar',
      name    => "Arabic",
      native  => "العربية",
      dir     => 'rtl',
      index2  => 13,
      index3  => 13,
    },

    # Farsi
    {
      code    => 'fa',
      name    => "Farsi",
      native  => "हिंदी",
      dir     => 'rtl',
      index2  => 14,
      index3  => 14,
    },

    # Hindi
    {
      code    => 'hi',
      name    => "Hindi",
      native  => "हिंदी",
      dir     => 'ltr',
      index2  => 15,
      index3  => 15,
    },

    # Chinese
    {
      code    => 'zh-cn',
      name    => "Chinese (Simplified)",
      native  => "中国",
      dir     => 'ltr',
      index2  => 16,
      index3  => 16,
    },

    {
      code    => 'zh-tw',
      name    => "Chinese (Traditional)",
      native  => "中国",
      dir     => 'ltr',
      index2  => 17,
      index3  => 17,
    },

    # Japanese
    {
      code    => 'ja',
      name    => "Japanese",
      native  => "日本",
      dir     => 'ltr',
      index2  => 18,
      index3  => 18,
    },

    # Korean
    {
      code    => 'ko',
      name    => "Korean",
      native  => "日本",
      dir     => 'ltr',
      index2  => 19,
      index3  => 19,
    }
  )->each(sub { $_->{index1} = 1 });

  # Default language
  my $english = $langs_available->first;

  # Lookup language
  my $lang_lookup = sub {
    my ($code) = @_;

    $langs_available->grep(sub { lc $code eq $_->{code} })->first
      or die "Language code '$code' does not exists!";
  };

  # Enabled languages
  $app->attr(languages => sub {
    $langs_enabled->map(sub { $lang_lookup->($_) });
  });

  # Active languages codes
  $app->attr(langs => sub {
    $app->languages->map( sub { $_->{code} });
  });

  my $lang_exists = sub {
    my ($code) = @_;

    return 0 unless $code and $code =~ /^[a-z]{2}(-[a-z]{2})?$/;
    $app->languages->grep(sub { $code eq $_->{code} })->size;
  };

  # Parse Accept-Language header
  $app->helper(accept_language => sub {
    my ($c) = @_;

    my $header = $c->req->headers->accept_language;
    HTTP::AcceptLanguage->new($header)->match(@{$app->langs});
  });

  # Detect language for site via url, cookie or headers
  my $detect_site = sub {
    my ($c, $path) = @_;

    my $part  = $path->parts->[0] // '';
    my @flags = (0, $english->{code}, 0, "/");

    unless ($part) {
      my $cookie = $c->cookie('lang');

      unless ($cookie) {
        my $accept = $c->accept_language;

        unless ($accept) {
          $app->log->debug("Unknown accept-language");
        }

        elsif ($accept eq $english->{code}) {
          @flags[1] = ($accept);
        }

        elsif ($lang_exists->($accept)) {
          @flags[1, 2, 3] = ($accept, 1, "/$accept");
        }

        else {
          $app->log->warn("Wrong accept-language: '$accept'");
        }
      }

      elsif ($cookie eq $english->{code}) {
        @flags[1] = ($cookie);
      }

      elsif ($lang_exists->($cookie)) {
        @flags[1, 2, 3] = ($cookie, 1, "/$cookie");
      }

      else {
        $app->log->warn("Wrong cookie-language: '$cookie'");
      }
    }

    elsif ($part eq $english->{code}) {
      @flags[0, 1, 2, 3] = (1, $part, 1, $path);
    }

    elsif ($lang_exists->($part)) {
      @flags[0, 1, 2, 3] = (1, $part, 0, $path);
    }

    else {
      $app->log->debug("No language detected");
    }

    if ($flags[0]) {
      shift @{$path->parts};
      $path->trailing_slash(0);
    }

    my $language = $lang_lookup->($flags[1]);
    $c->cookie(lang => $language->{code}, $conf->{cookie});

    $c->redirect_to($flags[3]) and return undef if $flags[2];

    $app->log->debug("Detect site language '$language->{code}'");

    return $language;
  };

  # Detetect language for api via headers only
  my $detect_api = sub {
    my ($c, $path) = @_;

    return $english if $c->req->method eq 'OPTIONS';

    my $accept = $c->accept_language;

    my $language = $lang_exists->($accept)
      ? $lang_lookup->($accept) : $english;

    $app->log->debug("Detect API language '$language->{code}'");

    return $language;
  };

  $app->hook(before_dispatch => sub {
    my ($c) = @_;

    return if $c->res->code;

    my $path = $c->req->url->path;
    my $is_api = grep { $path->contains($_) } @{$conf->{api_prefix}};

    return unless my $language = $is_api
      ? $detect_api->($c, $path) : $detect_site->($c, $path);

    $c->stash(language => $language);
  });

  $app->hook(after_render => sub {
    my ($c) = @_;

    return unless my $language = $c->stash('language');

    my $h = $c->res->headers;
    $h->append('Vary' => "Accept-Language");
    $h->content_language($language->{code});
  });

  # Complete languages collection
  $app->helper(languages => sub {
    my ($c) = @_;

    my $language = $c->stash('language') // $english;

    $app->languages->each(sub {
      $_->{active} = $_->{code} eq $language->{code} ? 1 : 0;
    });
  });

  # Reimplement 'url_for' helper
  my $mojo_url_for = *Mojolicious::Controller::url_for{CODE};

  my $lang_url_for = sub {
    my ($c, @args) = @_;

    my $url = $c->$mojo_url_for(@args);

    return $url if $url->is_abs;

    shift @args if @args % 2 && !ref $args[0] or @args > 1 && ref $args[-1];
    my %params = @args == 1 ? %{$args[0]} : @_;

    return $url unless my $language = $c->stash('language');
    my $code = $params{lang} // $language->{code};

    return $url if $code eq $english->{code};

    my $path = $url->path // [];

    unless ($path->[0]) {
      $path->parts([$code]);
    }

    else {
      my $exists = $c->languages->grep(sub {
        $path->contains(sprintf "/%s", $_->{code})
      })->size;

      unshift @{$path->parts}, $code unless $exists;
    }

    return $url;
  };

  {
    no strict 'refs';
    no warnings 'redefine';

    *Mojolicious::Controller::url_for = $lang_url_for;
  }
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::MultiLanguage - Find available native language

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Mojolicious>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Bugs should always be submitted via the GitHub bug tracker.

L<https://github.com/bitnoize/mojolicious-plugin-multilanguage/issues>

=head2 Source Code

Feel free to fork the repository and submit pull requests.

L<https://github.com/bitnoize/mojolicious-plugin-multilanguage>

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Dmitry Krutikov.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the README file.

=cut
