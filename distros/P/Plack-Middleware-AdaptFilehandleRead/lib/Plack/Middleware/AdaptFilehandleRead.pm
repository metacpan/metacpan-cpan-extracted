use strict;
use warnings;

package Plack::Middleware::AdaptFilehandleRead;

use base 'Plack::Middleware';
use Plack::Middleware::AdaptFilehandleRead::Proxy;
use Plack::Util::Accessor 'always_adapt', 'chunksize';
use Scalar::Util ();
use Plack::Util ();

our $VERSION = '0.003';

sub looks_like_a_readable_fh {
  my $self = shift;
  my $body = shift || return;             # If there's a body
  return Scalar::Util::blessed($body) &&  # and its an object
    $body->can('read') &&                 # which can 'read'
    ($self->always_adapt ||               # and either ->always_adapt
      !$body->can('getline'));            # or doesn't 'getline'
}

sub call {
  my($self, $env) = @_;
  my $res = $self->app->($env);
  return Plack::Util::response_cb($res, sub {
    if( $self->looks_like_a_readable_fh((my $r = shift)->[2]) ) {

      # We have an filehandle like object that doesn't do ->getline
      # so Plack can't do anything with it.  Wrap it in a proxy object
      # that adds the ->getline method by adapting read.  We assume
      # this ->read works like $fh->read(BUF, LEN, [OFFSET]).

      $r->[2] = Plack::Middleware::AdaptFilehandleRead::Proxy->new($r->[2], ($self->chunksize || 65536));
    }
  });
}

1;

=head1 NAME
 
Plack::Middleware::AdaptFilehandleRead - Give a filehandle a getline method when its missing
 
=head1 SYNOPSIS
  
    use Plack::Builder;
    use AppReturnsFileHandleWithRead;

    my $app = AppReturnsFileHandleWithRead->new;

    builder {
      enable 'AdaptFilehandleRead';
      $app;
    };
 
=head1 DESCRIPTION

L<PSGI> allows for the body content to be a glob filehandle or a Filehandle
like object.  For the later case the object must have a method C<getline>
which works as described in L<IO::Handle>.  However sometimes you may have
a custom filehandle like object that support the common C<read> method.  For
example many versions of L<Catalyst> allowed the body of a response to be a
glob or object that does C<read>.  People might have written custom streaming
applications that had this C<read> method but not C<getline>.  As a result
these custom Filehandle like objects are not compatible with the expectations
of L<PSGI>.

This middleware exists to help you convert such a custom made filehandle like
object.  If you have created something like this (or for example using some
shared code like L<MogileFS::Client> that returns a filehandle that does C<read>
but not C<getline>) you can use this middleware to wrap said object in a proxy
that does the C<getline> method by reading from the exising C<read> method.

By default, if this middleware is enabled, it will examine any body values and
check if they are 1) an object, 2) that does C<read> and 3) doesn't do C<getline>
If such a case exists it will create an instance of L<Plack::Middleware::AdaptFilehandleRead::Proxy>
which had the C<getline> method.  It also will delegate any other method calls
to the wrapped object via AUTOLOAD so if you have some additional custom methods
it will still work as expected.  It does not currently proxy any L<overload>ing.

If for some reason your custom filehandle like object does C<getline> but its
faulty and the C<read> method is correct, you can set C<always_adapt> to true
and the proxy will be applied even if a C<getline> method is detected.

    builder {
      enable 'AdaptFilehandleRead', always_adapt=>1;
      $app;
    };

This middleware will do its best to respect the various allowed values of
C<$/> for deciding how to return content from C<getline>  Currently we support
C<$/> values of scalar ref (like \8192 for reading fixed length chunks) or
simple scalars (like \n for reading newline delimited records).  Currently
we don't support C<$/> as undef (for slurping full content) and some of the other
more esoteric values of C<$/> as the author percieves that support was not needed
withing the context of adapting C<read> for L<PSGI> uses (all exampled L<Plack>
handlers seemed to use the scalar ref fixed length chunk value for C<$/>, but
we choose to also support the scalar record deliminator option since its very
commonly seen elsewhere).

=head1 ATTRIBUTES

This middleware has the following attributes:

=head2 always_adapt

Defaults to false, Optional.

Set this to any true value and the proxy will always wrap any filehandle like
object, as long as it has a C<read> method (even it if already has a C<getline>
method.)  Use this if you have a custom filehandle like object that you are using
as the body of a L<PSGI> reponse that has both C<read> and C<getline> but the
C<getline> is broken in some way (but C<read> isn't). 

=head2 chunksize

Defaults to 65536, Optional.

When adapting C<read>, we call for chunks of data 65536 in length.  This may not be the
most efficient way to read your files based on your specific requirements.  If so, you
may override the size of the chunks:

    builder {
      enable 'AdaptFilehandleRead', chunksize=>65536;
      $app;
    };

B<NOTE>: Be aware that the chunk is read into memory as each chunk is read.  Should a
chunk fail to find the deliminator indicated by C<$/>, another chunk would be read.
If you entire file contains no match, it is not impossible for the entire file to be 
thus read into memory should C<getline> be used.  In these cases you might wish to 
make sure your underlying L<Plack> server has other ways to handle these types of 
files (for example using XSendfile or via some other optimization.) or instead be sure
to use the fixed chunk sized option for C<$/>.

B<NOTE>: For most L<Plack> handlers, "$/" is set to a scalar refer, such as:

    local $/ = \'4096'

which is a flag indicating we'd prefer ->getline to return fixed length chunks
instead of variable length lines.  In this case the 'chunksize' attribute is
ignored.  Which means if you are using this with L<Plack> chances are this
attribute will not be respected :)  You probably should not worry about this!

=head1 SEE ALSO
 
L<PSGI>, L<Plack>, L<Plack::Middleware>, L<IO::File>,
L<Plack::Middleware::AdaptFilehandleRead::Proxy>.

See 'perlvar' docs for more on the possible values of C<$/>.
 
=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2014, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
