# 
# This file is part of Plack-App-JSP
# 
# This software is copyright (c) 2010 by Patrick Donelan <pat@patspam.com>.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
package Plack::App::JSP;
BEGIN {
  $Plack::App::JSP::VERSION = '0.101680';
}
# ABSTRACT: Javascript PSGI apps via JSP

use strict;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(js ctx);
use JSP;

sub prepare_app {
    my $self = shift;
    $self->ctx( JSP->stock_context );
}

sub call {
    my ( $self, $env ) = @_;
    my $res = $self->ctx->eval( $self->js );
    $res->[2] = [ map Encode::encode( 'utf8', $_ ), @{ $res->[2] } ]
      if ref $res->[2] eq 'ARRAY';
    return $res;
}

1;


__END__
=pod

=head1 NAME

Plack::App::JSP - Javascript PSGI apps via JSP

=head1 VERSION

version 0.101680

=head1 SYNOPSIS

 # app.psgi - looks pretty normal
 use Plack::App::JSP;
 Plack::App::JSP->new( js => q{
   [ 200, [ 'Content-type', 'text/html' ], [ 'Hello, World!' ] ] 
 });

 # app.psgi - hello Javascript!
 Plack::App::JSP->new( js => q{
    function respond(body) {
        return [ 200, [ 'Content-type', 'text/html' ], [ body ] ]
    }
    
    respond("Five factorial is " + 
        (function(x) {
          if ( x<2 ) return x;
          return x * arguments.callee(x - 1);
        })(5)
    );
 });

=head1 DESCRIPTION

Use Javascript to write a PSGI/L<Plack> app

=head1 ATTRIBUTES

=head2 js

Your Javascript

=head1 SEE ALSO

L<JSP>, L<Plack>

=cut

=head1 AUTHOR

  Patrick Donelan <pat@patspam.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Patrick Donelan <pat@patspam.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

