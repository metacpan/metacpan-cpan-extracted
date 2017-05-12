package Plack::Middleware::File::Sass;

use strict;
use 5.008_001;
our $VERSION = '0.03';

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(sass syntax);
use Plack::Util;
use IPC::Open3 qw(open3);
use Carp ();

my $text_sass;
my %valid = (sass => 1, scss => 1);

sub prepare_app {
    my $self = shift;

    $self->syntax("sass") unless defined $self->syntax;
    $valid{$self->syntax} or Carp::croak("Unsupported syntax: ", $self->syntax);

    my $sass = `sass -v`;
    if ($sass && $sass =~ /Sass 3/) {
        $self->sass(\&sass_command);
    } elsif (eval { require Text::Sass }) {
        $self->sass(\&sass_perl);
    } else {
        Carp::croak("Can't find sass gem nor Text::Sass module");
    }
}

sub sass_command {
    my($syntax, $body) = @_;

    my $pid = open3(my $in, my $out, my $err,
          "sass", "--stdin", ($syntax eq 'scss' ? '--scss' : ()));
    print $in $body;
    close $in;

    my $buf = join '', <$out>;
    waitpid $pid, 0;

    return $buf;
}

sub sass_perl {
    my($syntax, $body) = @_;

    my $method = "${syntax}2css";
    $text_sass ||= Text::Sass->new;
    $text_sass->$method($body);
}

sub call {
    my($self, $env) = @_;

    my $syntax = $self->syntax;

    # Sort of depends on how App::File works
    my $orig_path_info = $env->{PATH_INFO};
    if ($env->{PATH_INFO} =~ s/\.css$/.$syntax/i) {
        my $res = $self->app->($env);

        return $res unless ref $res eq 'ARRAY';

        if ($res->[0] == 200) {
            my $sass; Plack::Util::foreach($res->[2], sub { $sass .= $_[0] });
            my $css = $self->sass->($syntax, $sass);

            my $h = Plack::Util::headers($res->[1]);
            $h->set('Content-Type' => 'text/css');
            $h->set('Content-Length' => length $css);

            $res->[2] = [ $css ];
        } elsif ($res->[0] == 404) {
            $env->{PATH_INFO} = $orig_path_info;
            $res = $self->app->($env);
        }

        return $res;
    }

    return $self->app->($env);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Middleware::File::Sass - Sass and SCSS support for all Plack frameworks

=head1 SYNOPSIS

  use Plack::App::File;
  use Plack::Builder;

  builder {
      mount "/stylesheets" => builder {
          enable "File::Sass";
          Plack::App::File->new(root => "./stylesheets");
      };
  };

  # Or with Middleware::Static
  enable "File::Sass", syntax => "scss";
  enable "Static", path => qr/\.css$/, root => "./static";

=head1 DESCRIPTION

Plack::Middleware::File::Sass is a Plack middleware component that
works with L<Plack::App::File> or L<Plack::Middleware::Static> to
compile L<Sass|http://sass-lang.com/> templates into CSS stylesheet in
every request.

When a request comes in for I<.css> file, this middleware changes the
internal path to I<.sass> or I<.scss>, depending on the configuration,
in the same directory. If the Sass template is found, a new CSS
stylesheet is built on memory and served to the browsers.  Otherwise,
it falls back to the original I<.css> file in the directory.

This middleware should be very handy for the development. While Sass
to CSS rendering is reasonably fast, for the production environment
you might want to precompile Sass templates to CSS files on disk and
serves them with a real web server like nginx or lighttpd.

=head1 SASS BACKENDS

If you have the sass gem version higher than 3 installed and have the
C<sass> executable available in your PATH, this module automatically
uses the command to convert Sass or SCSS into CSS. If the command is
not available and you have L<Text::Sass> perl module available, it
will be used. Otherwise you'll get an exception during the
initialization of this middleware component.

=head1 OPTIONS

=over 4

=item syntax

Defines which syntax to use. Valid values are I<sass> and
I<scss>. Defaults to I<sass>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::App::File> L<Text::Sass> L<http://sass-lang.com/>

=cut
