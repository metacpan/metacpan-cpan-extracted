package PESEL::Generator;

#-----------------------------------------------------------------------
use vars qw( $VERSION );
$VERSION = 1.4;
#-----------------------------------------------------------------------
use warnings;
use strict;
use base "Exporter::Tiny";
#=======================================================================
our @EXPORT_OK = qw( pesel );
#=======================================================================
sub new {
	return bless { }, $_[ 0 ];
}
#=======================================================================
sub pesel {
	while( 1 ){
		my $psl = 	sprintf( '%02d', 1 + rand 99 		) .
					sprintf( '%02d', 1 + rand 12 		) .
					sprintf( '%02d', 1 + rand 27 		) .
					sprintf( '%03d', 1 + rand 999		) .
					sprintf( '%d'  , rand > 0.5 ? 1 : 0 ) ;
					
		my @dig = split( //, $psl );
		my $chk = $dig[ 0 ] * 1 + $dig[ 1 ] * 3 + $dig[ 2 ] * 7 + $dig[ 3 ] * 9 + $dig[ 4 ] * 1 + $dig[ 5 ] * 3 + $dig[ 6 ] * 7 + $dig[ 7 ] * 9 + $dig[ 8 ] * 1 + $dig[ 9 ] * 3;
		my $lst = substr( $chk, -1, 1 );
		
		return $psl . ( 10 - $lst ) if $lst;
		#return $psl . ( ( 10 - $lst ) % 10 );
	}
}
#=======================================================================
1;

__END__

=head1 NAME

PESEL::Generator - generator of polish identifiers.

=head1 SYNOPSIS

    use PESEL::Generator;
    
    # Main object
    my $gen = PESEL::Generator->new;
	
    # Run...
    my $psl = $gen->pesel;
    
    #-------------------------------------------------------------------
    
    use PESEL::Generator	qw( pesel ) ;
    
    # Run...
    my $psl = pesel();

=head1 DESCRIPTION

This module provides implementation of polish identifiers generator.

=head1 METHODS

=over 4

=item B<new>(  )

Constructor. No options there.

=item B<pesel>(  )

Get random PESEL number.

=back

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible. A small script which yields the problem will probably be of help. 

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 SEE ALSO

L<Identifier::PL::PESEL>

=head1 COPYRIGHT

Copyright (c) Strzelecki Lukasz. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
