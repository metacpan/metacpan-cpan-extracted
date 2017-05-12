package Net::Whois::ARIN::Contact;

=head1 NAME

Net::Whois::ARIN::Contact - ARIN whois Contact record class

=head1 SYNOPSIS

  use Net::Whois::ARIN::Contact;

  my $poc = Net::Whois::ARIN::Contact->new(
               Name       => 'Caine, Todd',
               Handle     => 'TCA53-ARIN',
               Company    => 'Electric Lightwave',
               Address    => '4400 NE 77th Ave',
               City       => 'Vancouver',
               StateProv  => 'WA',
               PostalCode => '98662',
               Country    => 'US',
               Comment    => '',
               RegDate    => '1995-07-25',
               Updated    => '2001-05-17',
               Phone      => '503-555-1212',
               Email      => 'nobody@nobody.net',
           );

  printf "The ARIN contact handle for %s is %s.\n",
         $poc->Name,
         $poc->Handle;

=head1 DESCRIPTION

The Net::Whois::ARIN::Contact module is simple class which is used to store the attributes of a point-of-contact record in ARIN's Whois server.  Each attribute of the contact record has an accessor/mutator of the same name.

=cut

use strict;
use Carp "croak";

our $AUTOLOAD;

=head1 METHODS

=over 4

=item B<new> - create a Net::Whois::ARIN::Contact object

=cut

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

=item B<dump> - return the current whois record

  print $o->dump;

=back

=cut

sub dump {
    my $self = shift;
    my $record = sprintf "\nName:       %s\n",$self->Name;
    $record .= sprintf "Handle:     %s\n",$self->Handle;
    $record .= sprintf "Company:    %s\n",$self->Company;
    $record .= sprintf("Address:    %s\n", $_) for @{ $self->Address };
    $record .= sprintf "City:       %s\n",$self->City;
    $record .= sprintf "StateProv:  %s\n",$self->StateProv;
    $record .= sprintf "PostalCode: %s\n",$self->PostalCode;
    $record .= sprintf "Country:    %s\n",$self->Country;
    $record .= sprintf "Comment:    %s\n",$self->Comment;
    $record .= sprintf "RegDate:    %s\n",$self->RegDate;
    $record .= sprintf "Updated:    %s\n",$self->Updated;
    $record .= sprintf "Phone:      %s\n",$self->Phone;
    $record .= sprintf "Email:      %s\n",$self->Email;
    return $record;
}

sub Type {
    my $self = shift;
    $self->{Type} = shift if @_;
    return $self->{Type};
}

=head1 ATTRIBUTES

These methods are the accessors/mutators for the fields found in the Whois record.

=over 4

=item B<Type> - get/set the contact type

=item B<Name> - get/set the contact name

=item B<Handle> - get/set the contact handle

=item B<Company> - get/set the company

=item B<Address> - get/set the address

=item B<City> - get/set the city

=item B<StateProv> - get/set the state or province

=item B<PostalCode> - get/set the postal code

=item B<Country> - get/set the country

=item B<RegDate> - get/set the registration date

=item B<Updated> - get/set the last updated date

=item B<Phone> - get/set the contact phone number

=item B<Email> - get/set the contact email address

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
