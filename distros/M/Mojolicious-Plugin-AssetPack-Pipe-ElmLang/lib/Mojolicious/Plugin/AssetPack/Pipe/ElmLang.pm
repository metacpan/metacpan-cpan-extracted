package Mojolicious::Plugin::AssetPack::Pipe::ElmLang;

use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(diag $CWD DEBUG);
use File::Temp;

our $VERSION = '0.4';

sub process {
    my ($self, $assets) = @_;

    # Normally a Mojolicious::Plugin::AssetPack::Store object
    my $store = $self->assetpack->store;

    my $file;
    my $mode = $self->app->mode;

    # Loop over Mojolicious::Plugin::AssetPack::Asset objects
    $assets->each(
        sub {
            my ($asset, $index) = @_;

            my $attrs = $asset->TO_JSON;
            $attrs->{key}    = 'elm';
            $attrs->{format} = 'js';
            
            return unless $asset->format eq 'elm';

            # massage the checksum so we can compile elm packages that are spread across multiple files
            $attrs->{checksum} = $attrs->{checksum} . "_" . sprintf("%x", time());
            
            $self->_install_elm unless $self->{installed}++;
            
            diag 'Process "%s" with checksum %s.', $asset->url, $attrs->{checksum} if $mode eq "development";
            
            my $elm_make = $self->app->home->rel_file('node_modules/.bin/elm-make');

            my @args = ($elm_make->path->to_string);

            my $tmp = File::Temp->new( SUFFIX => '.js' );
            push @args , '--yes', '--output' , $tmp->filename;
            push @args , '--debug' if $mode eq 'development';

            my $file = $asset->path ? $asset : Mojo::Asset::File->new->add_chunk($asset->content);
            
            push @args , $file->path->to_string;

            $self->run(\@args, undef, undef);

            my $js = do { local(@ARGV, $/) = $tmp; <> };

            $asset->content($store->save(\$js, $attrs))->FROM_JSON($attrs);
        }
    );
}

sub _install_elm {
  my $self = shift;
  my $path = $self->app->home->rel_file('node_modules/.bin/elm-make');
  return $path if -e $path;
  local $CWD = $self->app->home->to_string;
  $self->app->log->warn(
    'Installing elm ... Please wait. (npm install elm)');
  $self->run([qw(npm install elm)]);
  return $path;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AssetPack::Pipe::ElmLang - process .elm files

=head1 VERSION

0.4.2

=head1 DESCRIPTION

L<Mojolicious::Plugin::AssetPack::Pipe::ElmLang> will process
L<http://elm-lang.org/> files into JavaScript.

This module require the C<elm-make> program to be installed. C<elm-make> will be
automatically installed using L<https://www.npmjs.com/> unless already
installed.

=head1 SYNOPSIS

    use lib '../lib';
    use Mojolicious::Lite;

    plugin 'AssetPack' => {pipes => ['ElmLang']};

    app->asset->process('app.js' => 'test.elm');

    # Set up the mojo lite application and start it
    get '/' => 'index';
    app->start;
    __DATA__
    @@ index.html.ep
    <!DOCTYPE HTML>
    <html>
    <head>
    <title>Test</title>
    %= asset 'app.js';
    </head>
    <body>
    <script type="text/javascript">
        Elm.Main.fullscreen()
    </script>
    </body>
    </html>

=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack>.

=cut
