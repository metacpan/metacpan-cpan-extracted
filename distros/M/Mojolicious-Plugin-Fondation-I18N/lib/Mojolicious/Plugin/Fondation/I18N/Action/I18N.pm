package Mojolicious::Plugin::Fondation::I18N::Action::I18N;
$Mojolicious::Plugin::Fondation::I18N::Action::I18N::VERSION = '0.01';
# ABSTRACT: Scans all plugins for translations, merges them, writes share/i18n/<lang>.json

use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;
use Mojo::JSON qw(decode_json encode_json);

# ---------------------------------------------------------------------------
# after_load -- called by Fondation Manager for each plugin
# ---------------------------------------------------------------------------

sub after_load ($self, $long, $conf, $share_dir) {
    return unless $share_dir && -d $share_dir;

    my $trans_dir = $share_dir->child('translations');
    return unless -d $trans_dir;

    my $manager  = $self->manager;
    my $app      = $manager->app;
    $app->{i18n_lexicons} //= {};

    my $added = 0;
    for my $file ($trans_dir->list({dir => 0})->each) {
        my $basename = $file->basename;
        next unless $basename =~ /^([a-z]{2}(?:[_-][a-z]{2})?)\.json$/i;
        my $lang = lc($1);

        my $data = eval { decode_json($file->slurp) };
        next if $@ || ref $data ne 'HASH';

        $app->{i18n_lexicons}{$lang} //= {};
        %{$app->{i18n_lexicons}{$lang}} = (
            %{$app->{i18n_lexicons}{$lang}},
            %$data,
        );
        $added += scalar(keys %$data);
    }

    return unless $added;

    $self->log->debug(sprintf('%s: %d translations loaded', $long, $added));

    # Write merged files after each plugin -- last write has everything
    _write_merged($manager);
}

# ---------------------------------------------------------------------------
# _write_merged -- write merged per-language JSON files to share/i18n/
# ---------------------------------------------------------------------------

sub _write_merged ($manager) {
    my $app      = $manager->app;
    my $lexicons = $app->{i18n_lexicons} or return;

    my $out_dir = $app->home->child('share', 'i18n');
    $out_dir->make_path unless -d $out_dir;

    for my $lang (sort keys %$lexicons) {
        my $file = $out_dir->child("$lang.json");
        $file->spurt(encode_json($lexicons->{$lang}));
    }
}

1;
