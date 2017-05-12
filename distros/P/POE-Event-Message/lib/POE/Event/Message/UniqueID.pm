# -*- Perl -*-
#
# File:  POE/Event/Message/UniqueID.pm
# Desc:  Generate a guaranteed unique message identifier
# Date:  Mon Oct 10 10:10:59 2005
# Stat:  Prototype, Experimental
#
package POE::Event::Message::UniqueID;
use 5.006;
use strict;
use warnings;

our $PACK    = __PACKAGE__;
our $VERSION = '0.03';
### @ISA     = qw( );

use POSIX;
use Time::HiRes;	# comment this line to use CORE::time() and rand()
			# uncomment to use gettimeofday() -- the better choice
my($host,$pid);
my($time,$ident,@prior) = ("","",());
my($secs,$msecs,$rand)  = (0,0,0);
my($errs,$mesg,$count)  = (0,"",0);

sub import
{   my($class,@args) = @_;
    $class->buildIdentityGenerator( @args );   # How will we create IDs today?
}

*generate         = \&genUniqueIdent;
*generateUniqueID = \&genUniqueIdent;

sub buildIdentityGenerator
{   my($class,$debug) = @_;

    $host = eval { (POSIX::uname)[1] };
    $pid  = $$;

    print "-" x 55 ."\n"  if $debug;

    if ( exists $INC{'Time/HiRes.pm'} ) {
	print "Will use Time::HiRes::time() to generate IDs\n"  if $debug;

	eval('sub genUniqueIdent {
	          ($secs,$msecs) = Time::HiRes::gettimeofday();
	          ( $host ."-". unpack("H*", pack("N*", $secs,$msecs,$pid)) );
	      }
	');

    } else {
	print "Will use CORE::time() and rand() to generate IDs\n"   if $debug;
	print "(note that there is a slight chance of duplicates)\n" if $debug;

	eval('sub genUniqueIdent {
		  my $limit = 1000000;    # good distribution for uniqueness?
		  ($time,$rand) = ( CORE::time(), rand($limit) );
		  ( $host ."-". unpack("H*", pack("N*", $time,$rand,$pid)) );
	      }
	');
    }
    return;
}

my $dupErrCount;
sub dupErrCount { $dupErrCount };

sub verifyGenerateUniqueID
{   my($class,$debug,$max) = @_;

    $debug ||= 0;
    $max   ||= 1000;

    if ($debug) {
	print "-" x 55 ."\n";
	print "Generating $max IDs to verify uniqueness...\n";
	print "  host = $host\n";
	print "   pid = $pid\n";
	print "  time = ". time() ."\n";
    }

    foreach (1..$max) {

	$ident = genUniqueIdent();       # This is a generated subroutine

	if ( grep(/^$ident$/, @prior) ) {
	    ($errs,$mesg)  = ($errs +1, "duplicate ID!");
	    print " ident = $ident   $mesg\n";
	} else {
	    ($mesg)  = ("unique ID!");
	    push @prior, $ident;
	    if ($count) {
		print " ident = $ident   $mesg\n"      if $debug > 1;
	    } else {
		print " ident = $ident   (example)\n"  if $debug > 1;
	    }
	}
	$count++;
    }
    $dupErrCount = $errs;

    print "-" x 55 ."\n";
    print "IDs Generated: $count   Duplicates: $errs\n";

    if ( $errs and exists $INC{'Time/HiRes.pm'} ) {
	print "OUCH: the unique ID generator needs some work!!\n";
    } elsif ( $errs ) {
	print "Oops: Try using 'Time::HiRes' for better results!\n";
    }
    print "-" x 55 ."\n";
    return;
}
#_________________________
1; # Required by require()

__END__

=head1 NAME

POE::Event::Message::UniqueID - Generic messaging header identifier

=head1 VERSION

This document describes version 0.02, released November, 2005.

=head1 SYNOPSIS

 use POE::Event::Message::UniqueID;

 $ident = POE::Event::Message::Header->generate();

 POE::Event::Message::Header->verifyGenerateUniqueID();


=head1 DESCRIPTION

This class is used to generate a guaranteed unique identifier.

B<Warning>: If the B<Time::HiRes> module is not installed on the
local machine the possibility of duplicate identifiers does exist.

=head2 Constructor

None.

=head2 Methods

=over 4

=item generate ( )

Generate a unique identifier.

=item verifyGenerateUniqueID ( )

This method can be used to verify that unique identifiers
are generated without any duplicates.

=back

=head1 DEPENDENCIES

This class depends upon the following classes:

 Time::HiRes

=head1 INHERITANCE

None currently.

=head1 SEE ALSO

See L<Time::HiRes>.

=head1 AUTHOR

Chris Cobb [no dot spam at ccobb dot net]

=head1 COPYRIGHT

Copyright (c) 2005-2010 by Chris Cobb, All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
