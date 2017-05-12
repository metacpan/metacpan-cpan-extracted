package Parse::PhoneNumber;
use strict;
use warnings;

use Carp;

use vars qw[$VERSION $EXT $MINLEN $MIN_US_LENGTH @CCODES];

$VERSION = qw(1.9);
$EXT     = qr/\s*(?:(?:ext|ex|xt|x)[\s.:]*(\d+))/i;

$MINLEN        = 7;
$MIN_US_LENGTH = 10;

@CCODES  = qw[
	1	7	20	27	30	31	32	33	34
	36	39	40	41	43	44	45	46	47
	48	49	51	52	53	54	55	56	57
	58	60	61	62	63	64	65	66	81
	82	84	86	90	91	92	93	94	95
	98	212	213	216	218	220	221	222	223
	224	225	226	227	228	229	230	231	232
	233	234	235	236	237	238	239	240	241
	242	243	244	245	246	247	248	249	250
	251	252	253	254	255	256	257	258	260
	261	262	263	264	265	266	267	268	269
	290	291	297	298	299	350	351	352	353
	354	355	356	357	358	359	370	371	372
	373	374	375	376	377	378	380	381	385
	386	387	388	389	420	421	423	500	501
	502	503	504	505	506	507	508	509	590
	591	592	593	594	595	596	597	598	599
	670	672	673	674	675	676	677	678	679
	680	681	682	683	684	685	686	687	688
	689	690	691	692	800	808	850	852	853
	655	856	870	871	872	873	874	878	880
	881	882	886	960	961	962	963	964	965
	966	967	968	970	971	972	973	974	975
	976	977	979	991	992	993	994	995	996
	998
];

=head1 NAME

Parse::PhoneNumber - Parse Phone Numbers

=head1 SYNOPSIS

 use Parse::PhoneNumber;
 my $number = Parse::PhoneNumber->parse( number => $phone );
 
 print $number->human;

=head1 ABSTRACT

Parse phone numbers.  Phone number have a defined syntax (to a point),
so they can be parsed (to a point).

=head1 DESCRIPTION

=head2 Methods

=head3 new

Create a new Parse::PhoneNumber object.  Useful if a lot of numbers
have to be parsed.

=cut

sub new {
	return bless {}, shift;
}

=head3 parse

Accepts a list of arguments.  C<number> is the phone number.  This method
will return C<undef> and set C<errstr> on failure.  On success, a
C<Parse::PhoneNumber::Number> object is returned. C<assume_us> will have
the country code default to C<1> if none is given.  This is due to the fact
that most people in the US are clueless about such things.

=cut

sub parse {
	my ($class, %data) = @_;
	croak "No phone number" unless $data{number};

	local $_  = $data{number};
	s/^\s+//;s/\s+$//;

	my %number = (
		orig    => $data{number},
		cc      => undef,
		num     => undef,
		ext     => undef,
		opensrs => undef,
		human   => undef,
	);
	
	

	if ( m/$EXT$/ ) {
		if ( length $1 > 4 ) {
			$class->errstr( "Extension '$1' longer than four digits" );
			return undef;
		} else {
			$number{ext} = $1;
			s/$EXT$//;
		}
	}
	
	s/\D//g;
	s/^0+//;

	if ($data{'assume_us'}) {
		if (length $_ < $MIN_US_LENGTH) {
			$class->errstr("Invalid US number: $data{number}" );
			return;
		} else {
			$number{'cc'}  = 1;
			s/^1//; 
			$number{'num'} = $_;
		}
	} else {
		
		foreach my $len ( 1 .. 3 ) {
			last if $number{cc};
			
			my $cc = substr $_, 0, $len;
			
			if ( grep { $_ eq $cc } @CCODES ) {
				$number{cc} = $cc;
				s/^$cc//;
			}
		}
	
		if ( $number{cc} && length "$number{cc}$_" >= $MINLEN ) {
			$number{num}  = "$_";			
		} else {
			$class->errstr("Invalid international number: $data{number}" );
			return undef;
		}
	}
	
	$number{opensrs}  = sprintf "+%d.%s", @number{qw[cc num]};
	$number{opensrs} .= sprintf "x%d", $number{ext} if $number{ext};
			
	$number{human}  = sprintf "+%d %s", @number{qw[cc num]};
	$number{human} .= sprintf " x%d", $number{ext} if $number{ext};
	
	return Parse::PhoneNumber::Number->new( %number );
}

=head3 errstr

Returns the last error reported, or undef if no errors have occured yet.

=cut

{
	my $errstr = undef;
	sub errstr { $errstr = $_[1] if $_[1]; $errstr }
	sub clear_errstr { $errstr = undef; }
}

package Parse::PhoneNumber::Number;
use strict;
use warnings;

=head2 Parse::PhoneNumber::Number Objects

The objects returned on a successful parse.

=cut

sub new {
	my ($class, %data) = @_;
	return bless \%data, $class;
}

=head3 orig

The original string passed to C<parse>.

=head3 cc

The Country Code

=head3 num

The phone number, including the trunk pointer, area code, and
subscriber number.

=head3 ext

An extension, if one is present.

=head3 opensrs

The format an OpenSRS Registrar must make a phone number for some
TLDs.

=head3 human

Human readable format.

=cut

sub orig    { $_[0]->{orig}    }
sub cc      { $_[0]->{cc}      }
sub num     { $_[0]->{num}     }
sub ext     { $_[0]->{ext}     }
sub opensrs { $_[0]->{opensrs} }
sub human   { $_[0]->{human}   }

1;

__END__

=head1 BUGS

Currently only accept phone numbers in International format.  If a
number isn't given in international format, a false positive could
occur.

Please report bugs to the CPAN RT instance at
L<https://rt.cpan.org/Dist/Display.html?Queue=Parse-PhoneNumber>

=head1 SEE ALSO

L<Number::Phone>

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

Maintained by Tim Wilde <F<cpan@krellis.org>>

=head1 COPYRIGHT

Copyright (c) 2003 Casey West <casey@geeknest.com>.

Portions Copyright (c) 2005 Dynamic Network Services, Inc.

Portions Copyright (c) 2011 Tim Wilde

Portions Copyright (c) 2012 Google, Inc.

All rights reserved.  

This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.
