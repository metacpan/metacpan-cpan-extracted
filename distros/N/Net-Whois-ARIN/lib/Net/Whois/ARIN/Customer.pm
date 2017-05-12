package Net::Whois::ARIN::Customer;

=head1 NAME

Net::Whois::ARIN::Customer - ARIN whois Customer record class

=head1 SYNOPSIS

  use Net::Whois::ARIN::Customer;

  my $cust = Net::Whois::ARIN::Customer->new(
               CustName   => 'Electric Lightwave Inc',
               Address    => '4400 NE 77th Ave',
               City       => 'Vancouver',
               StateProv  => 'WA',
               PostalCode => '98662',
               Country    => 'US',
               Comment    => '',
               RegDate    => '1995-07-25',
               Updated    => '2001-05-17',
           );

  printf "%s is located in %s, %s\n",
         $cust->CustName,
         $cust->City,
         $cust->StateProv;

=head1 DESCRIPTION

The Net::Whois::ARIN::Customer module is simple class which is used to store the attributes of an Customer record in A
RIN's Whois server.  Each attribute of the Customer record has an accessor/mutator of the same name.

=cut

use strict;
use Carp "croak";

our $AUTOLOAD;

=head1 METHODS

=over 4

=item B<new> - create a Net::Whois::ARIN::Customer object

=back

=cut

sub new {
    my $class = shift;
    return bless { _contacts => [], @_ }, $class;
}

=over 4

=item B<contacts> - get/set Net::Whois::ARIN::Contact

This method accepts a list of Net::Whois::ARIN::Contact and associates these objects with the Organization record.  If no argu
ments are specified, the method returns a list of Net::Whois::ARIN::Contact objects.

=back

=cut

sub contacts {
    my $self = shift;
    $self->{_contacts} = [ @_ ] if @_;
    return @{ $self->{_contacts} };
}

=over 4

=item B<dump> - return the current whois record

  print $o->dump;

=back

=cut

sub dump {
    my $self = shift;
    my $record = sprintf "\nCustName:    %s\n", $self->CustName;
    $record .= sprintf("Address:    %s\n", $_) for @{ $self->Address };
    $record .= sprintf "City:       %s\n",$self->City;
    $record .= sprintf "StateProv:  %s\n",$self->StateProv;
    $record .= sprintf "PostalCode: %s\n",$self->PostalCode;
    $record .= sprintf "Country:    %s\n",$self->Country;
    $record .= sprintf "RegDate:    %s\n",$self->RegDate;
    $record .= sprintf "Updated:    %s\n\n",$self->Updated;

    $record .= sprintf "NetRange:   %s\n",$self->NetRange;
    $record .= sprintf "CIDR:       %s\n",$self->CIDR;
    $record .= sprintf "NetName:    %s\n",$self->NetName;
    $record .= sprintf "NetHandle:  %s\n",$self->NetHandle;
    $record .= sprintf "Parent:     %s\n",$self->Parent;
    $record .= sprintf "NetType:    %s\n",$self->NetType;
    $record .= sprintf "Comment:    %s\n",$self->Comment;
    $record .= sprintf "RegDate:    %s\n",$self->RegDate;
    $record .= sprintf "Updated:    %s\n",$self->Updated;

    foreach my $contact ( $self->contacts ) {
        $record .= sprintf "%sHandle: %s\n", $contact->Type, $contact->Handle;
        $record .= sprintf "%sName: %s\n", $contact->Type, $contact->Name;
        $record .= sprintf "%sPhone: %s\n", $contact->Type, $contact->Phone;
        $record .= sprintf "%sEmail: %s\n", $contact->Type, $contact->Email;
    }

    return $record;
}

=head1 ATTRIBUTES

These methods are the accessors/mutators for the fields found in the Whois record.

=over 4

=item B<CustName> - get/set the customer name

=item B<Address> - get/set the address

=item B<City> - get/set the city

=item B<StateProv> - get/set the state or province

=item B<PostalCode> - get/set the postal code

=item B<Country> - get/set the country

=item B<RegDate> - get/set the registration date

=item B<Updated> - get/set the last updated date

=item B<NetRange> - get/set the network range

=item B<CIDR> - get/set the CIDR netblock

=item B<NetName> - get/set the network name

=item B<NetHandle> - get/set the network handle

=item B<Parent> - get/set the parent network handle

=item B<NetType> - get/set the network type

=item B<Comment> - get/set the public comment

=back

=cut

sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    return if $name eq 'DESTROY';

    if ($name !~ /^_/ && exists $self->{$name}) {
        if (@_) {
            return $self->{$name} = shift;
        } else {
            return $self->{$name};
        }
    }

    croak "Undefined subroutine \&$AUTOLOAD called";
}

=head1 AUTHOR

Todd Caine   <todd.caine at gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2011 Todd Caine.  All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
__END__
