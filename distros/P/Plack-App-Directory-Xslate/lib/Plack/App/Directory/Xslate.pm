package Plack::App::Directory::Xslate;
use strict;
use warnings;

our $VERSION = '0.07';

use parent qw(Plack::App::Directory);

use Text::Xslate;
use Encode ();
use File::Spec;

use Plack ();
use Plack::App::File ();
use Plack::Util ();
use Plack::Util::Accessor qw(xslate_opt xslate_path xslate_param);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->xslate_opt->{path} = $self->root;
    $self->{xslate}           = Text::Xslate->new($self->xslate_opt);
    $self->{encoder}          = Encode::find_encoding('utf-8');
    $self->xslate_param(+{}) unless $self->xslate_param;

    $self->xslate_path(sub {}) unless $self->xslate_path;
    if (ref $self->xslate_path eq 'Regexp') {
        my $re = $self->xslate_path;
        $self->xslate_path(sub { $_ =~ $re });
    }

    return $self;
}

sub serve_path {
    my ($self, $env, $path, $fullpath) = @_;

    if (-f $path && $self->is_xslate_path($path)) {
        return $self->serve_xslate($env, $path, $fullpath);
    }
    else {
        return $self->SUPER::serve_path($env, $path, $fullpath);
    }
}

sub is_xslate_path {
    my ($self, $path) = @_;

    local $_ = $path;
    return $self->xslate_path->($path);
}

sub serve_xslate {
    my ($self, $env, $path, $fullpath) = @_;

    my $tmpl_path = File::Spec->abs2rel($path, $self->root);
    my $content   = $self->{encoder}->encode(
        $self->{xslate}->render($tmpl_path, $self->xslate_param)
    );
    return [
        200,
        [
            'Content-Type'   => 'text/html',
            'Content-Length' => Plack::Util::content_length($content),
        ],
        [$content]
    ];
}

1;
__END__

=head1 NAME

  Plack::App::Directory::Xslate - Serve static files and Text::Xslate template files from document root with directory index

=head1 SYNOPSIS

  # app.psgi
  use Plack::App::Directory::Xslate;
  my $app = Plack::App::Directory::Xslate->new({
    root => "/path/to/htdocs",
    xslate_opt  => +{ # Text::Xslate->new()
        syntax => 'TTerse',
    },
    xslate_param => +{
        hoge => 'fuga',
    },
    xslate_path => qr{\.tt$},
 })->to_app;

=head1 DESCRIPTION

  This is a static files and Text::Xslate template files server PSGI application with directory index a la Apache's mod_autoindex.

=head1 CONFIGURATION

=over 4

=item root

  Document root directory. Defaults to the current directory.

=item xslate_opt

  Text::Xslate constructor option.

=item xslate_path : Regexp or CodeRef

  Allow Text::Xslate rendering path.

=item xslate_param : HashRef

  Text::Xslate rendering variables.

=back

=head1 AUTHOR

  Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::App::Directory>
L<Plack::App::File>
L<Plack::App::Xslate>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
