package Net::TCLink;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
	PARAM_MAX_LEN
	TCLinkHandle
);
$VERSION = '3.4';

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Net::TCLink macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Net::TCLink $VERSION;

sub send
{
   my $params;

   if ($#_ == 0)
   {
      $params = $_[0];
   }
   else
   {
      %$params = @_;
   }

   my $handle = TCLinkCreate();
   foreach (keys %$params)
   {
      TCLinkPushParam($handle,$_,$params->{$_});
   }

   TCLinkSend($handle);

   my %response;
   my $buf = " " x 2048;
   $buf = TCLinkGetEntireResponse($handle,$buf);
   my @parts = split/\n/,$buf;
   foreach (@parts)
   {
         my ($name,$val) = split/=/,$_;
         $response{$name} = $val;
   }

   TCLinkDestroy($handle);

   return %response;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::TCLink - Perl interface to the TrustCommerce payment gateway

=head1 SYNOPSIS

  use Net::TCLink;
  %results = Net::TCLink::send(%params);

=head1 DESCRIPTION

Net::TCLink is a module that allows for fast, secure, reliable credit 
card and check transactions via the TrustCommerce IP gateway.  The 
module consists of a single functions call that accepts a hash that 
describes the requested transaction and returns a map that describes the 
result.  What values can be passed and returned are beyond the scope of 
this document and can be found in the web developers guide.  This guide 
is included the Net::TCLink distribution as TCDevGuide.{txt,html} or can 
be found at https://vault.trustcommerce.com/.

=head2 EXPORT

None by default.

=head1 AUTHOR

Orion Henry, orion@trustcommerce.com

=head1 SEE ALSO

perl(1).

=cut
