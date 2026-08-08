package Template::Stencil::PSGI;

use 5.010;
use strict;
use warnings;
use Template::Stencil;

our $VERSION = '0.04';

sub new {
    my ($class, %opts) = @_;
    return bless { stencil => Template::Stencil->new(%opts) }, $class;
}

sub stencil { $_[0]{stencil} }

sub res {
    my ($self, $template, $data, $status, $headers) = @_;
    my $body = $self->{stencil}->render($template, $data || {});
    return [ $status || 200,
             [ 'Content-Type'   => 'text/html; charset=utf-8',
               'Content-Length' => length $body,
               @{ $headers || [] } ],
             [ $body ] ];
}

sub to_app {
    my ($self, $routes) = @_;
    return sub {
        my $env = shift;
        my $r = $routes->{ $env->{PATH_INFO} }
            or return [ 404, [ 'Content-Type' => 'text/plain' ],
                        ['Not Found'] ];
        my ($template, $data) = ref $r eq 'ARRAY' ? @$r : ($r, undef);
        $data = $data->($env) if ref $data eq 'CODE';
        return $self->res($template, $data);
    };
}

1;

__END__

=head1 NAME

Template::Stencil::PSGI - tiny PSGI conveniences for Template::Stencil

=head1 SYNOPSIS

    use Template::Stencil::PSGI;

    my $view = Template::Stencil::PSGI->new(
        template_dir => 'templates',
        wrapper      => 'wrapper.tmpl',
    );

    # a finished PSGI response tuple
    my $res = $view->res('index', { title => 'Hi' });

    # or a tiny routed app
    my $app = $view->to_app({
        '/'      => [ 'index', sub { my $env = shift; { title => 'Hi' } } ],
        '/about' => 'about',
    });

=head1 METHODS

=head2 new

Takes exactly the L<Template::Stencil> constructor options.

=head2 stencil

The underlying L<Template::Stencil> object.

=head2 res($template, \%data, $status, \@headers)

Render and return a PSGI response tuple. Status defaults to 200; extra
headers are appended after Content-Type and Content-Length.

=head2 to_app(\%routes)

Returns a PSGI app. A route value is either a template name or
C<[$template, \%data | sub ($env) { ... } ]>. Unknown paths get a 404.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.
This is free software, licensed under The Artistic License 2.0.

=cut
