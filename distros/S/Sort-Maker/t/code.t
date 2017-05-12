#!/usr/local/bin/perl -sw

use strict ;

use lib 't' ;
use lib '..' ;
require 'common.pm' ;

use vars '$bench' ;

#my @sort_styles = qw( plain ) ;
my @sort_styles = qw( plain orcish ST GRT ) ;

#my @string_keys = map rand_alpha( 4, 8 ), 1 .. 5 ;
my @string_keys = map rand_alpha( 4, 8 ), 1 .. 100 ;

#print "STR @string_keys NUM @number_keys\n" ;

my $sort_tests = [
	{
		skip	=> 0,
		name	=> 'regex code',
		gen	=> sub { rand_choice( @string_keys ) },
		gold	=> sub { ($a =~ /(\w+)/)[0] cmp ($b =~ /(\w+)/)[0] },
		args	=> {
			string	=> [ qw( string /(\w+)/ ) ],
			qr	=> [ string => qr/(\w+)/ ],
			code	=> [ string => sub { /(\w+)/ } ],
		}
	},
	{
		skip	=> 0,
		name	=> 'array code',
		data	=> [ map {
				[ rand_token( 8, 20 ) ]
			} 1 .. 100
		],
		gold	=> sub { $a->[0] cmp $b->[0] },
		args	=> {
			string	=> [ qw( string $_->[0] ) ],
			code	=> [ string => sub { $_->[0] } ],
		}
	},
	{
		skip	=> 0,
		name	=> 'hash code',
		data	=> [ map {
				{ a => rand_token( 8, 20 ) }
			} 1 .. 100
		],
		gold	=> sub { $a->{a} cmp $b->{a} },
		args	=> {
			string	=> [ qw( string $_->{a} ) ],
			code	=> [ string => sub { $_->{a} } ],
		}
	},
] ;

common_driver( $sort_tests, \@sort_styles ) ;

exit ;
