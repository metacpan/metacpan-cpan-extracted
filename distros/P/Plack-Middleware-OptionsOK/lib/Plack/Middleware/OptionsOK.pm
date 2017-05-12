package Plack::Middleware::OptionsOK;

use strict;
use warnings;
use Plack::Util::Accessor qw(allow);
use parent qw( Plack::Middleware );

our $VERSION = 0.02;

sub call {
    my ( $self, $env ) = @_;

    if ($env->{REQUEST_METHOD} eq 'OPTIONS'
        && (   $env->{REQUEST_URI} eq '*'
            || $env->{REQUEST_URI} eq '/'
            || $env->{REQUEST_URI} eq '/*' )
        )
    {

        # We match /* because of the tests
        my $allow = $self->allow || 'GET HEAD OPTIONS';
        return [ 200, [ 'Allow' => $allow ], [] ];
    }

    # Not an OPTIONS * request, carry on...
    return $self->app->($env);

}

1;

__END__

=head1 NAME

  Plack::Middleware::OptionsOK

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  my $app = sub { ... } # as usual

  builder {
      enable "Plack::Middleware::OptionsOK",
      $app;
  };

=head1 DESCRIPTION

Many reverse Proxy servers (such as L<Perlbal>) use an
'OPTIONS *' request to confirm if a server is running.

This middleware will respond with a '200' to this
request so you do not have to handle it in your
app. There will be no further processing after this

=head1 OPTIONS

=head2 allow

   allow => 'GET HEAD OPTIONS'

The the C<Allow> header can be altered, it defaults to the list above.

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=head2 Contributors

Robert Rothenberg, rrwo@cpan.org

=head1 Repository (git)

https://github.com/ranguard/Plack-Middleware-OptionsOK, git://github.com/ranguard/Plack-Middleware-OptionsOK.git

=head1 COPYRIGHT

Copyright (c) 2011 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack> L<Plack::Builder> L<Perlbal>

=cut

