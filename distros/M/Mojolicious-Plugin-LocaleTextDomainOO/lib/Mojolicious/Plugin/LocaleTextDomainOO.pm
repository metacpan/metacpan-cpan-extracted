package Mojolicious::Plugin::LocaleTextDomainOO;
use Mojo::Base 'Mojolicious::Plugin';

use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::File::PO;
use Locale::TextDomain::OO::Lexicon::File::MO;
use I18N::LangTags;
use I18N::LangTags::Detect;

use constant DEBUG => $ENV{MOJO_I18N_DEBUG} || 0;

our $VERSION = '0.05';

has 'po' => sub { Locale::TextDomain::OO::Lexicon::File::PO->new };
has 'mo' => sub { Locale::TextDomain::OO::Lexicon::File::MO->new };

my $plugins_default = [
    qw/
      Expand::Gettext::DomainAndCategory
      Language::LanguageOfLanguages
      /
];

sub register {
    my ( $plugin, $app, $plugin_config ) = @_;

    # Initialize
    my $file_type = $plugin_config->{file_type} || 'po';
    my $default   = $plugin_config->{default}   || 'en';
    $default =~ tr/-A-Z/_a-z/;
    $default =~ tr/_a-z0-9//cd;
    my $languages = $plugin_config->{languages} // [$default];

    my $plugins = $plugins_default;
    push @$plugins, @{ $plugin_config->{plugins} }
      if ( ref $plugin_config->{plugins} eq 'ARRAY' );

    my $logger = sub { };
    $logger = sub {
        my ( $message, $arg_ref ) = @_;
        my $type = $arg_ref->{type} || 'debug';
        $app->log->$type($message);
        return;
      }
      if DEBUG;

    # Default Handler
    my $loc = sub {
        Locale::TextDomain::OO->instance(
            plugins   => $plugins,
            languages => $languages,
            logger    => $logger,
        );
    };

    # Add hook and replace url_for helper
    $Mojolicious::Plugin::LocaleTextDomainOO::I18N::code->(
        $app, $plugin_config
    );

    # Add "locale" helper
    $app->helper( locale => $loc );

    # Add "lexicon" helper
    $app->helper(
        lexicon => sub {
            my ( $app, $conf ) = @_;
            $conf->{decode} = $conf->{decode} // 1;    # Default: utf8 flaged
            $plugin->$file_type->lexicon_ref($conf);
        }
    );

    # Add "languages" helper
    $app->helper(
        languages => sub {
            my ( $self, @languages ) = @_;
            unless (@languages) { $self->locale->languages }
            else                { $self->locale->languages( \@languages ) }
        }
    );

    # Add "language" helper
    $app->helper(
        language => sub {
            my ( $self, $language ) = @_;
            unless ($language) { $self->locale->language }
            else               { $self->locale->language($language) }
        }
    );

    # Add helper from gettext methods
    my @methods = (
        qw/
          __  __x  __n  __nx  __p  __px  __np  __npx
          N__  N__x  N__n  N__nx  N__p  N__px  N__np  N__npx
          __d  __dn  __dp  __dnp  __dx  __dnx  __dpx  __dnpx
          N__d  N__dn  N__dp  N__dnp  N__dx  N__dnx  N__dpx  N__dnpx
          /
    );
    foreach my $method (@methods) {
        $app->helper( $method => sub { shift->app->locale->$method(@_) } );
    }

    foreach my $method (qw /__begin_d  __end_d/) {
        $app->helper( $method => sub { shift->app->locale->$method(@_); undef; }
        );
    }
}

#######################################################################
###  This code is Mojolicious::Plugin::I18N
#######################################################################
package Mojolicious::Plugin::LocaleTextDomainOO::I18N;

our $code = sub {
    my ( $app, $conf ) = @_;

    my $langs   = $conf->{support_url_langs};
    my $hosts   = $conf->{support_hosts};
    my $default = $conf->{default} || 'en';
    $default =~ tr/-A-Z/_a-z/;
    $default =~ tr/_a-z0-9//cd;

    # Add hook
    $app->hook(
        before_dispatch => sub {
            my $self = shift;

            # Header detection
            my @languages =
              $conf->{no_header_detect}
              ? ()
              : I18N::LangTags::implicate_supers(
                I18N::LangTags::Detect->http_accept_langs(
                    $self->req->headers->accept_language
                )
              );

            # Host detection
            my $host = $self->req->headers->header('X-Host')
              || $self->req->headers->host;
            if ( $conf->{support_hosts} && $host ) {
                warn $host;
                $host =~ s/^www\.//;    # hack
                if ( my $lang = $conf->{support_hosts}->{$host} ) {
                    $self->app->log->debug(
                        "Found language $lang, Host header is $host");

                    unshift @languages, $lang;
                }
            }

            # Set default language
            $self->stash( lang_default => $languages[0] ) if $languages[0];

            # URL detection
            if ( my $path = $self->req->url->path ) {
                my $part = $path->parts->[0];

                if ( $part && $langs && grep { $part eq $_ } @$langs ) {

                    # Ignore static files
                    return if $self->res->code;

                    $self->app->log->debug("Found language $part in URL $path");

                    unshift @languages, $part;

                    # Save lang in stash
                    $self->stash( lang => $part );

                    # Clean path
                    shift @{ $path->parts };
                    $path->trailing_slash(0);
                }
            }

            # Languages
            $self->languages( @languages, $default );
        }
    );

    # Reimplement "url_for" helper
    my $mojo_url_for = *Mojolicious::Controller::url_for{CODE};

    my $i18n_url_for = sub {
        my $self = shift;
        my $url  = $self->$mojo_url_for(@_);

        # Absolute URL
        return $url if $url->is_abs;

        # Discard target if present
        shift if ( @_ % 2 && !ref $_[0] ) || ( @_ > 1 && ref $_[-1] );

        # Unveil params
        my %params = @_ == 1 ? %{ $_[0] } : @_;

        # Detect lang
        if ( my $lang = $params{lang} || $self->stash('lang') ) {
            my $path = $url->path || [];

            # Root
            if ( !$path->[0] ) {
                $path->parts( [$lang] );
            }

            # No language detected
            elsif ( ref $langs ne 'ARRAY'
                or not scalar grep { $path->contains("/$_") } @$langs )
            {
                unshift @{ $path->parts }, $lang;
            }
        }

        $url;
    };

    {
        no strict 'refs';
        no warnings 'redefine';

        *Mojolicious::Controller::url_for = $i18n_url_for;
    }
};

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::LocaleTextDomainOO - I18N(GNU getext) for Mojolicious.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('LocaleTextDomainOO');

  # Mojolicious::Lite
  plugin 'LocaleTextDomainOO';


=head2 Plugin configuration

  # your app in startup method
  sub startup {
      # setup plugin
      $self->plugin('LocaleTextDomainOO',
        {
            file_type => 'po',              # or 'mo'. default: po
            default => 'ja',                # default en
            plugins => [                    # more Locale::TextDomain::OO plugins.
                qw/ +Your::Special::Plugin  # default Expand::Gettext::DomainAndCategory plugin onry.
            /],
            languages => [ qw( en-US en ja-JP ja de-DE de ) ],

            # Mojolicious::Plugin::I18N like options
            no_header_detect => $boolean,               # option. default: false
            support_url_langs => [ qw( en ja de ) ],    # option
            support_hosts => {                          # option
                'mojolicious.ru' => 'ru',
                'mojolicio.us' => 'en'
            }
        }
      );

      # loading lexicon files
      $self->lexicon(
          {
              search_dirs => [qw(/path/my_app/locale)],
              gettext_to_maketext => $boolean,              # option
              decode => $boolean,                           # option
              data   => [ '*::' => '*.po' ],
          }
      );
    ...
  }

=head1 DESCRIPTION

L<Locale::TextDomain::OO> is a internationalisation(I18N) tool of perl OO interface.
L<Mojolicious::Plugin::LocaleTextDomainOO> is internationalization  plugin for L<Mojolicious>.

This module is similar to L<Mojolicious::Plugin::I18N>.
But, L<Locale::MakeText> is not using "text domain" and more...

=head1 OPTIONS

=head2 C<file_type>

    plugin LocaleTextDomainOO => { file_type => 'po' };

Gettext lexicon File type. default to C<po>.

=head2 C<default>

    plugin LocaleTextDomainOO => { default => 'ja' };

Default language. default to C<en>.

=head2 C<languages>

    plugin LocaleTextDomainOO => { languages => [ 'en-US', 'en', 'ja-JP', 'ja' ] };

=head2 C<plugins>

    plugin LocaleTextDomainOO => { plugins => [ qw /Your::LocaleTextDomainOO::Plugin/ ] };

Add plugin. default using L<Locale::TextDomain::OO::Plugin::Expand::Gettext::DomainAndCategory>
and L<Locale::TextDomain::OO::Plugin::Language::LanguageOfLanguages> plugin onry.

=head2 C<support_url_langs>

    plugin LocaleTextDomainOO => { support_url_langs => [ 'en', 'ja', 'de' ] };

Detect language from URL. see L<Mojolicious::Plugin::I18N> option.

=head2 C<support_hosts>

    plugin LocaleTextDomainOO => { support_hosts => { 'mojolicious.ru' => 'ru', 'mojolicio.us' => 'en' } };

Detect Host header and use language for that host. see L<Mojolicious::Plugin::I18N> option.

=head2 C<no_header_detect>

    plugin LocaleTextDomainOO => { no_header_detect => 1 };

Off header detect. see L<Mojolicious::Plugin::I18N> option.


=head1 HELPERS

=head2 C<locale>

    # Mojolicious Lite
    my $loc = app->locale;

Returned Locale::TextDomain::OO object.

=head2 C<lexicon>

    app->lexicon(
        {
            search_dirs => [qw(your/my_app/locale)],
            gettext_to_maketext => $boolean,
            decode => $boolean,                         # default true. *** utf8 flaged ***
            data   => [
                '*::' => '*.po',
                '*:CATEGORY:DOMAIN' => '*/test.po',
            ],
        }
    );

Gettext '*.po' or '*.mo' file as lexicon.
See L<Locale::TextDomain::OO::Lexicon::File::PO> L<Locale::TextDomain::OO::Lexicon::File::MO>

=head2 C<language>

    app->language('ja');
    my $language = app->language;

Set or Get language.

=head2 C<__, __x, __n, __nx>

    # In controller
    app->__('hello');
    app->__x('hello, {name}', name => 'World');

    # In template
    <%= __ 'hello' %>
    <%= __x 'hello, {name}', name => 'World' %>

See L<Locale::TextDomain::OO::Plugin::Expand::Gettext>

=head2 C<__p, __px, __np, __npx>

    # In controller
    app->__p(
        'time',  # Context (msgctxt)
        'hello'
    );

    # In template
    <%= __p 'time', 'hello' %>

See L<Locale::TextDomain::OO::Plugin::Expand::Gettext>

=head2 C<N__, N__x, N__n, N__nx, N__p, N__px, N__np, N__npx>

See L<Locale::TextDomain::OO::Plugin::Expand::Gettext>

=head2 C<__begin_d, __end_d, __d, __dn, __dp, __dnp, __dx, __dnx, __dpx, __dnpx>

    # In controller
    app->__d(
        'domain',  # Text Domain
        'hello'
    );

    # In template
    <%= __d 'domain', 'hello' %>

    # begin, end
    <%= __begin_d 'domain' %>
        <%= __ 'hello' %>
        <%= __ 'hello2' %>
    <%= __end_d %>

See L<Locale::TextDomain::OO::Plugin::Expand::Gettext::DomainAndCategory>

=head2 C<N__d, N__dn, N__dp, N__dnp, N__dx, N__dnx, N__dpx, N__dnpx>

See L<Locale::TextDomain::OO::Plugin::Expand::Gettext::DomainAndCategory>

=head1 METHODS

L<Mojolicious::Plugin::LocaleTextDomainOO> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 DEBUG MODE

    # debug mode on
    BEGIN { $ENV{MOJO_I18N_DEBUG} = 1 }

    # or
    MOJO_I18N_DEBUG=1 perl script.pl

=head1 AUTHOR

Munenori Sugimura <clicktx@gmail.com>

=head1 SEE ALSO

L<Locale::TextDomain::OO>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 LICENSE of Mojolicious::Plugin::I18N

Mojolicious::Plugin::LocaleTextDomainOO uses Mojolicious::Plugin::I18N code. Here is LICENSE of Mojolicious::Plugin::I18N

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.


=cut
