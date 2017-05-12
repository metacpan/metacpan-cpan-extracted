package Net::Hesiod;

require 5;
use strict;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);

#We don't pollute namespace by default
@EXPORT = qw( );

#Some convenient tags
%EXPORT_TAGS =
(	'resolve' => [qw( hesiod_init hesiod_end hesiod_resolve)],
	'all' => [ qw(  hesiod_init hesiod_end hesiod_resolve
			hesiod_to_bind hesiod_getpwnam hesiod_getpwuid
			hesiod_getservbyname hesiod_getmailhost) ]
);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT_OK = qw( hesiod_init hesiod_end hesiod_resolve
			hesiod_to_bind hesiod_getpwnam hesiod_getpwuid
			hesiod_getservbyname hesiod_getmailhost);

$VERSION = '1.11';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    use vars qw($AUTOLOAD);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Hesiod macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Net::Hesiod $VERSION;

# Preloaded methods go here.

#OO Wrappers for the raw hesiod interface

sub new ($)
#Constructor
#Just call hesiod_init and bless context
{	my $class = shift;
	#If called as an instance method, create new object of same class
	if ( ref($class) ) { $class = ref($class); }

	my $context;
	my $res=hesiod_init($context);
	if ( $res ) { return undef; }
	bless $context, $class;
	return $context;
}

sub DESTROY ($)
#Destructor
#call hesiod_end on our context
{	my $obj = shift;
	if ( ! ref($obj) ) 
	{	croak "Net::Hesiod::DESTROY called as class method.";
	}
	hesiod_end($obj);
}

#Simple wrappers for the raw functions
sub to_bind($$$)
{	my $context = shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::to_bind called as class method.";
	}
	my $name=shift;
	my $type=shift;
	return hesiod_to_bind($context,$name,$type);
}

sub resolve($$$)
{	my $context = shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::resolve called as class method.";
	}
	my $name=shift;
	my $type=shift;
	return hesiod_resolve($context,$name,$type);
}


sub getpwnam($$)
{	my $context = shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::getpwnam called as class method.";
	}
	my $name=shift;
	return hesiod_getpwnam($context,$name);
}

sub getpwuid($$)
{	my $context = shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::getpwuid called as class method.";
	}
	my $uid=shift;
	return hesiod_getpwuid($context,$uid);
}

sub getservbyname($$$)
{	my $context = shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::getservbyname called as class method.";
	}
	my $serv=shift;
	my $proto=shift;

	return hesiod_getservbyname($context,$serv,$proto);
}

sub getmailhost($$)
{	my $context = shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::getmailhost called as class method.";
	}
	my $mh=shift;
	return hesiod_getmailhost($context,$mh);
}

sub query($$$;$)
#query is a wrapper for resolve.  IT does a hesiod_resolve for name and
#type, and depending on whether called in scalar or list context will
#return either a string of the list from resolve joined together (with $delim
#as delimiter) or a list produced by splitting each element of the list from
#resolve by the $delim character.
#$delim defaults to ", " in scalar context, and "\s*,\s*" in list context
{	my $context=shift;
	if ( ! ref($context) )
	{	croak "Net::Hesiod::query called as class method.";
	}
	my $name = shift;
	my $type = shift;
	my $delim = shift || undef;

	my @tmp = hesiod_resolve($context,$name,$type);
	my $tmp;
	if ( wantarray )
	{	#Called in list context
		if ( ! defined $delim ) { $delim = '\s*,\s*'; }

		my @res = ();
		foreach $tmp (@tmp)
		{	push @res, (split /$delim/, $tmp);
		}
		return @res;
	} else
	{	#Called in scalar context
		if ( ! defined $delim ) { $delim = ', '; }
		my $res = join "$delim", @tmp;
		return $res;
	}
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::Hesiod - Perl interface to Hesiod Library API

=head1 SYNOPSIS

=head2 Non-OO interface

  use Net::Hesiod qw( 
		 hesiod_init hesiod_end hesiod_to_bind hesiod_resolve
		 hesiod_getpwnam hesiod_getpwuid 
		 hesiod_getservbyname hesiod_getmailhost );

  $res=hesiod_init($context);

  $bindname = hesiod_to_bind($context,$name,$type);
  @results = hesiod_resolve($context,$name,$type);

  @pwent = hesiod_getpwnam($context,$username);
  @pwent = hesiod_getpwuid($context,$uid);

  @servent = hesiod_getservbyname($context,$servicename,$proto);

  @mhent = hesiod_getmailhost($context,$username);

  hesiod_end($context);

=head2 Object-orientated interface

  use Net::Hesiod;

  my $ctxt = new Net::Hesiod;

  $bindname = $ctxt->to_bind($name,$type);
  @results = $ctxt->resolve($name,$type);

  @pwent = $ctxt->getpwnam($username);
  @pwent = $ctxt->getpwuid($uid);

  @servent = $ctxt->getservbyname($servicename,$proto);
  @mhent = $ctxt->getmailhost($username);

  $results = $ctxt->query($name,$type,$delim);
  @results = $ctxt->query($name,$type,$delim);

=head1 DESCRIPTION

These routines interface to the Hesiod Library API.  Hesiod is a distributed
database, with records stored as text records in DNS,
that is used to provide system information in clusters such as 
MIT's Athena project. 
	http://web.mit.edu/is/athena/

This module provides both standard and object-orientated interfaces to the 
standard Hesiod library API.  It requires the hesiod library to already
be installed (and Hesiod configured) on the system.

Before using any of the routines, the hesiod library needs to be initialized.
This can be done in the non-OO interface by calling C<hesiod_init>.  The
scalar C<$context> should be passed to subsequent calls, and when you are
through with the Hesiod library, the resources should be explicitly freed
with the C<hesiod_end> routine.

In the OO interface, the constructor does the hesiod initialization, and
the resources will be automatcially freed by the destructor when the 
I<Hesiod> object gets destroyed.  (In actuality, the constructor merely
calls C<hesiod_init> and blesses the resulting C<$context> reference.)

C<hesiod_init> returns 0 if successful, -1 if fails (and $! set).  The
OO constructor returns a new object reference if successful, and undef
otherwise.

The C<hesiod_to_bind> routine and the C<to_bind> method convert a hesiod
query on a name and type to a DNS type query.  No actual lookup is done.

The C<hesiod_resolve> routine and the C<resolve> method perform an actual
query.  As with all DNS queries, multiple records can be returned, each of
which is returned as separate items in returned list.  Usually, only the
first item is relevant.  

The routines C<hesiod_getpwnam>, C<hesiod_getpwuid>, C<hesiod_getservbyname>,
and the related methods (C<getpwnam>, C<getpwuid>, and C<getservbyname>), are
hesiod versions of the Core Perl routines C<getpwnam>, C<getpwuid>, and
C<getservbyname>.  The arrays returned have the same structure as the Core
routines.  B<NOTE>: The service entry returned by C<hesiod_getservbyname> and
the related method has the port number in host-byte order, not network-byte
order as the standard C servent structure does.  This is consistent with the
CORE C<getservbyname> and related functions.

C<hesiod_getmailhost> and the related method C<getmailhost> return the Hesiod
postoffice structure for the named user.  The returned I<post office> array
has three elements, corresponding to the type, host, and name of the mailbox.

The method C<query> is a convenience wrapper to the C<hesiod_resolve> function.
In scalar context, it I<join>'s the list of strings returned by the resolve
routine with the C<$delim> argument (which defaults to ', '), thus returning
the entire query as a single scalar.  In list context, it I<split>'s each
element of the list of strings returned by the raw routine on C<$delim>
(which defaults to '\s*,\s*'), and returns an array of all the values.

The C language version of the API contains a number of routines to free
storage allocated by the library for the results of these queries.  The
Perl API copies these results to Perl variables, then immediately frees the
storage allocated by the Hesiod library, and these routines are not needed
in the Perl API.

=head2 EXPORT

Nothing by default.  The following routines are exportable:

=over 4

=item hesiod_init

=item hesiod_end

=item hesiod_resolve

=item hesiod_to_bind

=item hesiod_getpwnam

=item hesiod_getpwuid

=item hesiod_getservbyname

=item hesiod_getmailhost

=back

The first three can alternatively be exported with the tag I<resolve>, and
the whole list with the tag I<all>.

=head1 AUTHOR

This code is copyright (c) 2001 by
Tom Payerle 
	payerle@physics.umd.edu

All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself, or alternatively 
(at your option) under either the:

GNU GPL 
	http://www.gnu.org/copyleft/gpl.html

or The Artistic License 
	http://www.perl.com/pub/language/misc/Artistic.html

This code is provided AS IS, without any express or implied warranties.

=head1 SEE ALSO

=over 4

L<hesiod>

L<hesiod_init>, L<hesiod_end>, L<hesiod_to_bind>, L<hesiod_resolve>

L<hesiod_getpwnam>, L<hesiod_getpwuid>, L<hesiod_getservbyname>, L<hesiod_getmailhost>

MIT's Athena Project 
	http://web.mit.edu/is/athena/

=back

=cut
