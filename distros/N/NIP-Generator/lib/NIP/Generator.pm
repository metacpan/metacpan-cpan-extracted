package NIP::Generator;

#-----------------------------------------------------------------------
use vars qw( $VERSION );
$VERSION = 1.1;
#-----------------------------------------------------------------------
use warnings;
use strict;
use base		qw( Exporter::Tiny	);
#=======================================================================
our @EXPORT_OK = qw( nip );
#=======================================================================
sub new {
	return bless { }, $_[ 0 ];
}
#=======================================================================
sub nip {
    my @vec = qw( 6 5 7 2 3 4 5 6 7 );

    while( 1 ){
        my @val = map { int( rand 10 ) } @vec;
        my $sum = 0;
		$sum += $_ for map { $vec[ $_ ] * $val[ $_ ] } 0 .. $#vec;
        $sum %= 11;
        return join( q[], @val, $sum ) if $sum != 10;
    }
}
#=======================================================================
1;

__END__

=head1 NAME

NIP::Generator - generator of polish fiscal identifiers.

=head1 SYNOPSIS

    use NIP::Generator;
    
    # Main object
    my $gen = NIP::Generator->new;
	
    # Run...
    my $nip = $gen->nip;
    
    #-------------------------------------------------------------------
    
    use NIP::Generator	qw( nip ) ;
    
    # Run...
    my $nip = nip();

=head1 DESCRIPTION

This module provides implementation of polish fiscal identifiers generator.

=head1 METHODS

=over 4

=item B<new>(  )

Constructor. No options there.

=item B<pesel>(  )

Get random NIP number.

=back

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible. A small script which yields the problem will probably be of help. 

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 SEE ALSO

L<Business::PL::NIP>

=head1 COPYRIGHT

Copyright (c) Strzelecki Lukasz. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
