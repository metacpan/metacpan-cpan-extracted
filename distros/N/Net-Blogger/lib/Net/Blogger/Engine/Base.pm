{

=head1 NAME

Net::Blogger::Engine::Base - base class for Blogger API engines

=head1 SYNOPSIS

 package Net::Blogger::Engine::SuperFly;

 use vars qw ( @ISA );
 @ISA = qw ( Net::Blogger::Engine::Base );
 use Net::Blogger::Engine::Base;

 sub new {
    my $pkg = shift;

    my $self = {};
    bless $self,$pkg;

    $self->SUPER::init(@_);
    return $self;
 }

=head1 DESCRIPTION

Base.pm is used a base class by implementation specific modules
for the Blogger API.

If an implementation follows the Blogger API to the letter then,
conceivably, all it's package would need to define is a constructor
and I<Proxy> method to define the
URI of it's XML-RPC server.

Base.pm inherits the functionality of Net::Blogger::Base::API and
Net::Blogger::Base::Ext and defines private methods used by each.

=cut

package Net::Blogger::Engine::Base;
use strict;

use vars qw ( $AUTOLOAD );

$Net::Blogger::Engine::Base::VERSION        = '1.0';
@Net::Blogger::Engine::Base::ISA            = qw ( Exporter Net::Blogger::API::Core Net::Blogger::API::Extended );
@Net::Blogger::Engine::Base::ISA::EXPORT    = qw ();
@Net::Blogger::Engine::Base::ISA::EXPORT_OK = qw ();

use Carp;
use Error;
use Exporter;

use SOAP::Lite;

use Net::Blogger::API::Core;
use Net::Blogger::API::Extended;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE->new(\%args)

Instantiate a new Blogger object.

Valid arguments are :

=over 4

=item *

B<appkey>

String. The magic appkey for connecting to the Blogger XMLRPC server.

=item *

B<blogid>

String. The unique ID that Blogger uses for your weblog

=item *

B<username>

String. A valid username for blogid

=item *

B<password>

String. A valid password for the username/blogid pair.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an object. Woot!

=head2 __PACKAGE__->init

Initializes the option values

=cut

sub new {
    my $pkg = shift;

    my $self = {};
    bless $self,$pkg;

    $self->init(@_) || return undef;

    return $self;
}

sub init {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    $self->AppKey($args->{'appkey'});
    $self->Username($args->{'username'});
    $self->Password($args->{'password'});
    $self->BlogId($args->{'blogid'});

    $self->{'debug'}   = $args->{'debug'};
    $self->{"_posts"}  = [];

    # Note to self: this is what comments are for.
    # It's late, I'm hungry, I don't want to have
    # to remember what I was smoking when I wrote
    # this...

    (my $caller = (caller(2))[3]) =~ /(.*)[:]{2}([^:]{1,})[:]{2}([^:]{1,})$/;

    $self->{'__parent'} = $2;
    return 1;
}

=head1 OBJECT METHODS

There are no public methods. See I<Net::Blogger::Base::API> and
I<Net::Blogger::Base::Ext>.

=cut

=head1 PRIVATE METHODS

=cut

=head2 $pkg->Proxy()

Get/set the URI of the Blogger API server.

=head2 $pkg->AppKey($key)

Get/set the magic appkey

=head2 $pkg->BlogId($id)

Get/set the blogid

=head2 $pkg->Username($username)

Get/set the username

=head2 $pkg->Password($password)

Get/set the password

=head2 $pkg->MaxPostLength()

Return the maximum number of characters a single post may contain.

=cut

=head2 $pkg->LastError($e)

Fetch the last recorded error message.

Returns a string.

=cut

sub LastError {
    my $self = shift;
    my $e    = shift;

    if ($e) {
	Error::Simple->record($e);
	return 1;
    }

    $e = Error->prior();
    chomp $e;

    return $e;
}

=head2 $pkg->Transport

Just returns XMLRPC by default

=cut

sub Transport {
  return "XMLRPC";
}

sub _Client {
    my $self = shift;

    unless (ref($self->{"_client"}) =~ /^(XMLRPC|SOAP)::Lite$/) {

      my $pkg = uc $self->Transport();

      if ($pkg =~ /^(XMLRPC|SOAP)$/) {
	$pkg = join("::",$pkg,"Lite");
      }

      else {
	die "Unknown transport : '$pkg'\n";
	$self->LastError("Unknown transport : $pkg");
	return undef;
      }

      eval "require $pkg";

      if ($@) {
	die "Failed to eval, $@\n";
      }
      my $client = $pkg->new()
	|| Error->throw(-text=>$!);

      $client->on_fault(\&_ClientFault);

      # Obey $http_proxy, if set.

      if (defined($ENV{http_proxy})) {
	  $client->proxy($self->Proxy, proxy => ['http' => $ENV{http_proxy} ]);
      } else {
	  $client->proxy($self->Proxy);
      }

      $client->uri($self->Uri());

      # Fix this.
      if ($self->{'debug'}) {
	$client->on_debug(sub { print @_; });
      }

      $self->{"_client"} = $client;
    }

    return $self->{"_client"};
}

sub _ClientFault {
    my $client = shift;
    my $res    = shift;
    Error::Simple->record(join("\n",
			       "Fatal client error.",
			       ((ref $res) ? $res->faultstring() : $client->transport->status()))
			  );
    return 0;
}

sub _Type {
  my $self = shift;
  my $name = shift;

  if ($name =~ /^(hash|array)$/) {
    return SOAP::Data->name(args=>@_);
  }

  return SOAP::Data->type($name,@_);
}

sub DESTROY {
    return 1;
}

sub AUTOLOAD {
    my $self  = shift;
    $AUTOLOAD =~ s/.*:://;

    if ($AUTOLOAD eq "Publish") {
	$self->LastError("This method has been deprecated.");
	return undef;
    }

    unless ($AUTOLOAD =~ /^(Proxy|Uri|AppKey|BlogId|Username|Password)$/) {
	$self->LastError("Unknown method '$AUTOLOAD' called. Skipping.");
	return undef;
    }

    my $property = lc "_".$AUTOLOAD;

    if (my $arg = shift) {
      $self->{ $property } = $arg;

      if ($AUTOLOAD eq "Proxy") {
	$self->{"_client"} = undef;
      }

      #

      if (exists $self->{'__meta'}) {
	$self->{'__meta'}->$property($arg);
      }

      if (exists $self->{'__mt'}) {
	$self->{'__mt'}->$property($arg);
      }

      if (exists $self->{'__slash'}) {
	$self->{'__slash'}->$property($arg);
      }

    }

    return $self->{ $property };
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::API::Core>

L<Net::Blogger::API::Extended>

L<SOAP::Lite>

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
