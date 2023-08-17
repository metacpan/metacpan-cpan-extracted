package Net::Fritz::PhonebookEntry;
use strict;
use Carp qw(croak);
use Moo 2;
use Filter::signatures;
use XML::Simple qw(:strict);
use feature 'signatures';
no warnings 'experimental::signatures';

use Net::Fritz::PhonebookEntry::Number;
use Net::Fritz::PhonebookEntry::Mail;

our $VERSION = '0.07';

our $has_DeletePhonebookEntryUID = 1;

=head1 NAME

Net::Fritz::PhonebookEntry - a Fritz!Box phone book entry

=head1 ACCESSORS

=head2 C< phonebook >

A weak reference to the phone book containing this entry

=cut

has 'phonebook' => (
    is => 'ro',
    weak_ref => 1,
);

=head2 C< uniqueid >

An opaque value assigned by the Fritz!Box to this entry

=cut

has 'uniqueid' => (
    is => 'rw',
);

=head2 C<< phonebookIndex >>

The index in the phonebook

This is used for entry deletion. I haven't tested whether the FritzBox
renumbers items while deleting, so the best approach is likely to delete
multiple items starting with the highest-numbered item.

=cut

has 'phonebookIndex' => (
    is => 'rw',
);

=head2 C< category >

The category of this entry

Numeric value, default 0

=cut

has 'category' => (
    is => 'rw',
    default => 0,
);

=head2 C< numbers >

Arrayref of the telephone numbers associated with this entry. The elements
will be L<Net::Fritz::PhonebookEntry::Number>s.

=cut

has 'numbers' => (
    is => 'rw',
    default => sub{ [] },
);

=head2 C< email_addresses >

Arrayref of the email addresses associated with this entry. The elements will be
L<Net::Fritz::PhonebookEntry::Email> objects.

=cut

has 'email_addresses' => (
    is => 'rw',
    default => sub{ [] },
);

=head2 C< name >

The name displayed in the phone book. This will likely be the name of a person.

=cut

has 'name' => (
    is => 'rw',
);

=head2 C< ringtoneidx >

The index of the ringtone to use for this entry?

=cut

has 'ringtoneidx' => (
    is => 'rw',
    #default => '',
);

=head2 C< imageURL >

HTTP URL to image for this contact

This must be on the same protocol and host as the Fritz!Box device
the phone book resides on!

=cut

has 'imageURL' => (
    is => 'rw',
    #default => '',
);

around BUILDARGS => sub ( $orig, $class, %args ) {
    my %self;
    if( exists $args{ contact }) {
        my $contact = $args{ contact }->[0];
        my $telephony = $contact->{telephony}->[0];

        # Fix up the horrible things that XML::Simple produces.
        # I swear I only used it because Net::Fritz uses it.
        for my $entry (qw(number services)) {
            if( 'HASH' eq ref $telephony->{$entry}) {
                $telephony->{$entry} = [values %{$telephony->{$entry}}];
            };
        };

        %self = (
            phonebook => $args{ phonebook },
            phonebookIndex => $args{ phonebookIndex },
            name     => $contact->{ person }->[0]->{realName}->[0],
            uniqueid => $contact->{uniqueid}->[0],
            category => $contact->{category}->[0],
            numbers => [map { Net::Fritz::PhonebookEntry::Number->new( %$_ ) }
                           @{ $telephony->{number} }
                       ],
            email_addresses => [map { Net::Fritz::PhonebookEntry::Mail->new( %$_ ) }
                           @{ $telephony->{services} }
                       ],
        );
        if( exists $contact->{imageURL} ) {
            $self{imageURL} = $contact->{imageURL}->[0];
        };
    } else {
        %self = %args;
    };
    return $class->$orig( %self );
};

=head2 C<< $contact->build_structure >>

  my $struct = $contact->build_structure;
  XMLout( $struct );

Returns the contact as a structured hashref that XML::Simple will serialize to
the appropriate XML to write a contact.

=cut

# This is the reverse of BUILDARGS, basically
sub build_structure( $self ) {
    my %optional_fields;
    for my $field (qw(uniqueid ringtoneidx imageURL)) {
        if( defined $self->$field ) {
            $optional_fields{ $field } = [$self->$field];
        };
    };

    my $res = {
        person => [{
            realName => [$self->name],
        }],
        telephony => [{
                number => [map { $_->build_structure } @{ $self->numbers }],
                services =>
                    [map { $_->build_structure } @{ $self->email_addresses }],
        }],
        category => [$self->category],
        %optional_fields,
    };

    # "pre-encode" the name for SOAP?!
    #use Encode 'encode';
    #use Data::Dumper;
    #$Data::Dumper::Useqq = 1;
    #warn "Before: ", Dumper $res->{person}->[0]->{realName}->[0];
    #$res->{person}->[0]->{realName}->[0] = encode 'UTF-8', $res->{person}->[0]->{realName}->[0];
    #warn "After : ", Dumper $res->{person}->[0]->{realName}->[0];

    $res
}

=head2 C<< $contact->add_number( $number, $type='home' ) >>

  $contact->add_number('555-12345');
  $contact->add_number('555-12346', 'fax_work');

Adds a number to the entry. No check is made whether that number is already
associated with that phone book entry. You can alternatively pass in a
l<Net::Fritz::PhonebookEntry::Number> object.

=cut

sub add_number($self, $n, $type='home') {
    if( ! ref $n) {
        $n = Net::Fritz::PhonebookEntry::Number->new( content => $n, type => $type );
    };
    push @{$self->numbers}, $n;
};

=head2 C<< $contact->add_email( $mail ) >>

  $contact->add_email('example@example.com');

Adds an email address to the entry. No check is made whether that address is
already associated with that phone book entry. You can alternatively pass in a
l<Net::Fritz::PhonebookEntry::Email> object.

=cut

sub add_email($self, $m) {
    if( ! ref $m) {
        $m = Net::Fritz::PhonebookEntry::Mail->new( email => [{ content => $m }]);
    };
    push @{$self->email_addresses}, $m;
};

=head2 C<< $contact->create() >>

  $contact->create(); # save to Fritz!Box
  $contact->create(phonebook => $other_phonebook);

Creates the contact in the phonebook given at creation or in the call. The
allowed options are

=over 4

=item B<phonebook_id>

The id of the phonebook to use

=item B<phonebook>

The phonebook object to use

=back

If neither the id nor the object are given, the C<phonebook>

=cut

sub create( $self, %options ) {
    if( ! defined $options{ phonebook_id }) {
        $options{ phonebook } ||= $self->phonebook;
        $options{ phonebook_id } = $options{ phonebook }->id;
    };
    $self->phonebook->service->call('AddPhonebookEntry',
        NewPhonebookID => $options{ phonebook_id },
    )->data
}

sub delete_by_search( $self ) {
    # Let's do a binary search, in the hope that names are sorted alphabetically:
    my $count = @{ $self->phonebook->entries };
    my $high = $count - 1;
    my $low = 0; # in theory maybe $self->phonebookIndex; ?!
    my $ofs = $low + int( ($high-$low) / 2 );

    # Maybe we get lucky
    my $remote_self = $self->phonebook->get_entry_by_index( $self->phonebookIndex );
    while( $remote_self->name ne $self->name ) {

        #use Data::Dumper;
        #binmode STDERR, ':utf8';
        #warn "[$ofs ($low,$high)] " . join "/", $remote_self->name, $self->name;

        if( $high == $low ) {
            last
        } elsif( $remote_self->name gt $self->name ) {
            $high = $ofs;
        } else {
            $low = $ofs;
        };
        $ofs = $low + int(( $high - $low ) / 2);
        $remote_self = $self->phonebook->get_entry_by_index( $ofs );
    };
    #warn "Found at [$ofs] " . $remote_self->name;

    if( $remote_self->name ne $self->name ) {
        # Not found anymore?!
        return Net::Fritz::Error->new( error => sprintf "Name '%s' not found", $self->name );
    };

    my $res = $self->phonebook->service->call('DeletePhonebookEntry',
        NewPhonebookID => $self->phonebook->id,
        NewPhonebookEntryID => $ofs,
    );

    return $res
}

sub delete( $self, %options ) {
    my $res;

    if( $has_DeletePhonebookEntryUID ) {
    # This one is available starting with FritzOS 7 and the much better approach
        $res = $self->phonebook->service->call('DeletePhonebookEntryUID',
            NewPhonebookID => $self->phonebook->id,
            NewPhonebookEntryUniqueID => $self->uniqueid,
        );

        if( $res->error and $res->error eq 'unknown action DeletePhonebookEntryUID' ) {
            $has_DeletePhonebookEntryUID = 0;
            $res = $self->delete_by_search();
        };

    } else {
        $res = $self->delete_by_search();
    };

    croak $res->error
        if $res->error;

    $res->data
}

sub save( $self ) {
    my $payload = XMLout(
        $self->build_structure,
        RootName => 'contact',
        XMLDecl  => 1,
        KeyAttr  => [],
    );

    $self->phonebook->service->call('SetPhonebookEntry',
        NewPhonebookID => $self->phonebook->id,
        NewPhonebookEntryID => $self->uniqueid,
        NewPhonebookEntryData => $payload,
    )->data
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Net-Fritz-Phonebook>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-Fritz-Phonebook>
or via mail to L<net-fritz-phonebook-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2017-2023 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
