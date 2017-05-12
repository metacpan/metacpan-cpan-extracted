package Plack::Middleware::File::Less;

# ABSTRACT: LESS CSS support

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.04';

use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(less);
use IPC::Open3 qw(open3);
use Carp;

sub prepare_app {
    my $self = shift;
    $self->less(\&less_command);
    my $less = `lessc -v`;
    if ($less) {
        $self->less(\&less_command);
    } elsif (eval { require CSS::LESSp }) {
        $self->less(\&less_perl);
    } else {
        Carp::croak("Can't find lessc command nor CSS::LESSp module");
    }
}

sub less_command {
    my $less = shift;
    my $pid = open3(my $in, my $out, my $err, "lessc", "-");
    print $in $less;
    close $in;

    my $buf = join '', <$out>;
    waitpid $pid, 0;

    return $buf;
}

sub less_perl {
    return join "", CSS::LESSp->parse(shift);
}

sub call {
    my ($self, $env) = @_;

    my $orig_path_info = $env->{PATH_INFO};
    if ($env->{PATH_INFO} =~ s/\.css$/.less/i) {
        my $res = $self->app->($env);

        return $res unless ref $res eq 'ARRAY';

        if ($res->[0] == 200) {
            my $less;
            Plack::Util::foreach($res->[2], sub { $less .= $_[0] });

            my $css = $self->less->($less);

            my $h = Plack::Util::headers($res->[1]);
            $h->set('Content-Type'   => 'text/css');
            $h->set('Content-Length' => length $css);

            $res->[2] = [$css];
        }
        elsif ($res->[0] == 404) {
            $env->{PATH_INFO} = $orig_path_info;
            $res = $self->app->($env);
        }

        return $res;
    }
    return $self->app->($env);
}

1;

=head1 NAME

Plack::Middleware::File::Less - compile LESS templates into CSS stylesheets

=head1 SYNOPSIS

  use Plack::App::File;
  use Plack::Builder;

  builder {
      mount "/stylesheets" => builder {
          enable "File::Less";
          Plack::App::File->new(root => "./stylesheets");
      };
  };

  # Or with Middleware::Static
  enable "File::Less";
  enable "Static", path => qr/\.css$/, root => "./static";

=head1 DESCRIPTION

Plack::Middleware::File::Less is middleware that compiles
L<Less|http://lesscss.org> templates into CSS stylesheet..

When a request comes in for I<.css> file, this middleware changes the
internal path to I<.less> in the same directory. If the LESS template
is found, a new CSS stylesheet is built on memory and served to the
browsers.  Otherwise, it falls back to the original I<.css> file in
the directory.

=head1 LESS BACKENDS

If you have the C<lessc> executable available in your PATH, this
module automatically uses the command to convert LESS into CSS. If the
command is not available and you have L<CSS::LESSp> perl module
available, it will be used. Otherwise you'll get an exception during
the initialization of this middleware component.

=head1 SEE ALSO

L<Plack::App::File> L<CSS::LESSp> L<http://lesscss.org/>

=head1 AUTHORS

=over 4

=item *

Naoya Ito <lt>i.naoya@gmail.com<gt>

=item *

Franck Cuny <lt>https://github.com/franckcuny<gt>

=item *

Tatsuhiko Miyagawa <lt>miyagawa@bulknews.net<gt>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
