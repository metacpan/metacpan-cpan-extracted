package Plack::Middleware::DefaultDocument;

use strict;
use warnings;

our $VERSION = '0.02';

use parent 'Plack::Middleware';
use Plack::Util;
use Plack::MIME;

sub call {
    my $self = shift;
    my $env  = shift;

    my $r = $self->app->($env);

    $self->response_cb($r, sub {
        my $r = shift;
        return if $r->[0] != 404;

        for my $uri (grep { $_ ne 'app' } keys %$self) {
            if ($env->{PATH_INFO} =~ m{$uri}) {
                ## return 404 if the specified file doesn't exist
                return unless -f $self->{$uri};

                my $h = Plack::Util::headers($r->[1]);
                $h->remove('Content-Length');
                $h->set('Content-Type', Plack::MIME->mime_type($env->{PATH_INFO}));

                open my $fh, '<', $self->{$uri}
                    or die "Can't open file $self->{$uri}: $!";
                $r->[0] = 200;
                $r->[2] = $fh;

                return;
            }
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::DefaultDocument - Return default document with '200' instead of '404' error

=head1 SYNOPSIS

  enable "DefaultDocument" => (
      '/favicon\.ico$' => '/path/to/htodcs/favicon.ico',
      '/robots\.txt'   => '/path/to/htdocs/robots.txt',
  );

=head1 DESCRIPTION

This DefaultDocument middleware is able to return '200' response with default
document instead of '404' error. It is useful in the case that your application
can't find any contents from database, assets of users, static assets and etc,
but has system default file for request URL and to want to return it with '200'
reponse, not '404' errror.

=head1 SEE ALSO

L<Plack::Middleware::ErrorDocument>
    
=head1 AUTHOR

Hiroshi Sakai E<lt>ziguzagu@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
