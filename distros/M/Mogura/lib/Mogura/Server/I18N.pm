package Mogura::Server::I18N;
use strict;
use warnings;
use Mojo::JSON qw(decode_json to_json);

my %catalogs;

sub supported {
    my ($locale) = @_;
    return defined($locale) && ($locale eq 'ja' || $locale eq 'en');
}

sub messages {
    my ($locale) = @_;
    $locale = 'en' unless supported($locale);
    return $catalogs{$locale} //=
        decode_json(Mogura::Server::assets()->child('public', 'locales', "$locale.json")->slurp);
}

sub translate {
    my ($locale, $key, %values) = @_;
    my $text = messages($locale)->{$key} // messages('en')->{$key} // $key;
    $text =~ s/\{([a-z_]+)\}/defined($values{$1}) ? $values{$1} : "{$1}"/ge;
    return $text;
}

sub client_messages {
    my ($locale) = @_;
    my $messages = messages($locale);
    my @keys = qw(
        tag_limit remove_tag inventory_refresh_failed submitting
        start_scan saving save_failed tag_added tag_removed saved
        result_range result_count result_count_one result_filtered result_filtered_one
        no_results table_load_failed browser_unsupported packages matches
        cache_save_failed list_separator cache_cleared cache_clear_failed loading
        building rebuild_packages rebuild_matches build_failed build_failed_detail
        result_format_invalid unknown
    );
    return {map { $_ => $messages->{$_} } @keys};
}

sub register {
    my ($class, $app) = @_;
    $app->hook(
        before_dispatch => sub {
            my ($controller) = @_;
            my $requested = $controller->req->url->query->param('lang');
            my $saved = $controller->cookie('mogura_language');
            my $locale = supported($saved) ? $saved : 'en';
            if ($controller->req->method eq 'GET' && supported($requested)) {
                $locale = $requested;
                $controller->cookie(
                    mogura_language => $locale,
                    {
                        path => '/',
                        max_age => 31536000,
                        samesite => 'Lax',
                        httponly => 1,
                        secure => $controller->req->is_secure ? 1 : 0,
                    }
                );
            }
            $controller->stash(locale => $locale);
            $controller->res->headers->content_language($locale);
        }
    );
    $app->helper(locale => sub { return shift->stash('locale') // 'en' });
    $app->helper(l => sub { my $c = shift; return translate($c->locale, @_) });
    $app->helper(locale_messages => sub { return to_json(client_messages(shift->locale)) });
    $app->helper(
        date_time => sub {
            my ($controller, $value) = @_;
            return $controller->l('unknown') unless defined $value && length $value;

            # Stored timestamps and downloadable metadata remain in UTC.
            return $value
                unless $value =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}:\d{2}:\d{2})(?:\.\d+)?Z\z/;
            return $controller->locale eq 'ja' ? "$1/$2/$3 $4" : "$2/$3/$1, $4";
        }
    );
}

1;
