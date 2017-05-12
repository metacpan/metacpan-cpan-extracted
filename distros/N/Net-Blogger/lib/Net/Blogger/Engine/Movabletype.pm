{

=head1 NAME

Net::Blogger::Engine::Movabletype - Movabletype Blogger API engine

=head1 SYNOPSIS

 my $mt = Net::Blogger->new(engine=>"movabletype");

 $mt->Proxy("http://mtserver.com/mt-xmlrpc.cgi");
 $mt->Username("foo");
 $mt->Password("bar");

 my $postid_1 = $mt->newPost(postbody=>\"hello world") 
    || croak $mt->LastError();

 my $postid_2 = $mt->metaWeblog()->newPost(
	   		                   title=>"hello",
			                   description=>"world",
			                   publish=>1,
			                   );

=head1 DESCRIPTION

This package inherits I<Net::Blogger::Engine::Base> and implements 
methods specific to a MovableType XML-RPC server.

=cut

package Net::Blogger::Engine::Movabletype;
use strict;

$Net::Blogger::Engine::Movabletype::VERSION   = '1.0';
@Net::Blogger::Engine::Movabletype::ISA       = qw ( Exporter Net::Blogger::Engine::Base );
@Net::Blogger::Engine::Movabletype::EXPORT    = qw ();
@Net::Blogger::Engine::Movabletype::EXPORT_OK = qw ();

use Exporter;
use Net::Blogger::Engine::Base;

=head1 Blogger API OBJECT METHODS

=cut

=head2 $pkg->getRecentPosts(\%args)

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=cut

sub getRecentPosts {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

    my $num   = (defined $args->{'numposts'}) ? $args->{'numposts'} : 1;
    my $posts = [];

    unless ($num =~ /^(-)*(\d+)$/) {
	$self->LastError("Argument $args->{'numposts'} isn't numeric.");
        return 0;
    }

    if ($num > -1) { $num = 0; }

    return $self->SUPER::getRecentPosts($args);
}

=head1 Movable Type (mt) API OBJECT METHODS

=cut

=head2 $pkg->mt()

Returns an object. Woot!

=cut

sub mt {
  my $self = shift;

  if (! $self->{'__mt'}) {

    require Net::Blogger::Engine::Movabletype::mt;
    my $mt = Net::Blogger::Engine::Movabletype::mt->new(debug=>$self->{debug});

    map { $mt->$_($self->$_()); } qw (BlogId Proxy Username Password);
    $self->{'__mt'} = $mt;
  }

  return $self->{'__mt'};
}

=head1 metaWeblog API OBJECT METHODS

=cut

=head2 $pkg->metaWeblog()

Returns an object. Woot!

=cut

sub metaWeblog {
  my $self = shift;

  if (! $self->{__meta}) {

    require Net::Blogger::Engine::Userland::metaWeblog;
    my $meta = Net::Blogger::Engine::Userland::metaWeblog->new(debug=>$self->{debug});

    map { $meta->$_($self->$_()); } qw (BlogId Proxy Username Password);
    $self->{__meta} = $meta;
  }

  return $self->{__meta};
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::Engine::Base>

L<Net::Blogger::Engine::Movabletype::mt>

L<Net::Blogger::Engine::Userland::metaWeblog>

http://aaronland.net/weblog/archive/3719

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
