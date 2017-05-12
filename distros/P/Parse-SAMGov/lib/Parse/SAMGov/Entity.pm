package Parse::SAMGov::Entity;
$Parse::SAMGov::Entity::VERSION = '0.106';
use strict;
use warnings;
use 5.010;
use Data::Dumper;
use Parse::SAMGov::Mo;
use URI;
use DateTime;
use DateTime::Format::Strptime;
use Parse::SAMGov::Entity::Address;
use Parse::SAMGov::Entity::PointOfContact;
use Carp;

#ABSTRACT: Object to denote each Entity in SAM

use overload fallback => 1,
    '""' => sub {
        my $self = $_[0];
        my $str = '';
        $str .= $self->name if $self->name;
        $str .= ' dba ' . $self->dba_name if $self->dba_name;
        $str .= "\nDUNS: " . $self->DUNS if $self->DUNS;
        $str .= '+' . $self->DUNSplus4 if $self->DUNSplus4 ne '0000';
        $str .= "\nCAGE: " . $self->CAGE if $self->CAGE;
        $str .= "\nDODAAC: " . $self->DODAAC if $self->DODAAC;
        $str .= "\nStatus: " . $self->extract_code if $self->extract_code;
        $str .= "\nUpdated: Yes" if $self->updated;
        $str .= "\nRegistration Purpose: " . $self->regn_purpose if $self->regn_purpose;
        $str .= "\nRegistration Date: " . $self->regn_date->ymd('-') if $self->regn_date;
        $str .= "\nExpiry Date: " . $self->expiry_date->ymd('-') if $self->expiry_date;
        $str .= "\nLast Update Date: " . $self->lastupdate_date->ymd('-') if $self->lastupdate_date;
        $str .= "\nActivation Date: " . $self->activation_date->ymd('-') if $self->activation_date;
        $str .= "\nCompany Division: " . $self->company_division if $self->company_division;
        $str .= "\nDivision No.: " . $self->division_no if $self->division_no;
        $str .= "\nPhysical Address: " . $self->physical_address if $self->physical_address;
        $str .= "\nBusiness Start Date: " . $self->start_date->ymd('-') if $self->start_date;
        $str .= sprintf "\nFiscal Year End: %02d-%02d", $self->fiscalyear_date->month, $self->fiscalyear_date->day
                if $self->fiscalyear_date;
        $str .= "\nCorporate URL: " . $self->url if $self->url;
        $str .= "\nBusiness Types: [" . join(',', @{$self->biztype}) . "]";
        $str .= "\nNAICS Codes: [" . join(',', keys %{$self->NAICS}) . "]";
        $str .= "\nSmall Business: " . ($self->is_smallbiz() ? 'Yes' : 'No');
        {
            local $Data::Dumper::Indent = 1;
            local $Data::Dumper::Terse = 1;
            $str .= "\nNAICS Details: " . Dumper($self->NAICS);
        }
        $str .= "\nPSC Codes: [" . join(',', @{$self->PSC}) . "]";
        $str .= "\nMailing Address: " . $self->mailing_address if $self->mailing_address;
        $str .= "\nGovt Business POC: " . $self->POC_gov if $self->POC_gov;
        $str .= "\nGovt Business POC (alternate): " . $self->POC_gov_alt if $self->POC_gov_alt;
        $str .= "\nPast Performance POC: " . $self->POC_pastperf if $self->POC_pastperf;
        $str .= "\nPast Performance POC (alternate): " . $self->POC_pastperf_alt if $self->POC_pastperf_alt;
        $str .= "\nElectronic POC: " . $self->POC_elec if $self->POC_elec;
        $str .= "\nElectronic POC (alternate): " . $self->POC_elec_alt if $self->POC_elec_alt;
        $str .= "\nDelinquent Federal Debt: " . ($self->delinquent_fed_debt ? 'Yes' : 'No');
        $str .= "\nExclusion Status: " . $self->exclusion_status if $self->exclusion_status;
        {
            local $Data::Dumper::Indent = 0;
            local $Data::Dumper::Terse = 1;
            $str .= "\nSBA Business Type: " . Dumper($self->SBA);
        }
        {
            local $Data::Dumper::Indent = 0;
            local $Data::Dumper::Terse = 1;
            $str .= "\nDisaster Response Type: " . Dumper($self->disaster_response);
        }
        $str .= "\nIs Private Listing: " . ($self->is_private ? 'Yes' : 'No');
        return $str;
    };


has 'DUNS';
has DUNSplus4 =>  default => sub { '0000' };
has 'CAGE';
has 'DODAAC';


has 'extract_code';
has 'updated';
has 'regn_purpose' => coerce => sub {
    my $p = $_[0];
    return 'Federal Assistance Awards' if $p eq 'Z1';
    return 'All Awards' if $p eq 'Z2';
    return 'IGT-Only' if $p eq 'Z3';
    return 'Federal Assistance Awards & IGT' if $p eq 'Z4';
    return 'All Awards & IGT' if $p eq 'Z5';
};

sub _parse_yyyymmdd {
    if (@_) {
        my $d = shift;
        if (length($d) == 4) {
            my $y  = DateTime->now->year;
            $d = "$y$d";
        }
        state $Strp =
          DateTime::Format::Strptime->new(pattern   => '%Y%m%d',
                                          time_zone => 'America/New_York',);
        return $Strp->parse_datetime($d);
    }
    return;
}


has 'regn_date' => coerce => sub { _parse_yyyymmdd $_[0] };
has 'expiry_date' => coerce => sub { _parse_yyyymmdd $_[0] };
has 'lastupdate_date' => coerce => sub { _parse_yyyymmdd $_[0] };
has 'activation_date' => coerce => sub { _parse_yyyymmdd $_[0] };


has 'name';
has 'dba_name';
has 'company_division';
has 'division_no';
has 'physical_address' => default => sub { return Parse::SAMGov::Entity::Address->new; };


has 'start_date' => coerce => sub { _parse_yyyymmdd $_[0] };
has 'fiscalyear_date' => coerce => sub { _parse_yyyymmdd $_[0] };
has 'url' => coerce => sub { URI->new($_[0]) };
has 'entity_structure';


has 'incorporation_state';
has 'incorporation_country';



has 'biztype' => default => sub { [] };
has 'NAICS' => default => sub { {} };
has 'PSC' => default => sub { [] };
has 'creditcard';
has 'correspondence_type';
has 'mailing_address' => default => sub { return Parse::SAMGov::Entity::Address->new; };
has 'POC_gov' => default => sub { return
    Parse::SAMGov::Entity::PointOfContact->new; };
has 'POC_gov_alt' => default => sub {
    Parse::SAMGov::Entity::PointOfContact->new; };
has 'POC_pastperf' => default => sub {
    Parse::SAMGov::Entity::PointOfContact->new; };
has 'POC_pastperf_alt' => default => sub {
    Parse::SAMGov::Entity::PointOfContact->new; };
has 'POC_elec' => default => sub {
    Parse::SAMGov::Entity::PointOfContact->new; };
has 'POC_elec_alt' => default => sub {
    Parse::SAMGov::Entity::PointOfContact->new; };
has 'delinquent_fed_debt';
has 'exclusion_status';
has 'is_private';
has 'disaster_response' => default => sub { {} };
has 'SBA' => default => sub { {} };

has 'SBA_descriptions' => default => sub {
    {
        A4 => 'SBA Certified Small Disadvantaged Business',
        A6 => 'SBA Certified 8A Program Participant',
        JT => 'SBA Certified 8A Joint Venture',
        XX => 'SBA Certified HUBZone Firm',
    }
};

sub is_smallbiz {
    my $self = shift;
    my $res = 0;
    foreach my $k (keys %{$self->NAICS}) {
        $res = 1 if $self->NAICS->{$k}->{small_biz};
        $res = 1 if $self->NAICS->{$k}->{exception}->{small_biz};
        last if $res;
    }
    return $res;
}

sub _trim {
    # from Mojo::Util::trim
    my $s = shift;
    $s =~ s/^\s+//g;
    $s =~ s/\s+$//g;
    return $s;
}

sub load {
    my $self = shift;
    return unless (scalar(@_) == 150);
    $self->DUNS(shift);
    $self->DUNSplus4(shift || '0000');
    $self->CAGE(shift);
    $self->DODAAC(shift);
    $self->updated(0);
    my $code = shift;
    if ($code =~ /A|2|3/x) {
        $self->extract_code('active');
        $self->updated(1) if $code eq '3';
    } elsif ($code =~ /E|1|4/x) {
        $self->extract_code('expired');
        $self->updated(1) if $code eq '1';
    }
    $self->regn_purpose(shift);
    $self->regn_date(shift);
    $self->expiry_date(shift);
    $self->lastupdate_date(shift);
    $self->activation_date(shift);
    $self->name(_trim(shift));
    $self->dba_name(_trim(shift));
    $self->company_division(_trim(shift));
    $self->division_no(_trim(shift));
    my $paddr = Parse::SAMGov::Entity::Address->new(
        # the order of shifting matters
        address => _trim(join(' ', shift, shift)),
        city => shift,
        state => shift,
        zip => sprintf("%s-%s", shift, shift),
        country => shift,
        district => shift,
    );
    $self->physical_address($paddr);
    $self->start_date(shift);
    $self->fiscalyear_date(shift);
    $self->url(_trim(shift));
    $self->entity_structure(shift);
    $self->incorporation_state(shift);
    $self->incorporation_country(shift);
    my $count = int(_trim(shift) || 0);
    if ($count > 0) {
        my @biztypes = grep { length($_) > 0 } split /~/, shift;
        $self->biztype([@biztypes]);
    } else {
        shift; # ignore
    }
    my $pnaics = _trim(shift);
    $self->NAICS->{$pnaics} = {};
    $count = int(_trim(shift) || 0) + (length($pnaics) ? 1 : 0);
    if ($count > 0) {
        my @naics = grep { length($_) > 0 } split /~/, shift;
        foreach my $c (@naics) {
            if ($c =~ /(\d+)(Y|N|E)/) {
                $self->NAICS->{$1} = {} unless ref $self->NAICS->{$1} eq 'HASH';
                $self->NAICS->{$1}->{is_primary} = 1 if $pnaics eq $1;
                $self->NAICS->{$1}->{small_biz} = 1 if $2 eq 'Y';
                $self->NAICS->{$1}->{small_biz} = 0 if $2 eq 'N';
                $self->NAICS->{$1}->{exception} = {} if $2 eq 'E';
            }
        }
    } else {
        shift; # ignore
    }
    $count = int(_trim(shift) || 0);
    if ($count > 0) {
        my @psc = grep { length ($_) > 0 } split /~/, shift;
        $self->PSC([@psc]);
    } else {
        shift; # ignore
    }
    $self->creditcard((shift eq 'Y') ? 1 : 0);
    $code = shift; # re-use variable
    $self->correspondence_type('mail') if $code eq 'M';
    $self->correspondence_type('fax') if $code eq 'F';
    $self->correspondence_type('email') if $code eq 'E';
    my $maddr = Parse::SAMGov::Entity::Address->new(
        # the order of shifting matters
        address => _trim(join(' ', shift, shift)),
        city => shift,
        zip => sprintf("%s-%s", shift, shift),
        country => shift,
        state => shift,
    );
    $self->mailing_address($maddr);
    for my $i (0..5) {
        my $poc = Parse::SAMGov::Entity::PointOfContact->new(
            first => _trim(shift),
            middle => _trim(shift),
            last => _trim(shift),
            title => _trim(shift),
            address => _trim(join(' ', shift, shift)),
            city => shift,
            zip => sprintf("%s-%s", shift, shift),
            country => shift,
            state => shift,
            phone => shift,
            phone_ext => shift,
            phone_nonUS => shift,
            fax => shift,
            email => shift,
        );
        $self->POC_gov($poc) if $i == 0;
        $self->POC_gov_alt($poc) if $i == 1;
        $self->POC_pastperf($poc) if $i == 2;
        $self->POC_pastperf_alt($poc) if $i == 3;
        $self->POC_elec($poc) if $i == 4;
        $self->POC_elec_alt($poc) if $i == 5;
    }
    $count = int(_trim(shift) || 0);
    if ($count > 0) {
        my @naics = grep { length($_) > 0 } split /~/, shift;
        foreach my $c (@naics) {
            if ($c =~ /(\d+)([YN ]*)/) {
                my @es = split //, $2;
                if (@es) {
                    $self->NAICS->{$1}->{exception} = {} unless ref $self->NAICS->{$1}->{exception} eq 'HASH';
                    $self->NAICS->{$1}->{exception}->{small_biz} = 1 if $es[0] eq 'Y';
                    $self->NAICS->{$1}->{exception}->{small_biz} = 0 if $es[0] eq 'N';
                }
            }
        }
    } else {
        shift; # ignore
    }
    $code = shift;
    $self->delinquent_fed_debt(1) if $code eq 'Y';
    $self->delinquent_fed_debt(0) if $code eq 'N';
    $self->exclusion_status(_trim(shift));
    $count = int(_trim(shift) || 0);
    if ($count > 0) {
        my @sba = grep { length($_) > 0 } split /~/, shift;
        foreach my $c (@sba) {
            if ($c =~ /(\w{2})(\d{8})/) {
                my $t = $1;
                $self->SBA->{$t} = {} unless ref $self->SBA->{$t} eq 'HASH';
                $self->SBA->{$t}->{description} = $self->SBA_descriptions->{$t};
                $self->SBA->{$t}->{expiration} = _parse_yyyymmdd($2);
            }
        }
    } else {
        shift; # ignore
    }
    $self->is_private(length(shift) ? 1 : 0);
    $count = int(_trim(shift) || 0);
    if ($count > 0) {
        my @dres = grep { length($_) > 0 } split /~/, shift;
        my $h = {};
        my %desc = (
            ANY => 'Any area',
            CTY => 'County',
            STA => 'State',
            MSA => 'Metropolitan Service Area',
        );
        foreach my $c (@dres) {
            if ($c =~ /(\w{3})(\w*)/) {
                $h->{$1} = {} unless ref $h->{$1} eq 'HASH';
                $h->{$1}->{description} = $desc{$1};
                $h->{$1}->{areas} = [] unless ref $h->{$1}->{areas} eq 'HASH';
                my $a = _trim($2);
                push @{$h->{$1}->{areas}}, $a if length $a;
            }
        }
        $self->disaster_response($h);
    } else {
        shift; # ignore
    }
    my $eof = shift;
    carp "Invalid end of record '$eof' seen. Expected '!end'" if $eof ne '!end';
    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Parse::SAMGov::Entity - Object to denote each Entity in SAM

=head1 VERSION

version 0.106

=head1 SYNOPSIS

    my $e = Parse::SAMGov::Entity->new(DUNS => 12345);
    say $e; #... stringification supported ...

=head1 METHODS

=head2 DUNS

This holds the unique identifier of the entity, currently the Data
Universal Numbering System (DUNS) number. This has a maximum length of 9 characters.
This number can be gotten from Dun & Bradstreet.

=head2 DUNSplus4

This holds the DUNS+4 value which is of 4 characters. If an entity doesn't have
this value set, it will be set as '0000'.

=head2 CAGE

This holds the CAGE code of the Entity.

=head2 DODAAC

This holds the DODAAC code of the entity.

=head2 extract_code

This denotes whether the SAM entry is active or expired
during extraction of the data.

=head2 updated

This denotes whether the SAM entry has been updated recently. Has a boolean
value of 1 if updated and 0 or undef otherwise.

=head2 regn_purpose

This denotes whether the purpose of registration is Federal Assistance Awards,
All Awards, IGT-only, Federal Assistance Awards & IGT or All Awards & IGT.

=head2 regn_date

Registration date of the entity with the input in YYYYMMDD format and it returns
a DateTime object.

=head2 expiry_date

Expiration date of the registration of the entity. The input is in YYYYMMDD
format and it returns a DateTime object.

=head2 lastupdate_date

Last update date of the registration of the entity. The input is in YYYYMMDD
format and it returns a DateTime object.

=head2 activation_date

Activation date of the registration of the entity. The input is in YYYYMMDD
format and it returns a DateTime object.

=head2 name

The legal business name of the entity.

=head2 dba_name

The Doing Business As (DBA) name of the entity.

=head2 company_division

The company division listed in the entity.

=head2 division_no

The divison number of the company division.

=head2 physical_address

This is the physical address of the entity represented as a
Parse::SAMGov::Entity::Address object.

=head2 start_date

This denotes the business start date. It takes as input the date in YYYYMMDD
format and returns a DateTime object.

=head2 fiscalyear_date

This denotes the current fiscal year end close date in YYYYMMDD format and
returns a DateTime object.

=head2 url

The corporate URL is denoted in this method. Returns a URI object and takes a
string value.

=head2 entity_structure

Get/Set the entity structure of the entity.

=head2 incorporation_state

Get/Set the two-character abbreviation of the state of incorporation.

=head2 incorporation_country

Get/Set the three-character abbreviation of the country of incorporation.

=head2 biztype

Get/Set the various business types that the entity holds. Requires an array
reference. The full list of business type codes can be retrieved from the SAM
Functional Data Dictionary.

=head2 is_smallbiz

Returns 1 or 0 if the business is defined as a small business or not.

=head2 NAICS

Get/Set the NAICS codes for the entity. This is a hash reference with the keys
being the numeric NAICS codes and the values being a hash reference with the
following keys:

    {
        124567 => {
            small_biz => 1,
            exceptions => {
                small_biz => 0,
                # ... undocumented others ...
            },
        },
        # ...
    }
whether it is a small
business (value is 1)  or not (value is 0) or has an exception (value is 2).

=head2 PSC

Get/Set the PSC codes for the entity. This requires an array reference.

=head2 creditcard

This denotes whether the entity uses a credit card.

=head2 correspondence_type

This denotes whether the entity prefers correspondence by mail, fax or email.
Returns a string of value 'mail', 'fax' or 'email'.

=head2 mailing_address

The mailing address of the entity as a L<Parse::SAMGov::Entity::Address> object.

=head2 POC_gov

This denotes the Government business Point of Contact for the entity and holds an
L<Parse::SAMGov::Entity::PointOfContact> object.

=head2 POC_gov_alt

This denotes the alternative Government business  Point of Contact for the entity and
holds an L<Parse::SAMGov::Entity::PointOfContact> object.

=head2 POC_pastperf

This denotes the Past Performance Point of Contact for the entity and
holds an L<Parse::SAMGov::Entity::PointOfContact> object.

=head2 POC_pastperf_alt

This denotes the alternative Past Performance Point of Contact for the entity and
holds an L<Parse::SAMGov::Entity::PointOfContact> object.

=head2 POC_elec

This denotes the electronic business Point of Contact for the entity and
holds an L<Parse::SAMGov::Entity::PointOfContact> object.

=head2 POC_elec_alt

This denotes the alternative electronic business Point of Contact for the entity and
holds an L<Parse::SAMGov::Entity::PointOfContact> object.

=head2 delinquent_fed_debt

Get/Set the delinquent federal debt flag.

=head2 exclusion_status

Get/Set the exclusion status flag.

=head2 is_private

This flag denotes whether the listing is private or not.

=head2 SBA

This holds a hash-ref of Small Business Administration codes such as Hubzone,
8(a) certifications and the expiration dates. The structure looks like below:

    {
        A4 => { description => 'SBA Certified Small Disadvantaged Busines',
                expiration => '2016-12-01', #... this is a DateTime object...
              },
    }    

=head2 disaster_response

This holds an array ref of disaster response (FEMA) codes that the entity falls
under, if applicable.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Selective Intellect LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
