package Net::Whois::ARIN::AS;

our $AUTOLOAD;

=head1 NAME

Net::Whois::ARIN::AS - ARIN whois AS record class

=head1 SYNOPSIS

  use Net::Whois::ARIN::AS;

  my $as = Net::Whois::ARIN::AS->new(
               OrgName    => 'Electric Lightwave Inc',
               OrgID      => 'ELIX',
               Address    => '4400 NE 77th Ave',
               City       => 'Vancouver',
               StateProv  => 'WA',
               PostalCode => '98662',
               Country    => 'US',
               RegDate    => '1995-07-25',
               Updated    => '2001-05-17',
               ASName     => 'ELIX',
               ASNumber   => '5650',
               ASHandle   => 'AS5650',
               Comment    => '',
           );

  printf "%s has ASN %d\n", 
         $as->OrgName, 
         $as->ASNumber;    

=head1 DESCRIPTION

The Net::Whois::ARIN::AS module is simple class which is used to store the attributes of an AS record in ARIN's Whois server.  Each attribute of the AS record has an accessor/mutator of the same name.

=cut

use strict;
use Carp "croak";

=head1 METHODS

=over 4

=item B<new> - create a Net::Whois::ARIN::AS object

=cut

sub new {
    my $class = shift;
    return bless { _contacts => [], @_ }, $class;
}

=item B<contacts> - get/set Net::Whois::ARIN::Contact

This method accepts a list of Net::Whois::ARIN::Contact and associates these objects with the AS record.  If no arguments are specified, the method returns a list of Net::Whois::ARIN::Contact objects.

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
    my $record = sprintf "\nOrgName:    %s\n",$self->OrgName;
    $record .= sprintf "OrgName:    %s\n",$self->OrgID;
    $record .= sprintf("Address:    %s\n", $_) for @{ $self->Address };
    $record .= sprintf "City:       %s\n",$self->City;
    $record .= sprintf "StateProv:  %s\n",$self->StateProv;
    $record .= sprintf "PostalCode: %s\n",$self->PostalCode;
    $record .= sprintf "Country:    %s\n",$self->Country;
    $record .= sprintf "ASNumber:   %s\n",$self->ASNumber;
    $record .= sprintf "ASName:     %s\n",$self->ASName;
    $record .= sprintf "ASHandle:   %s\n",$self->ASHandle;
    $record .= sprintf "Comment:    %s\n",$self->Comment;
    $record .= sprintf "RegDate:    %s\n",$self->RegDate;
    $record .= sprintf "Updated:    %s\n\n",$self->Updated;

    foreach my $contact ( $self->contacts ) {
        $record .= sprintf "%sHandle: %s\n",$contact->Type,$contact->Handle;
        $record .= sprintf "%sName:   %s\n",$contact->Type,$contact->Name;
        $record .= sprintf "%sPhone:  %s\n",$contact->Type,$contact->Phone;
        $record .= sprintf "%sEmail:  %s\n",$contact->Type,$contact->Email;
    }

    return $record;
}

=head1 ATTRIBUTES

These methods are the accessors/mutators for the fields found in the Whois record.

=over 4

=item B<OrgName> - get/set the organization name

=item B<OrgID> - get/set the organization id

=item B<Address> - get/set the address

=item B<City> - get/set the city

=item B<StateProv> - get/set the state or province

=item B<PostalCode> - get/set the postal code

=item B<Country> - get/set the country

=item B<RegDate> - get/set the registration date

=item B<Updated> - get/set the last updated date

=item B<ASNumber> - get/set the AS number

=item B<ASName> - get/set the AS name

=item B<ASHandle> - get/set the AS handle

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
