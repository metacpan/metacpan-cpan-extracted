package Plack::Middleware::TrailingSlashKiller;

use strict;
use warnings;
use parent qw(Plack::Middleware);

use Plack::Util::Accessor qw( redirect );

our $VERSION  = '0.01';
our %STATUSES = (
   301 => 'Moved Permanently',
   307 => 'Temporary Redirect',
);

sub call {
    my( $self, $env ) = @_;

    # check for/replace trailing slash
    if( $env->{PATH_INFO} =~ s{^(.+)/$}{$1} ) {
        # redirect if waned
        if( $self->redirect ) {
            my $code = ( $env->{REQUEST_METHOD } eq 'HEAD' ||
                         $env->{REQUEST_METHOD } eq 'GET' )
                     ? 301
                     : 307;
            my $location = $env->{PATH_INFO};
               $location .= "?$env->{QUERY_STRING}" if $env->{QUERY_STRING};

            return [ $code, [ 'Location' => $location ], [ $STATUSES{$code} ] ];
        }
    }

    # return the app's content (with possibly updated PATH_INFO)
    return $self->app->($env);
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::TrailingSlashKiller - Dealing with that pesky trailing slash/

=head1 SYNOPSIS

  builder {
    enable "TrailingSlashKiller",
      redirect => 1
  };

=head1 DESCRIPTION

C<Plack::Middleware::TrailingSlashKiller> will look for trailing slashes
in the requested URL and remove them. Based on the C<redirect> option,
it will either redirect or silently rewrite the URL before passing
it on to the app.

This module was written with L<Dancer2> in mind, where C</path> and
C</path/> are different (and the latter usually results in a 404).

=head1 PARAMETERS

=over 5

=item redirect

This boolean will instruct the module to either return 301 (GET/HEAD)
and 307 (other) results with a Location header or to silently rewrite
the URL without a trailing slash.

=back

=head1 SEE ALSO

L<Plack::Middleware>

=head1 AUTHOR

Menno Blom E<lt>blom@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Menno Blom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
