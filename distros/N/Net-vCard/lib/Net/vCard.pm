package Net::vCard;

use strict;
use warnings;

our $VERSION=0.1;
our $WARN=0;

=head1 NAME

Net::vCard - Read and write vCard files (RFC 2426). vCard files hold personal information that you would typically find on a business card. Name, numbers, addresses, and even logos. This module can also serve as a base class for other vFile readers.

=head1 SYNOPSIS

  use Net::vCard;

  my $cards=Net::vCard->loadFile( "addresses.vcf" );

  foreach my $card ( @$cards ) {

    print $card->givenName,       " ",  $card->familyName, "\n";
    print $card->ADR->address,    "\n"; 
    print $card->ADR->city,       " ",  $card->ADR->region, "\n";
    print $card->ADR->postalCode, "\n";

    print $card->ADR("home")->address,    "\n"; 
    print $card->ADR("home")->city,       " ",  $card->ADR("home")->region, "\n";
    print $card->ADR("home")->postalCode, "\n";

  }

=head1 MODULE STATUS

The current state of this module is a pretty solid parser and internal data structure.

Now I will be adding get/set handlers for the various properties. As well, I'd really like
to get some pathelogical data from different vCard producers. Right now I have a pretty good
handle on Apple's Addressbook - which is the whole reason why I wrote this stuff.

For those who really want to use this module right away

  - go ahead and access the hash values directly for the time being
  - keep in mind that I will be making a get/set method interface
  - once that is established you will need to use that interface instead

=cut


use base qw(Net::vFile);
use Net::vCard::ADR;

$Net::vFile::classMap{'VCARD'}=__PACKAGE__;

=head1 ACCESSOR METHODS

=head2 NAME values

=over 4

=item $vcard->familyName( [ familyName ] )

=cut

sub familyName { 
    if (exists $_[1]) {
        $_[0]->{'N'}{'familyName'}=$_[1];
    }
    return $_[0]->{'N'}{'familyName'};
};

=item $vcard->givenName( [ givenName ] )

=cut

sub givenName { 
    if (exists $_[1]) {
        $_[0]->{'N'}{'givenName'}=$_[1];
    }
    return $_[0]->{'N'}{'givenName'};
};

=item $vcard->additionalNames( [ additionalNames ] )

=cut

sub additionalNames { 
    if (exists $_[1]) {
        $_[0]->{'N'}{'additionalNames'}=$_[1];
    }
    return $_[0]->{'N'}{'additionalNames'};
};

=item $vcard->suffixes( [ suffixes ] )

=cut

sub suffixes { 
    if (exists $_[1]) {
        $_[0]->{'N'}{'suffixes'}=$_[1];
    }
    return $_[0]->{'N'}{'suffixes'};
};

=item $vcard->prefixes( [ prefixes ] )

=cut

sub prefixes { 
    if (exists $_[1]) {
        $_[0]->{'N'}{'prefixes'}=$_[1];
    }
    return $_[0]->{'N'}{'prefixes'};
};

=back

=head2 ADDRESSES

To access address data:

 $card->ADR( type )->field;
 $card->ADR( )->city;           # Default address, city field
 $card->ADR( "home" )->address; # Home address type, address field

=over 4

=item $card->ADR( [type] )->country

=item $card->ADR( [type] )->poBox

=item $card->ADR( [type] )->city

=item $card->ADR( [type] )->region

=item $card->ADR( [type] )->address

=item $card->ADR( [type] )->postalCode

=item $card->ADR( [type] )->extendedAddress

=back


There are some decisions to be taken wrt ADR values. 

Firstly

As of now the RFC specifies
action to take in the case of unlisted type - the address gets four types - intl,
parcel, postal, and work. This implies that several types refer to the same address.

What I am doing for loading this data is storing the address in a hash entry by
the first name and listing the remainder in "_alias" hash key.

What happens when one of these addresses is updated? Do we copy all the values to
unique hash entries or do we update the common copy, requiring the developer to
explicitly declare a new address replace the common entry.

If this doesn't make sense email me and I'll try another explaination.

Secondly

What about preferred addresses? For now I am going to let the module user optionally
request their preferred address type. If it does not exist then we'll keep looking
for less preferred address types like the "pref" that was specified when loading vcard
data, and finally the 4 default types.

=cut

sub ADR  {

    my $self=shift;
    my $reqType=shift || $self->{'ADR'}{'_pref'};

    foreach my $type ( $reqType, @{$self->typeDefault->{'ADR'}} ) {
        next unless $type;
        if (exists $self->{'ADR'}{$type}) {
            return $self->{'ADR'}{$type};
        }

        if (exists $self->{'ADR'}{'_alias'}{$type}) {
            return $self->{'ADR'}{'_alias'}{$type};
        }
    }

    warn "No address found\n" if $WARN;
    my $adrPkg=ref($self) . "::ADR";
    return $adrPkg->new;

}

sub FN   { $_[0]->_singleText( "FN", $_[1] ); }
sub BDAY { $_[0]->_singleText( "BDAY", $_[1] ); }

sub varHandler {

    return {
        'FN'          => 'singleText',
        'N'           => 'N',
        'NICKNAME'    => 'multipleText',
        'PHOTO'       => 'singleBinary',
        'BDAY'        => 'singleText',
        'ADR'         => 'ADR',
        'LABEL'       => 'singleTextTyped',
        'TEL'         => 'singleTextTyped',
        'EMAIL'       => 'singleTextTyped',
        'MAILER'      => 'singleText',
        'TZ'          => 'singleText',
        'GEO'         => 'GEO',
        'TITLE'       => 'singleText',
        'ROLE'        => 'singleText',
        'LOGO'        => 'singleBinary',
        'AGENT'       => 'singleText',
        'ORG'         => 'multipleText',
        'CATEGORIES'  => 'multipleText',
        'NOTE'        => 'singleText',
        'PRODID'      => 'singleText',
        'REV'         => 'singleText',
        'SORT-STRING' => 'singleText',
        'SOUND'       => 'singleBinary',
        'UID'         => 'singleText',
        'URL'         => 'singleText',
        'VERSION'     => 'singleText',
        'CLASS'       => 'singleText',
        'KEY'         => 'singleBinary',
    };

}

sub typeDefault {

    return {
        'ADR'     => [ qw(intl postal parcel work) ],
        'LABEL'   => [ qw(intl postal parcel work) ],
        'TEL'     => [ qw(voice) ],
        'EMAIL'   => [ qw(internet) ],
    };

}

sub load_N {

	die "load_N: @_ cannot have attributes\n" if $_[2];
	
    no warnings;
	my @parts = split /(?<!\\);/, $_[3];
	map { s/\\;/;/g; } @parts;

	my @additional = split /(?<!\\),/, $parts[2];
	map { s/\\,/,/g; } @additional;

	my @prefixes = split /(?<!\\),/, $parts[3];
	map { s/\\,/,/g; } @prefixes;

	my @suffixes = split /(?<!\\),/, $parts[4];
	map { s/\\,/,/g; } @suffixes;

	$_[0]->{$_[1]} = {
		familyName      => $parts[0],
		givenName       => $parts[1],
		additionalNames => \@additional,
		suffixes        => \@suffixes,
		prefixes        => \@prefixes,
	};

}

sub load_ADR {

    my $attr=$_[2];

    my %type=();
    map { map { $type{lc $_}=1 } split /,/, $_ } @{$attr->{TYPE}};
    my $typeDefault=$_[0]->typeDefault;
    map { $type{ lc $_ }=1 } @{$typeDefault->{$_[1]}} unless scalar(keys %type);

	my @parts = split /(?<!\\);/, $_[3];
	map { s/\\;/;/g; s/\\n/\n/gs; } @parts;

    my $pref=0;
    if ($type{pref}) {
        delete $type{pref};
        $pref=1;
    }
    my @types=sort keys %type;

	# What to do about comma separated things?

    my $actual=shift @types;
    my $adrPkg = ref($_[0]) . "::ADR";

	$_[0]->{$_[1]}{$actual} = $adrPkg->new( {
		poBox           => $parts[0],
		extendedAddress => $parts[1],
		address         => $parts[2],
		city            => $parts[3],
		region          => $parts[4],
		postalCode      => $parts[5],
		country         => $parts[6],
	});

    $_[0]->{$_[1]}{_pref}=$actual if $pref;
    delete $_[0]->{$_[1]}{_alias}{$actual};
    map { $_[0]->{$_[1]}{_alias}{$_}=$actual unless exists $_[0]->{$_[1]}{$_} } @types;

}

=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "Net::vCard" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

 Net::iCal - whose loading code inspired me for mine

=head1 SEE ALSO

RFC 2426, Net::iCal

=cut

1;

