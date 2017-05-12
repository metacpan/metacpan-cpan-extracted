package Net::DNS::ToolKit::RR;

#use 5.006;
use strict;
#use diagnostics;
#use warnings;

use Net::DNS::Codes qw(:RRs);
use Net::DNS::ToolKit qw(
	get16
	get32
	put16
	put32
	getstring
	dn_comp
	dn_expand
);
use vars qw($VERSION $autoload *sub);
require Net::DNS::ToolKit::Question;

$VERSION = do { my @r = (q$Revision: 0.09 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub remoteload {
#    *sub = $autoload;
    (my $RRtype = $autoload ) =~ s/.*::(\w+):://;
    # function = $1, one of get,put,parse
    local $_;
    ($autoload,$_) = instantiate($RRtype,$1);
#    my $code = 'package '. __PACKAGE__ .'::'. $1 .'; '.'*'. $RRtype .'=\&'. $autoload;
    my $code = 'package '. __PACKAGE__ .'::'. $1 .'; '.'*'. $RRtype .
	q| = sub { unshift @_,'|. $autoload . q|'; &|. $_ .'};';
    eval "$code";

# print "AUTOLOAD=",*sub,";\n";
# print "subname=$autoload RRtype=$RRtype func=$1\n";
# print 'code=', $code, "\n";

#    no strict;
#    eval { *sub = sub { unshift @_,$autoload; &$_ } };
#    goto &{*sub};
    unshift @_,$autoload;
    goto &$_;
}

# return target function, target interpreter
sub instantiate {
    my($RRtype,$func) = @_;
    if ($RRtype eq 'DESTROY') {	# should never get here
	die __PACKAGE__.".pm: DESTROY must be defined internally in the calling package\n";
    } else {
	my $filename = __PACKAGE__.'::'.$RRtype.'.pm';
	$filename =~ s#::#/#g;
	my $save = $@;
	eval { local $SIG{__DIE__}; require $filename };
	if ($@) {
#	    die __PACKAGE__.'::RR'.$func.' not implemented'
#		if $func eq 'put';
#	    $@ = $save;
#	    $RRtype = 'NotImplemented';
	  my $generic;
	  if (	$RRtype =~ /^TYPE(\d+)$/ &&
		($generic = TypeTxt->{$1}) &&
		$generic =~ /T_(.+)/) {
		$generic = __PACKAGE__.'::'. $1;
	  } else {
	    $generic = __PACKAGE__.'::TYPE';
	  }
	  local $_ = $generic .'.pm';
	  s#::#/#g;
	  require $_;
	  my $code = 'package '. __PACKAGE__ .'::'. $RRtype .';
*get = \&'. $generic .'::get;
*put = \&'. $generic .'::put;
*parse = \&'. $generic .'::parse;';
	  eval "$code";
	}
    }
    # package from local scope
    return (__PACKAGE__.'::'.$RRtype.'::'.$func, __PACKAGE__.'::RR'.$func);
}

# return instantiated function
sub make_function {
  my $type = shift;
  (caller(1))[3] =~ /RR(\w+)$/;
  my $action = $1;
  local $_;
  if (($_ = TypeTxt->{$type}) && $_ =~ /T_(.+)/) {	# type is real?
    my $function = __PACKAGE__.'::'.$1;
    if ($function->can($action)) {	# if function is instantiated
      return $function .= '::'.$action;
    } else {				# instantiate it or NotImplemented
      return (instantiate($1,$action))[0];
    }
  } else {
#  return __PACKAGE__.'::NotImplemented::'.$action;
    my $function = __PACKAGE__.'::TYPE'. $type;
    if ($function->can($action)) {	# if function is instantiated
      return $function .= '::'.$action;
    } else {				# instantiate it or NotImplemented
      return (instantiate("TYPE$type",$action))[0];
    }
  }
}  

#########################################################
#	implements the common portion of...
#  ($newoff,$name,$type,$class,$ttl,$rdlength,$rdata,...)
#        = $get->next(\$buffer,$offset);

sub RRget {
  my($function,$self,$bp,$newoff) = @_;
  my ($off,$name) = dn_expand($bp,$newoff);
  (my $type, $off) = get16($bp,$off);
  (my $class, $off) = get16($bp,$off);
  (my $ttl, $off) = get32($bp,$off);
  my $rdlength = get16($bp,$off);	# scalar context, don't get offset
  $function = make_function($type) unless $function;
  no strict;
  ($off, my @results) = &$function($self,$bp,$off);
  return($off,$name,$type,$class,$ttl,$rdlength,@results);
}

#########################################################
#	implements the common portions of...
#  ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,
#        $name,$type,$class,$ttl,$rdata,...);

sub RRput {
  # extract common elements from input, shrink input
  # input was: $function,$self,\$buffer,$offset,\@dnptrs,$name,$type,$class,$ttl,@rdata
  my ($func,$put,$bp,$off,$dnp,$name,$type,$class,$ttl) = @_;
  if (exists $_[1]->{class}) {
    ($func,$put,$bp,$off,$dnp,$name,$ttl) = splice(@_,0,7);
    $class = $put->{class};
    $func =~ /.+::(.+)::put$/;
    $type = 'T_'.$1;
    no strict;
    $type = &$type;
  } else {
    ($func,$put,$bp,$off,$dnp,$name,$type,$class,$ttl) = splice(@_,0,9);
  }
  # input is now: @rdata
  die "'names' ending in '.' are not allowed per RFC's\n"
	if $name =~ /\.$/;
  ($off, my @dnptrs) = dn_comp($bp,$off,\$name,$dnp);
  unless (@dnptrs) {		# if not valid return
    while(shift) {};		# empty the input array
    return ();			# error
  }
  return () unless ($off = put16($bp,$off,$type));
  # the rest should work since offset has been checked
  $off = put16($bp,$off,$class);# class
  $off = put32($bp,$off,$ttl);# ttl
  no strict;
  &$func($self,$bp,$off,\@dnptrs,@_);
}

####################################################################
#	implements the common portion of...
#  ($name,$typeTXT,$classTXT,$ttl,$rdlength,$RDATA,...)
#        = $parse->XYZ($name,$type,$class,$ttl,$rdlength,$rdata,...)

sub RRparse {
  # extract common elements from input, shrink input
  # input was: $function,$self,$name,$type,$class,$ttl,$rdlength,@rdata
  my $function = shift;
  # input is now: $name,$type,$class,$ttl,$rdlength,@rdata
  my ($name,$type,$class,$ttl,$rdlength) = splice(@_,1,5);	# pass $self,@rdata to $function call
# if length is ever needed, add it here
#  $_[0]->{len} = $rdlength;
  $name .= '.';	# terminate domain name
  $function = make_function($type) unless $function;
  no strict;
  my $typetxt = TypeTxt->{$type} || "TYPE$type";
  my $classtxt = ClassTxt->{$class} || "CLASS$class";
  return($name,$typetxt,$classtxt,$ttl,$rdlength,&{$function}(@_));
}

#####################################################################
######################### sub PACKAGES ##############################
#####################################################################

# this entire sub package is obsolete as of v0.07
#{
#  package Net::DNS::ToolKit::RR::NotImplemented;
#
#  sub get {
#    my($self,$bp,$offset) = @_;
#    (my $rdlength, $offset) = &Net::DNS::ToolKit::get16($bp,$offset);
#    $offset += $rdlength;
#    return($offset,"\0");
#  }
#
## die in loader, unimplemented
##  sub put {
##    my($bp,$off,$dp) = @_;
##    return($off,@$dp);
##  }
#  
#  sub parse {
#    shift;	# $self
#    return(@_);	# garbage in, garbage out
#  }
#}

{
    package Net::DNS::ToolKit::RR::get;
    use vars qw($AUTOLOAD);

    # preload Question
    *Question = \&Net::DNS::ToolKit::Question::get;

    sub AUTOLOAD {
	$Net::DNS::ToolKit::RR::autoload = $AUTOLOAD;
	goto &Net::DNS::ToolKit::RR::remoteload;
    }
    sub next {
      unshift @_,undef;	# flag to RRget;
      goto &Net::DNS::ToolKit::RR::RRget;
    }
    sub EmptyList {()};
    sub DESTROY {};
}

{
    package Net::DNS::ToolKit::RR::put;
    use vars qw($AUTOLOAD);

    # preload Question
    *Question = \&Net::DNS::ToolKit::Question::put;

    sub AUTOLOAD {
	$Net::DNS::ToolKit::RR::autoload = $AUTOLOAD;
	goto &Net::DNS::ToolKit::RR::remoteload;
    }
    sub DESTROY {};
}

{
    package Net::DNS::ToolKit::RR::parse;
    use vars qw($AUTOLOAD);

    # preload Question
    *Question = \&Net::DNS::ToolKit::Question::parse;

    sub AUTOLOAD {
	$Net::DNS::ToolKit::RR::autoload = $AUTOLOAD;
	goto &Net::DNS::ToolKit::RR::remoteload;
    }
# this next sub has been in the distro a long time
# $parse->RR
# this was unintentional but does not hurt anything
    sub RR {
      unshift @_,undef; # flag to RRparse; 
      goto &Net::DNS::ToolKit::RR::RRparse;
    }
# this SHOULD of been here instead of the above
    sub next {
      unshift @_,undef; # flag to RRparse; 
      goto &Net::DNS::ToolKit::RR::RRparse;
    }
    sub DESTROY {};
}

=head1 NAME

Net::DNS::ToolKit::RR - Resource Record class loader

=head1 SYNOPSIS

  use Net::DNS::ToolKit::RR;

  ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
	or
  ($get,$put,$parse) = Net::DNS::ToolKit::RR->new;

	retrieve the next record (type unknown)
  ($newoff,$name,$type,$class,$ttl,$rdlength,$rdata,...)
	= $get->next(\$buffer,$offset);

	parse the current record (type in input fields)
  ($name,$typeTXT,$classTXT,$ttlTXT,$rdlength,$RDATA,...)
	= $parse->RR($name,$type,$class,$ttl,$rdlength,
			$rdata,...);

  ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,
	$name,$type,$class,$ttl,$rdata,...);

  The 'get' and 'parse' operations can also be done
  by specific record type...
  ...but why would you use them instead of 'next' & 'RR'?

  ($newoff,$name,$type,$class,$ttl,$rdlength,$rdata,...)
	= $get->XYZ(\$buffer,$offset);

  ($name,$typeTXT,$classTXT,$ttlTXT,$rdlength,$RDATA,...)
	= $parse->XYZ($name,$type,$class,$ttl,$rdlength,
			$rdata,...);

	or you can use the individual methods 
	directly without calling "new"

  @output=Net::DNS::ToolKit::RR::get->next(@input);
  @output=Net::DNS::ToolKit::RR::get->XYZ(@input);
  @output=Net::DNS::ToolKit::RR::put->XYZ(@input);
  @output=Net::DNS::ToolKit::RR::parse->RR(@input);
  @output=Net::DNS::ToolKit::RR::parse->XYZ(@input);

The Question section is a special case:

  ($newoff,$name,type,class) = 
	$get->Question(\$buffer,$offset);
  ($newoff,@dnptrs) = 
	$put->Question(\$buffer,$offset,
	$name,$type,$class,\@dnptrs);
  ($name,$typeTXT,$classTXT) =
	$parse->Question($name,$type,$class);

=head1 ALTERNATE PUT METHOD SYNOPSIS

An alternate method for B<put> is available for class specific
submissions. This eliminates the need to specify TYPE and CLASS when doing a
put. The generic form of a put command using this method is shown below but
NOT detailed in the method descriptions.

  ($get,$put,$parse) = new Net::DNS::ToolKit::RR(class_type);
	or
  ($get,$put,$parse) = Net::DNS::ToolKit::RR->new(C_IN);

The generic form of a C<put> operation then becomes:

  ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,
	$name,$ttl,$rdate,...)

The only class currently supported at this time is C_IN.

NOTE: the use of this alternate method changes the number of required
arguments to ALL put RR operations. These changes are NOT noted below in the
method descriptions.

=head1 DESCRIPTION

B<Net::DNS::ToolKit::RR> is the class loader for Resource Record classes. 
It provides an extensible wrapper for existing
classes as well as the framework to easily add new RR classes. See:
B<Net::DNS::ToolKit::RR::Template>

  From RFC 1035

  3.2.1. Format

  All RRs have the same top level format shown below:

                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      NAME                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     CLASS                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TTL                      |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                   RDLENGTH                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    |                     RDATA                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

  NAME	an owner name, i.e., the name of the node to which this
	resource record pertains.

  TYPE	two octets containing one of the RR TYPE codes.

  CLASS	two octets containing one of the RR CLASS codes.

  TTL	a 32 bit signed integer that specifies the time interval
	that the resource record may be cached before the source
	of the information should again be consulted.  Zero
	values are interpreted to mean that the RR can only be
	used for the transaction in progress, and should not be
	cached.  For example, SOA records are always distributed
	with a zero TTL to prohibit caching.  Zero values can
	also be used for extremely volatile data.

  RDLENGTH an unsigned 16 bit integer that specifies the length
	in octets of the RDATA field.

  RDATA	a variable length string of octets that describes the
	resource.  The format of this information varies
	according to the TYPE and CLASS of the resource record.

=over 4

=item * ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

Retrieves the method pointers to B<get>, B<put>, and B<parse> for Queston
section and Resource Records of a particular type.

=cut

sub new {
  my ($proto,$class) = @_;
  my $package = ref($proto) || $proto;
  my $get  = {};
  bless ($get, "${package}::get");
  my $put = ($class && ClassTxt->{$class})
	? { class => $class, } : {};
  bless ($put, "${package}::put");
  my $parse = {};
  bless ($parse, "${package}::parse");
  return ($get,$put,$parse);
}

=item * ($newoff,@common,$rdata,...) =
	$get->next(\$buffer,$offset);

Get the next Resource Record.

  input:	pointer to buffer,
		offset into buffer

  returns:	offset to next RR or section,
		(items common to all RR's)
   i.e.	$name,$type,$class,$ttl,$rdlength,
		$rdata,.... for this RR
	    or	undef if the RR is unsupported.

HERE IS THE OPPORTUNITY FOR YOU TO ADD TO THIS PACKAGE.
If your RR of interest is not supported, see:

  Net::DNS::ToolKit::RR::Template in:
  .../Net/DNS/ToolKit/Template/Template.pm

Build the support for your Resource Record and submit it to CPAN as an
extension to this package.

UN-IMPLEMENTED methods: $get->[unimplemented] returns a correct offset to
the following RR, correct @common data and a single $rdata element
containing a null ... "\0" to be precise. This works as either a numeric 0
(zero) or an end of string.

=cut

=item * ($newoff,@dnptrs)=$put->XYZ(\$buffer,$offset,\@dnptrs,
        $name,$type,$class,$ttl,$rdata,...);


Append a resource record of type XYZ to the current buffer. This is the
generic form of a B<put>.

  input:	pointer to buffer,
		offset,	[should be end of buffer]
		pointer to compressed name array,
		(items common to all RR's)
   i.e.	$name,$type,$class,$ttl,
		$rdata,.... for this RR
		in binary form if appropriate

  returns:	offset to end of RR,
		new pointer array,
	   or	empty list if the RR type is
		unsupported

  See: note above about writing new RR's

UN-IMPLEMENTED methods: $put->[unimplemented] fails miserably with a DIE
statement identifying the offending method.

=cut

=item * (@COMMON,$RDATA) = $parse->XYZ(@common,$rdata,...);

Convert non-printable and numeric data common to all records and the RR
specific B<rdata> into ascii text. In many cases this is a null
operation. i.e. for a TXT record. However, for a RR of type B<A>, the
operation would be as follows:

	EXAMPLE
Common:

  name       is already text.
  type       numeric to text
  class      numeric to text
  ttl        numeric to text
  rdlength   is a number
  rdata      RR specific conversion

Resource Record B<A> returns $rdata containing a packed IPv4 network
address. The parse operation would be:

input:

  name       foo.bar.com
  type       1
  class      1
  ttl        123
  rdlength   4
  rdata      a packed IPv4 address

output:

  name       foo.bar.com
  type       T_A
  class      C_IN
  ttl        123 # 2m 3s
  rdlength   4
  rdata      192.168.20.40

The rdata conversion is implemented internally as:

  $dotquad = inet_ntoa($networkaddress);

  where $dotquad is a printable IP address like
	192.168.20.55

UN-IMPLEMENTED methods: $parse->[unimplemented] returns correct @common
elements insofar as the type and class are present in Net::DNS::Codes.
Other elements are passed through unchanged. i.e. garbage-in, garbage-out.

=item * ($newoff,$name,type,class) =
	$get->Question(\$buffer,$offset);

  Get the Question.

  input:	pointer to buffer,
		offset
  returns:	domain name,
		question type,
		question class

=item * ($newoff,@dnptrs) =
	$put->Question(\$buffer,$offset,
	$name,$type,$class,\@dnptrs);

Append a question to the $buffer. Returns a new pointer array for compressed
names and the offset to the next RR. 

NOTE: it is up to the user to update the question count. See: L<put_qdcount>

Since the B<question> usually is the first record to be appended to the
buffer, @dnptrs may be ommitted. See the details at L<dn_comp>.

Usage: ($newoff,@dnptrs)=$put->Question(\$buffer,$offset,
	$name,$type,$class);

  input:	pointer to buffer,
		offset into buffer,
		domain name,
		question type,
		question class,
		pointer to array of
		  previously compressed names,
  returns:	offset to next record,
		updated array of offsets to
		  previous compressed names

=item * ($name,$typeTXT,$classTXT) =
	$parse->Question($name,$type,$class);

Convert non-printable and numeric data
into ascii text.

  input:	domain name,
		question type (numeric)
		question class (numeric)
  returns:	domain name,
		type TEXT,
		class TEXT

=back

=cut

1;
__END__

=head1 DEPENDENCIES

	Net::DNS::ToolKit

=head1 EXPORT

	none

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT

    Copyright 2003 - 2011, Michael Robinton <michael@bizsystems.com>
   
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either    
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.                        
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA                                     

or visit their web page on the internet at:                      

        http://www.gnu.org/copyleft/gpl.html.

=head1 See also:

Net::DNS::Codes(3), Net::DNS::ToolKit(3), Net::DNS::ToolKit::RR::Template(3)

=cut

1;
