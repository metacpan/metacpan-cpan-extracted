# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *	                   Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# *
# *	DBMS.pm -- Perl 5 interface to DBMS sockets
# *
# *
=NAME DBMS

=head1 NAME

DBMS - Perl5 access to a dbms server.

=head1 SYNOPSIS

    use DBMS ;
    $x=tie %hash, 'DBMS', $type,$name;

    # Use the %hash array.
    $hash{ aap } = noot;
    foreach $k (keys(%hash)) {
	print "$k - $hash{ $k }\n";
	};
    # and destroy..
    undef $x;

=head1 DESCRIPTION

B<DBMS> is a module which allows Perl programs to make use of the
facilities provided by the dbms server. The dbms server is a small
server with a bit of glue to the Berkeley DB (> 1.85 < 2.x) and some code
to listen to a few sockets.

=head1 DETAILS

As the devil is in the details... this module supports three
functions which are not part of the normal tie interface; 
atomic counter increment, atomic counter decrement and atomic list retrival.

The increment and decrement functions increments or decrement a counter before it returns
a value. Thus a null or undef value can safely be taken as
an error.

=head2 EXAMPLE

    use DBMS ;
    $x=tie %hash, 'DBMS', $type,$name
	or die "Could not ty to $name: $!";

    $hash{ counter } = 0;

    $my_id = $x->inc( 'counter' )
	or die "Oi";

    $my_id = $x->dec( 'counter' )
	or die "Oi oi";

    # and these are not quite implemented yet..
    # 	
    @keys = $x->keys();
    @values = $x->values();
    @all = $x->hash();

=head1 VERSION

$Id: DBMS.pm,v 1.5 2006/06/19 10:10:24 areggiori Exp $

=head1 AVAILABILITY

Well, ah hmmm. For ParlEuNet at the beginning but now for the whole CPAN community.

=head1 BUGS

Memory management not fully checked. Some speed issues, I.e. only
about 100 TPS. No proper use of $! and $@, i.e. it will just croak,
carp or return an undef. And there is no automagic retry should you 
loose the connection.

=head1 Author

Dirk-Willem van Gulik <dirkx@webweaving.org> and Alberto Reggiori <areggiori@webweaving.org>
	
=head1 SEE ALSO

L<perl(1)>, L<DB_File(3)> L<AnyDBM_File(3)> L<perldbmfilter(3)>. 

=cut

package DBMS;

$E_NOSUCHDATABASE = 1011;

use strict;
use vars qw($VERSION @ISA $AUTOLOAD);

use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file

use Carp;
use Tie::Hash;
use AutoLoader;
@ISA = qw(Tie::Hash);

$VERSION = "1.7";

# some inlin-ed h2ph macros - need to be in-sync with dbms/include/dbms.h
eval("sub DBMS::EVENT_RECONNECT () { 0; }") unless defined(&DBMS::EVENT_RECONNECT);
eval("sub DBMS::EVENT_WAITING () { 1; }") unless defined(&DBMS::EVENT_WAITING);
eval("sub DBMS::XSMODE_DEFAULT () { 0; }") unless defined(&DBMS::XSMODE_DEFAULT);
eval("sub DBMS::XSMODE_RDONLY () { 1; }") unless defined(&DBMS::XSMODE_RDONLY);
eval("sub DBMS::XSMODE_RDWR () { 2; }") unless defined(&DBMS::XSMODE_RDWR);
eval("sub DBMS::XSMODE_CREAT () { 3; }") unless defined(&DBMS::XSMODE_CREAT);
eval("sub DBMS::XSMODE_DROP () { 4; }") unless defined(&DBMS::XSMODE_DROP);


# B-tree comparinson functions - see include/rdfstore_flat_store.h for definitions
eval("sub DBMS::BT_COMP_INT () { 7000; }") unless defined(&DBMS::BT_COMP_INT);
eval("sub DBMS::BT_COMP_DOUBLE () { 7001; }") unless defined(&DBMS::BT_COMP_DOUBLE);
eval("sub DBMS::BT_COMP_DATE () { 7002; }") unless defined(&DBMS::BT_COMP_DATE);

sub inc {
	my($class,$key)=@_;
	return $class->INC($key);
};

sub dec {
	my($class,$key)=@_;
	return $class->DEC($key);
};

sub isalive {
	my($class,$key)=@_;
	return $class->PING($key);
};

sub drop {
	my($class,$key)=@_;
	return $class->DROP($key);
};

sub AUTOLOAD {
    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    Carp::croak("Your vendor has not defined DBMS macro $constname, used");
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

1;
__END__
