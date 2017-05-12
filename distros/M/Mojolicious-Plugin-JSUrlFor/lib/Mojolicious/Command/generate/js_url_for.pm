package Mojolicious::Command::generate::js_url_for;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Home;

our $VERSION = '0.17';

has description => <<'EOF';
Generate "url_for" function for javasctipt (perldoc Mojolicious::Plugin::JSUrlFor)
EOF

has usage => <<"EOF";
usage: $0 generate js_url_for \$file

\$file - file for saving javascript code
        For example, you can save it to public/static/url_for.js

EOF

sub run {
    my ( $self, $filename ) = @_;
    die $self->usage unless $filename;

    $self->app->plugin('Mojolicious::Plugin::JSUrlFor');
    my $js = $self->app->_js_url_for_code_only;

    $self->write_rel_file( $filename, $js );
}

1;
