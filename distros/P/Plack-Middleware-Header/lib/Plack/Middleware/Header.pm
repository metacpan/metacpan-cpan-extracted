package Plack::Middleware::Header;

use strict;
use 5.008_001;
use parent qw(Plack::Middleware);
 
__PACKAGE__->mk_accessors(qw(set append unset));
 
use Plack::Util;

our $VERSION = '0.04';
 
sub call {
    my $self = shift; 
    my $res  = $self->app->(@_);
 
    $self->response_cb(
        $res,
        sub {
            my $res = shift;
            my $headers = $res->[1];

            if ( $self->set ) {
                Plack::Util::header_iter($self->set, sub {Plack::Util::header_set($headers, @_)});
            }
            if ( $self->append ) {
                push @$headers, @{$self->append};
            }
            if ( $self->unset ) {
                Plack::Util::header_remove($headers, $_) for @{$self->unset};
            }
        }
    );
}
 
1;
 
__END__
 
=head1 NAME
 
Plack::Middleware::Header - modify HTTP response headers
 
=head1 SYNOPSIS
 
  use Plack::Builder;
 
  my $app = sub {['200', [], ['hello']]};
  builder {
      enable 'Header',
        set => ['X-Plack-One' => '1'],
        append => ['X-Plack-Two' => '2'],
        unset => ['X-Plack-Three'];
      $app;
  };

=head1 DESCRIPTION
 
Plack::Middleware::Header
 
=head1 AUTHOR
 
Masahiro Chiba

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 SEE ALSO
 
L<Plack::Middleware> L<Plack::Builder>
 
=cut
