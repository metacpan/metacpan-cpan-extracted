package Polycom::Contact;
use strict;
use warnings;
use base qw(Class::Accessor);

our $VERSION = 0.05;

use overload (
    '==' => sub { !$_[0]->diff($_[1]) },
    '!=' => sub { scalar $_[0]->diff($_[1]) },
    '""' => sub {
        my $name = join ' ', grep {defined} ($_[0]->{first_name}, $_[0]->{last_name});
        return join ' at ', grep {$_} ($name, $_[0]->{contact});
    },
);

Polycom::Contact->mk_accessors(
    qw(first_name last_name contact speed_index label ring_type divert
    auto_reject auto_divert buddy_watching buddy_block in_storage)
);

###################
# Constructors
###################
sub new
{
    my ($class, %args) = @_;

    my $self = {
        first_name     => $args{first_name},
        last_name      => $args{last_name},
        contact        => $args{contact},
        speed_index    => $args{speed_index},
        label          => $args{label},
        ring_type      => $args{ring_type},
        divert         => $args{divert} || 0,
        auto_reject    => $args{auto_reject} || 0,
        auto_divert    => $args{auto_divert} || 0,
        buddy_watching => $args{buddy_watching} || 0,
        buddy_block    => $args{buddy_block} || 0,
        in_storage     => $args{in_storage} || 0,
    };

    if (!defined $self->{contact} || $self->{contact} eq '')
    {
        warn "No 'contact' attribute specified";
    }

    return bless $self, $class;
}

###################
# Public Methods
###################
sub is_valid
{
    my ($self, $reason) = @_;

    if (defined $self->first_name && length $self->first_name > 40)
    {
        $reason = 'first_name must be <= 40 bytes long';        
        return;
    }

    if (defined $self->last_name && length $self->last_name > 40)
    {
        $reason = 'last_name must be <= 40 bytes long';        
        return;
    }

    if (!defined $self->contact || $self->contact eq '')
    {
        $reason = 'contact is a required field';
        return;
    }

    if (   defined $self->speed_index
        && ($self->speed_index !~ /^\d*$/
        || $self->speed_index < 1
        || $self->speed_index > 9999))
    {
        $reason = 'speed_index must be a number between 1 and 9999';
        return;
    }

    if (   defined $self->ring_type
        && ($self->ring_type !~ /^\d*$/
        || $self->ring_type < 1
        || $self->ring_type > 21))
    {
        $reason = 'ring_type must be a number between 1 and 21';
        return;
    }

    if (defined $self->auto_divert && $self->auto_divert !~ /^[01]?$/)
    {
        $reason = 'auto_divert must be either "", 0, or 1';
        return;
    }

    if (defined $self->auto_reject && $self->auto_reject !~ /^[01]?$/)
    {
        $reason = 'auto_reject must be either "", 0, or 1';
        return;
    }

    if (defined $self->buddy_watching && $self->buddy_watching !~ /^[01]?$/)
    {
        $reason = 'buddy_watching must be either "", 0, or 1';
        return;
    }

    if (defined $self->buddy_block && $self->buddy_block !~ /^[01]?$/)
    {
        $reason = 'buddy_block must be either "", 0, or 1';
        return;
    }

    return 1;
}

sub delete
{
    my ($self) = @_;
    $self->{in_storage} = 0;
    return;
}

sub diff
{
    my ($self, $other) = @_;

    # Map each contact attribute to a "nice" name (e.g. first_name => "First Name")
    my %LABELS = (
        first_name     => 'First Name',
        last_name      => 'Last Name',
        contact        => 'Number',
        speed_index    => 'Speed Index',
        label          => 'Label',
        ring_type      => 'Ring Type',
        divert         => 'Divert',
        auto_reject    => 'Auto Reject',
        auto_divert    => 'Auto Divert',
        buddy_watching => 'Buddy Watch',
        buddy_block    => 'Buddy Block',
    );

    my @nonMatchingFields;
    while (my ($attr, $label) = each %LABELS)
    {
        my $mine   = defined $self->{$attr}  ? $self->{$attr}  : 0;
        my $theirs = defined $other->{$attr} ? $other->{$attr} : 0;

        # Normalize Boolean fields
        if (   $attr eq 'auto_reject'
            || $attr eq 'auto_divert'
            || $attr eq 'buddy_watching')
        {
            $mine   =~ s/Enabled/1/i;
            $theirs =~ s/Enabled/1/i;
            $mine   =~ s/Disabled//i;
            $theirs =~ s/Disabled//i;
        }

        if ($mine ne $theirs)
        {
            push @nonMatchingFields, $attr;
        }
    }

    return @nonMatchingFields;
}

=head1 NAME

Polycom::Contact - Contact in a Polycom VoIP phone's local contact directory.

=head1 SYNOPSIS

  use Polycom::Contact;

  # Create a new contact
  my $contact = Polycom::Contact->new(
      first_name => 'Bob',
      last_name  => 'Smith',
      contact    => '1234',
  );

  # The contact can be interpolated in strings
  # Prints: "The contact is: Bob Smith at 1234"
  print "The contact is: $contact\n";

  # The contact can also be compared with other contacts
  my $otherContact = Polycom::Contact->new(first_name => 'Jimmy', contact => '5678');
  if ($otherContact != $contact)
  {
    print "$otherContact is not the same as $contact\n";
  }

  # Or, of course, you can simply query the contact's fields
  my $first_name = $contact->first_name;
  my $last_name  = $contact->last_name;

=head1 DESCRIPTION

The C<Polycom::Contact> class represents a contact in a Polycom SoundPoint IP, SoundStation IP, or VVX phone's local contact directory. This class is intended to be used with C<Polycom::Contact::Directory>, which parses entire contact directory files, extracting the contacts, and enabling you to read or modify them.

=head1 CONSTRUCTOR

=head2 new ( %fields )

  use Polycom::Contact;
  my $contact = Polycom::Contact->new(first_name => 'Bob', contact => 1234);

Returns a newly created C<Polycom::Contact> object.

In all, each C<Polycom::Contact> object can have the following fields:

  first_name       - first name
  last_name        - last name
  contact          - phone number or URL (required)
  speed_index      - speed dial index (1 - 9999)
  label            - label to show on speed dial keys
  ring_type        - distinctive incoming ring tone (1 - 22)
  divert           - phone number or URL to divert incoming calls to
  auto_reject      - automatically reject calls from this contact (0 = no, 1 = yes)
  auto_divert      - automatically divert calls from this contact (0 = no, 1 = yes)
  buddy_watching   - include in the list of watched phones (0 = no, 1 = yes)
  buddy_block      - block from watching this phone (0 = no, 1 = yes)

Of those fields, the C<contact> field is the only required field; without a unique C<contact> field, the phone will not load the contact.

=head1 ACCESSORS

=head2 first_name

  my $fn = $contact->first_name;
  $contact->first_name('Bob');  # Set the first_name to "Bob"

=head2 last_name

  my $ln = $contact->last_name;
  $contact->last_name('Smith');  # Set the last_name to "Smith"

=head2 contact

The phone number, extension, or URL of the contact. This field must be present (i.e. not blank) and must be unique.

  my $num = $contact->contact;
  $contact->contact('1234');  # Set the contact number to 1234

=head2 speed_index

The speed dial index for the contact (1 - 9999).

  my $sd = $contact->speed_index;
  $contact->speed_index(5);  # Set the speed index to 5

Contacts that have a speed dial index specified are listed in the phone's speed dial menu and are mapped to unused line keys for quick access.

=head2 label

The label to show on speed dial keys (e.g. "Manager").

  my $lb = $contact->label;
  $contact->label('Sales');  # Set the label to "Sales"

=head2 ring_type

The distinctive incoming ring tone for this contact (1 - 22).

  my $rt = $contact->ring_type;
  $contact->ring_type(2);  # Set the ring type to 2

The ring type number must correspond to a ring type listed in the I<Settings> > I<Basic> > I<Ring Type> menu on the phone. When an incoming call is received from the contact, the specified ring tone will play instead of the default ring tone.

=head2 divert

The phone number or URL to divert incoming calls to.

  my $divert = $contact->divert;
  $contact->divert(2345);  # Set the divert phone number to 2345

=head2 auto_reject

Specifies whether to automatically reject calls from this contact (0 = no, 1 = yes).

  print "Calls from $contact will be automatically rejected" if ($contact->auto_reject);
  $contact->auto_reject(1);  # Enable auto reject

=head2 auto_divert

Specifies whether to automatically divert calls from this contact (0 = no, 1 = yes).

  print "Calls from $contact will be automatically diverted" if ($contact->auto_divert);
  $contact->auto_divert(1);  # Enable auto divert

=head2 buddy_watching

Specifies whether to include this contact in the list of watched phones (0 = no, 1 = yes).

  print "$contact is in the watched list" if ($contact->buddy_watching);
  $contact->buddy_watching(1);  # Add this contact to the buddy list

=head2 buddy_block

Specifies whether to block this contact from watching this phone (0 = no, 1 = yes).

  print "$contact is blocked from watching" if ($contact->buddy_block);
  $contact->buddy_block(1);  # Prevent this contact from watching this phone

=head1 METHODS

=head2 is_valid

  if (!$contact->is_valid)
  {
      print "$contact is invalid.\n";
  }

Returns I<undef> if the contact is invalid (i.e. it has no C<contact> value specified), or 1 otherwise.

=head2 delete

  my @contacts = $dir->search({first_name => 'Bob'});
  $contacts[0]->delete;
  
Removes the contact from the directory it belongs to (see C<Polycom::Contact::Directory>).
If the C<Polycom::Contact> object was created from scratch, rather than from an existing
contact directory object, then calling C<delete> has no effect.

=head2 diff ( $contact2 )

  my @differences = $contact1->diff($contact2);

Returns an array of contact field names that do not match (e.g. "First Name", "Speed Dial").

=head1 SEE ALSO

C<Polycom::Contact::Directory> - A closely related module that parses the XML-based local contact directory file used by Polycom SoundPoint IP, SoundStation IP, and VVX VoIP phones, and can be used to read, modify, or create contacts in the file. 

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Polycom Canada 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

'Together. Great things happen.';
