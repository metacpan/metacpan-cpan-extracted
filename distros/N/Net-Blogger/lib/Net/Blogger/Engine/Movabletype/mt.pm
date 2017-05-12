{

=head1 NAME

mt - Adds support for the MovableType XML-RPC API

=head1 SYNOPSIS

 use Net::Blogger;

 use Carp;
 use Data::Dumper;

 my $mt = Net::Blogger->new(engine=>"movabletype");

 $mt->Proxy("http://yaddayadda.com/mt-xmlrpc.cgi");
 $mt->Username("asc");
 $mt->Password("*****");
 $mt->BlogId(123);

 $mt->newPost(postbody=>\&fortune(),publish=>1)
   || croak $mt->LastError();

 my $id = $mt->metaWeblog()->newPost(title=>"test:".time,
  				     description=>&fortune(),
				      publish=>1)
   || croak $mt->LastError();

 my $categories = $mt->mt()->getCategoryList()
   || croak $mt->LastError();

 my $cid = $categories->[0]->{categoryId};

 $mt->mt()->setPostCategories(postid=>$id,
                              categories=>[{categoryId=>$cid}])
   || croak $mt->LastError();

 print &Dumper($mt->mt()->getPostCategories(postid=>$id));

 sub fortune {
   local $/;
   undef $/;

   system ("fortune > /home/asc/tmp/fortune");

   open F, "</home/asc/tmp/fortune";
   my $fortune = <F>;
   close F;

   return $fortune;
 }

=head1 DESCRIPTION

Adds support for the MovableType XML-RPC API

=cut

package Net::Blogger::Engine::Movabletype::mt;
use strict;

use Exporter;
use Net::Blogger::Engine::Base;

$Net::Blogger::Engine::Movabletype::mt::VERSION   = '1.0';

@Net::Blogger::Engine::Movabletype::mt::ISA       = qw ( Exporter Net::Blogger::Engine::Base );
@Net::Blogger::Engine::Movabletype::mt::EXPORT    = qw ();
@Net::Blogger::Engine::Movabletype::mt::EXPORT_OK = qw ();

=head1 OBJECT METHODS

=cut

=head2 $obj->getRecentPostTitles(\%args)

Valid arguments are :

=over 4

=item *

B<count>

Int. 

The number of post titles to fetch. Default is I<20>

=item *

B<asc>

Boolean.

As in: return data ordered by ascending date. By default, items are
returned 'most recent first'.

=back

Returns an array ref of hash refs. Each hash ref contains the following 
keys :

=over 4

=item *

B<postid>

=item *

B<userid>

=item *

B<title>

String.

=item *

B<dateCreated>

String, formatted as a W3CDTF datetime.

=back

This method was introduced in Net::Blogger 0.86 and does B<not> accept
arguments passed as a list. They B<must> be passed by reference.

=cut

sub getRecentPostTitles {
    my $self = shift;
    my $args = shift;

    # Translate numbers for humans
    # to zero-based count.

    my $count = 19;

    if (exists($args->{count})) {
	$count = ($args->{count} - 1);
    }

    #

    my $call = $self->_Client()->call(
				      "mt.getRecentPostTitles",
				      $self->_Type(string=>$self->BlogId()),
				      $self->_Type(string=>$self->Username()),
				      $self->_Type(string=>$self->Password()),
				      $self->_Type((int=>$_[0] || 20)),
				      );

    #

    if (! exists($args->{asc})) {
	return ($call) ? $call->result() : undef;
    }

    elsif (! $call) {
	return undef;
    }

    else {
	return [ reverse @{$call->result()} ];
    }
}

=head2 $obj->getCategoryList()

Returns an array ref of hash references.

=cut

sub getCategoryList {
  my $self = shift;

  my $call = $self->_Client()->call(
				    "mt.getCategoryList",
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    );

  return ($call) ? $call->result() : undef;
}

=head2 $obj->getPostCategories(\%args)

Valid arguments are 

=over

=item *

B<postid>

String. I<required>

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an array ref of hash references

=cut

sub getPostCategories {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  if (! $args->{'postid'}) {
    $self->LastError("You must specify a postid");
    return undef;
  }

  my $call = $self->_Client()->call(
				    "mt.getPostCategories",
				    $self->_Type(string=>$args->{'postid'}),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    );

  return ($call) ? $call->result() : undef;
}

=head2 $obj->setPostCategories(\%args)

Valid argument are

=over

=item *

B<postid>

String. Required

B<categories>

Array ref. I<required>

The MT docs state that :

=over 4

=item * 

The array categories is an array of structs containing 

=over 4

=item * 

B<categoryId>

String.

=item *

B<isPrimary>

Using isPrimary to set the primary category is optional--in the absence of 
this flag, the first struct in the array will be assigned the primary category for 
the post

=back

=back

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false

=cut

sub setPostCategories {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};
  
  if (! $args->{'postid'}) {
    $self->LastError("You must specify a postid");
    return undef;
  }

  if (ref($args->{'categories'}) ne "ARRAY") {
    $self->LastError("You must pass category data as an array reference.");
    return undef;
  }

  foreach my $struct (@{$args->{'categories'}}) {
    if (! $struct->{'categoryId'}) {
      $self->LastError("Category struct requires a categoryId.");
      return undef;
    }
  }

  my $call = $self->_Client()->call(
				    "mt.setPostCategories",
				    $self->_Type(string=>$args->{'postid'}),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    $self->_Type(array=>$args->{'categories'}),
				    );

  return ($call) ? $call->result() : undef;
}

=head2 $obj->getTrackbackPings(\%args)

=over 4

=item * *

B<postid>

String.

=back

Returns an array reference of hash references who keys are :

=over 4

=item * 

I<pingTitle>

=item * 

I<pingURL>

=item * 

I<pingIP>

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=cut

sub getTrackbackPings {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };
  my $call = $self->_Client()->call(
				    "mt.getTrackbackPings",
				    $self->_Type(string=>$args->{'postid'})
				   );

  return ($call) ? $call->result() : undef;
}

=head2 $obj->supportMethods()

Returns an array reference.

=cut

sub supportedMethods {
  my $self = shift;
  my $call = $self->_Client()->call("mt.setPostCategories");
  return ($call) ? $call->result() : undef;
}

=head2 $obj->publishPost($postid)

Returns true or false.

=cut

sub publishPost {
    my $self = shift;

    my $call = $self->_Client()->call(
				      "mt.publishPost",
				      $self->_Type(int=>$_[0]),
				      $self->_Type(string=>$self->Username()),
				      $self->_Type(string=>$self->Password()),
				      );

    return ($call) ? 1 : 0;    
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO 

L<Net::Blogger::Engine::Base>

http://www.movabletype.org/mt-static/docs/mtmanual_programmatic.html#xmlrpc%20api

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
