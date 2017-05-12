package Plack::Middleware::Xslate;
BEGIN {
  $Plack::Middleware::Xslate::AUTHORITY = 'cpan:DOY';
}
{
  $Plack::Middleware::Xslate::VERSION = '0.03';
}
use strict;
use warnings;
# ABSTRACT: serve static templates with Plack

use base 'Plack::Middleware::Static';

use Plack::Util::Accessor 'xslate_args', 'xslate_vars';

use Text::Xslate;


sub prepare_app {
    my $self = shift;
    $self->{file} = Plack::App::File::Xslate->new({ root => $self->root || '.', encoding => $self->encoding, xslate_args => $self->xslate_args, xslate_vars => $self->xslate_vars });
    $self->{file}->prepare_app;
}

# XXX copied and pasted from Plack::Middleware::Static just so i can override
# with Plack::App::File::Xslate instead of Plack::App::File - submit a patch
# upstream to make this more configurable
sub _handle_static {
    my($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    local $env->{PATH_INFO} = $path; # rewrite PATH
    return $self->{file}->call($env);
}

package # hide from PAUSE
    Plack::App::File::Xslate;
use strict;
use warnings;

use base 'Plack::App::File';

use Plack::Util::Accessor 'xslate_args', 'xslate_vars';

use File::Spec;
use Cwd 'cwd';

sub prepare_app {
    my $self = shift;

    $self->SUPER::prepare_app(@_);

    $self->content_type('text/html');

    $self->xslate_args({
        %{ $self->xslate_args || {} },
        path => [ $self->root ],
    });
    $self->{xslate} = Text::Xslate->new($self->xslate_args || ());
}

sub serve_path {
    my $self = shift;
    my ($env, $file) = @_;

    my $res = $self->SUPER::serve_path(@_);

    my $filename = $res->[2]->path;
    if (File::Spec->file_name_is_absolute($filename)) {
        $filename = File::Spec->abs2rel($filename, $self->root);
    }

    $res->[2] = [
        $self->{xslate}->render($filename, $self->xslate_vars)
    ];

    Plack::Util::header_set($res->[1], 'Content-Length', length($res->[2][0]));

    return $res;
}


1;

__END__
=pod

=head1 NAME

Plack::Middleware::Xslate - serve static templates with Plack

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable "Xslate",
          path => qr{^/}, root => 'root/templates/', pass_through => 1;
      $app;
  };

=head1 DESCRIPTION

This middleware allows you to serve files processed as L<Text::Xslate>
templates. This is useful for serving sites that are essentially static
content, but with a consistent structure (which can be pulled out into a single
template to include, rather than duplicated across every page).

Configuration for this middleware is identical to L<Plack::Middleware::Static>,
with these additional options:

=over 4

=item xslate_args

A hashref of arguments to pass to the L<Text::Xslate> constructor. Note that
you cannot pass a C<path> argument here - it will be overridden by the C<root>
option.

=item xslate_vars

A hashref of data to use when rendering the template. This will be passed to
C<< Text::Xslate->render >> every time a template is rendered.

=back

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-plack-middleware-xslate at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-Xslate>.

=head1 SEE ALSO

L<Plack::Middleware::Static>

L<Plack::Middleware::TemplateToolkit>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Xslate

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Middleware-Xslate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-Xslate>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-Xslate>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Middleware-Xslate>

=back

=for Pod::Coverage prepare_app

=head1 AUTHOR

Jesse Luehrs <doy at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

