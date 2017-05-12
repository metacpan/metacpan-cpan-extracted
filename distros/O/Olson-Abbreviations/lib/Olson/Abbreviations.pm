package Olson::Abbreviations;
use strict;
use warnings;

use Moose;

use MooseX::ClassAttribute;
use namespace::autoclean;

our $VERSION = '0.04';

class_has 'ZONEMAP' => (
	isa  => 'HashRef[Maybe[Str]]'
	, is => 'rw'
	, traits  => ['Hash']
	, handles => {
		'_exists' => 'exists'
		, '_get' => 'get'
		, '_defined' => 'defined'
	}
	, default => sub {
		# Table for mapping abbreviated timezone names to tz_abbreviations
		return {
				 'A' => '+0100',       'ACDT' => '+1030',       'ACST' => '+0930',
			 'ADT' => undef,         'AEDT' => '+1100',        'AES' => '+1000',
			'AEST' => '+1000',        'AFT' => '+0430',       'AHDT' => '-0900',
			'AHST' => '-1000',       'AKDT' => '-0800',       'AKST' => '-0900',
			'AMST' => '+0400',        'AMT' => '+0400',      'ANAST' => '+1300',
			'ANAT' => '+1200',        'ART' => '-0300',        'AST' => undef,      
				'AT' => '-0100',       'AWST' => '+0800',      'AZOST' => '+0000',
			'AZOT' => '-0100',       'AZST' => '+0500',        'AZT' => '+0400',
				 'B' => '+0200',       'BADT' => '+0400',        'BAT' => '+0600',
			'BDST' => '+0200',        'BDT' => '+0600',        'BET' => '-1100',
			 'BNT' => '+0800',       'BORT' => '+0800',        'BOT' => '-0400',
			 'BRA' => '-0300',        'BST' => undef,           'BT' => undef,      
			 'BTT' => '+0600',          'C' => '+0300',       'CAST' => '+0930',
			 'CAT' => undef,          'CCT' => undef,          'CDT' => undef,      
			'CEST' => '+0200',        'CET' => '+0100',     'CETDST' => '+0200',
		 'CHADT' => '+1345',      'CHAST' => '+1245',        'CKT' => '-1000',
			'CLST' => '-0300',        'CLT' => '-0400',        'COT' => '-0500',
			 'CST' => undef,         'CSuT' => '+1030',        'CUT' => '+0000',
			 'CVT' => '-0100',        'CXT' => '+0700',       'ChST' => '+1000',
				 'D' => '+0400',       'DAVT' => '+0700',       'DDUT' => '+1000',
			 'DNT' => '+0100',        'DST' => '+0200',          'E' => '+0500',
		 'EASST' => '-0500',       'EAST' => undef,          'EAT' => '+0300',
			 'ECT' => undef,          'EDT' => undef,         'EEST' => '+0300',
			 'EET' => '+0200',     'EETDST' => '+0300',       'EGST' => '+0000',
			 'EGT' => '-0100',        'EMT' => '+0100',        'EST' => undef,      
			'ESuT' => '+1100',          'F' => '+0600',        'FDT' => undef,      
			'FJST' => '+1300',        'FJT' => '+1200',       'FKST' => '-0300',
			 'FKT' => '-0400',        'FST' => undef,          'FWT' => '+0100',
				 'G' => '+0700',       'GALT' => '-0600',       'GAMT' => '-0900',
			'GEST' => '+0500',        'GET' => '+0400',        'GFT' => '-0300',
			'GILT' => '+1200',        'GMT' => '+0000',        'GST' => undef,      
				'GT' => '+0000',        'GYT' => '-0400',         'GZ' => '+0000',
				 'H' => '+0800',        'HAA' => '-0300',        'HAC' => '-0500',
			 'HAE' => '-0400',        'HAP' => '-0700',        'HAR' => '-0600',
			 'HAT' => '-0230',        'HAY' => '-0800',        'HDT' => '-0930',
			 'HFE' => '+0200',        'HFH' => '+0100',         'HG' => '+0000',
			 'HKT' => '+0800',         'HL' => 'local',        'HNA' => '-0400',
			 'HNC' => '-0600',        'HNE' => '-0500',        'HNP' => '-0800',
			 'HNR' => '-0700',        'HNT' => '-0330',        'HNY' => '-0900',
			 'HOE' => '+0100',        'HST' => '-1000',          'I' => '+0900',
			 'ICT' => '+0700',       'IDLE' => '+1200',       'IDLW' => '-1200',
			 'IDT' => undef,          'IOT' => '+0500',       'IRDT' => '+0430',
		 'IRKST' => '+0900',       'IRKT' => '+0800',       'IRST' => '+0430',
			 'IRT' => '+0330',        'IST' => undef,           'IT' => '+0330',
			 'ITA' => '+0100',       'JAVT' => '+0700',       'JAYT' => '+0900',
			 'JST' => '+0900',         'JT' => '+0700',          'K' => '+1000',
			 'KDT' => '+1000',       'KGST' => '+0600',        'KGT' => '+0500',
			'KOST' => '+1200',      'KRAST' => '+0800',       'KRAT' => '+0700',
			 'KST' => '+0900',          'L' => '+1100',       'LHDT' => '+1100',
			'LHST' => '+1030',       'LIGT' => '+1000',       'LINT' => '+1400',
			 'LKT' => '+0600',        'LST' => 'local',         'LT' => 'local',
				 'M' => '+1200',      'MAGST' => '+1200',       'MAGT' => '+1100',
			 'MAL' => '+0800',       'MART' => '-0930',        'MAT' => '+0300',
			'MAWT' => '+0600',        'MDT' => '-0600',        'MED' => '+0200',
		 'MEDST' => '+0200',       'MEST' => '+0200',       'MESZ' => '+0200',
			 'MET' => undef,         'MEWT' => '+0100',        'MEX' => '-0600',
			 'MEZ' => '+0100',        'MHT' => '+1200',        'MMT' => '+0630',
			 'MPT' => '+1000',        'MSD' => '+0400',        'MSK' => '+0300',
			'MSKS' => '+0400',        'MST' => '-0700',         'MT' => '+0830',
			 'MUT' => '+0400',        'MVT' => '+0500',        'MYT' => '+0800',
				 'N' => '-0100',        'NCT' => '+1100',        'NDT' => '-0230',
			 'NFT' => undef,          'NOR' => '+0100',      'NOVST' => '+0700',
			'NOVT' => '+0600',        'NPT' => '+0545',        'NRT' => '+1200',
			 'NST' => undef,         'NSUT' => '+0630',         'NT' => '-1100',
			 'NUT' => '-1100',       'NZDT' => '+1300',       'NZST' => '+1200',
			 'NZT' => '+1200',          'O' => '-0200',       'OESZ' => '+0300',
			 'OEZ' => '+0200',      'OMSST' => '+0700',       'OMST' => '+0600',
				'OZ' => 'local',          'P' => '-0300',        'PDT' => '-0700',
			 'PET' => '-0500',      'PETST' => '+1300',       'PETT' => '+1200',
			 'PGT' => '+1000',       'PHOT' => '+1300',        'PHT' => '+0800',
			 'PKT' => '+0500',       'PMDT' => '-0200',        'PMT' => '-0300',
			 'PNT' => '-0830',       'PONT' => '+1100',        'PST' => '-0800',
			 'PWT' => '+0900',       'PYST' => '-0300',        'PYT' => '-0400',
				 'Q' => '-0400',          'R' => '-0500',        'R1T' => '+0200',
			 'R2T' => '+0300',        'RET' => '+0400',        'ROK' => '+0900',
				 'S' => '-0600',       'SADT' => '+1030',       'SAST' => undef,      
			 'SBT' => '+1100',        'SCT' => '+0400',        'SET' => '+0100',
			 'SGT' => '+0800',        'SRT' => '-0300',        'SST' => undef,      
			 'SWT' => '+0100',          'T' => '-0700',        'TFT' => '+0500',
			 'THA' => '+0700',       'THAT' => '-1000',        'TJT' => '+0500',
			 'TKT' => '-1000',        'TMT' => '+0500',        'TOT' => '+1300',
			'TRUT' => '+1000',        'TST' => '+0300',        'TUC' => '+0000',
			 'TVT' => '+1200',          'U' => '-0800',      'ULAST' => '+0900',
			'ULAT' => '+0800',       'USZ1' => '+0200',      'USZ1S' => '+0300',
			'USZ3' => '+0400',      'USZ3S' => '+0500',       'USZ4' => '+0500',
		 'USZ4S' => '+0600',       'USZ5' => '+0600',      'USZ5S' => '+0700',
			'USZ6' => '+0700',      'USZ6S' => '+0800',       'USZ7' => '+0800',
		 'USZ7S' => '+0900',       'USZ8' => '+0900',      'USZ8S' => '+1000',
			'USZ9' => '+1000',      'USZ9S' => '+1100',        'UTZ' => '-0300',
			 'UYT' => '-0300',       'UZ10' => '+1100',      'UZ10S' => '+1200',
			'UZ11' => '+1200',      'UZ11S' => '+1300',       'UZ12' => '+1200',
		 'UZ12S' => '+1300',        'UZT' => '+0500',          'V' => '-0900',
			 'VET' => '-0400',      'VLAST' => '+1100',       'VLAT' => '+1000',
			 'VTZ' => '-0200',        'VUT' => '+1100',          'W' => '-1000',
			'WAKT' => '+1200',       'WAST' => undef,          'WAT' => '+0100',
			'WEST' => '+0100',       'WESZ' => '+0100',        'WET' => '+0000',
		'WETDST' => '+0100',        'WEZ' => '+0000',        'WFT' => '+1200',
			'WGST' => '-0200',        'WGT' => '-0300',        'WIB' => '+0700',
			 'WIT' => '+0900',       'WITA' => '+0800',        'WST' => undef,      
			 'WTZ' => '-0100',        'WUT' => '+0100',          'X' => '-1100',
				 'Y' => '-1200',      'YAKST' => '+1000',       'YAKT' => '+0900',
			'YAPT' => '+1000',        'YDT' => '-0800',      'YEKST' => '+0600',
			'YEKT' => '+0500',        'YST' => '-0900',          'Z' => '+0000',
		}
	}
);

has 'tz_abbreviation' => ( isa => 'Str', is => 'rw', required => 1 );

sub is_known {
	my $self = shift;
	$self->_exists( $self->tz_abbreviation );
}

sub is_unambigious {
	my $self = shift;
	$self->_defined( $self->tz_abbreviation );
}

sub get_offset {
	my $self = shift;

	Carp::croak 'Unknown abreviation please submit '
		. $self->tz_abbreviation
		. ' to : http://rt.cpan.org/NoAuth/Bugs.html?Dist=Olson-Abbreviations'
		unless $self->is_known
	;

	Carp::croak "Globally ambigious abbreviation detected"
		unless $self->is_unambigious;
	;

	$self->_get( $self->tz_abbreviation );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Olson::Abbreviations -globally unique timezones abbreviation handling

=head1 DESCRIPTION

This module should help you with converting commonly used and often ambigious olson
abbreviations into TZ offset notation.

=head2 NOT COMPLETE

This module is released as 0.01 because it is useful. It is not complete. In order to
be complete in the author's eyes this module must accept a locale and disambiguate based
on that.

EST is not ambigious if your standing in the US or in Austrailia. This module should
handle this properly in the future.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Olson::Abbreviations;

    my $oa = Olson::Abbreviations->new({ tz_abbreviation => 'EST' });
		$oa->is_unambigious; # returns 0
		$oa->is_known;       # returns 1
		$oa->get_offset      # dies
    ...

=head1 METHODS

=over 12

=item get_offset

Returns the offset to UTC

=item is_unambigious

Returns 0|1 based on if the abbreviation is globally unambigious to the whole planet

=item is_known

Returns 0|1 based on if the abbreviation is known despite if it is ambigious or not

=back

=head1 AUTHOR

Evan Carroll, C<< <me+cpan at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-olson-abbreviations at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Olson-Abbreviations>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Olson::Abbreviations


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Olson-Abbreviations>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Olson-Abbreviations>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Olson-Abbreviations>

=item * Search CPAN

L<http://search.cpan.org/dist/Olson-Abbreviations/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Evan Carroll, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Olson::Abbreviations
