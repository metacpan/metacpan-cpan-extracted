#!perl -w
use strict;
use Net::Fritz::Box;
use Net::Fritz::Phonebook;
use URI::URL;
use Data::Dumper;
use Encode;

our $VERSION = '0.05';

=head1 NAME

import-carddav.pl - import a VCard or CardDAV phone book to the Fritz!Box

=head1 SYNOPSIS

  import-carddav.pl [OPTIONS] [VCard filename or CardDAV phonebook URLs]

=head1 DESCRIPTION

Import a VCard .vcf file or a CardDAV phonebook to a Fritz!Box phonebook.

Existing contacts will not be overwritten.

=head1 ARGUMENTS

  --help        print documentation about Options and Arguments
  --version     print version number

=head1 OPTIONS

  --host        URL of the Fritz!Box, default is https://fritz.box
  --user        Username of the phone book owner on the Fritz!Box
  --pass        Password of the phone book owner on the Fritz!Box
  --phonebook   Name of the phone book on the Fritz!Box
                default is 'Telefonbuch'

=head1 EXAMPLE

  import-carddav.pl --host https://192.168.1.1:49443/ /user/me/contacts/*.vcf

  import-carddav.pl --host https://192.168.1.1:49443/ http://user:pass@contacts.home/

=cut

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'host:s' => \my $host,
    'u|user:s' => \my $username,
    'p|pass:s' => \my $password,
    'b|phonebook:s' => \my $phonebookname,
    'help!' => \my $opt_help,
    'version!' => \my $opt_version,
) or pod2usage(-verbose => 1) && exit;

$phonebookname ||= 'Telefonbuch';

pod2usage(-verbose => 1) && exit if $opt_help;
if( $opt_version ) {
    print $VERSION;
    exit;
};

my $fb = Net::Fritz::Box->new(
    username => $username,
    password => $password,
    upnp_url => $host,
);

#my $started = time;

my $device = $fb->discover;
if( my $error = $device->error ) {
    die $error
};

my $book = Net::Fritz::Phonebook->by_name( device => $device, name => $phonebookname );

if( ! $book) {
    my @phonebooks = Net::Fritz::Phonebook->list(device => $device);
    warn "Couldn't find phone book '$phonebookname'\n";
    warn "Known phonebooks on $host are\n";
    warn $_->name . "\n"
        for @phonebooks;
    exit 1;
};

# Cache what we have so we don't overwrite contacts with identical data.
my $entries = $book->entries;

#print sprintf "%d seconds taken to read current state", time - $started;

sub entry_exists {
    my( $entry ) = @_;

    #my $uid = $vcard->uid;
    #warn sprintf "[%s] (%s)\n", $uid, $vcard->VFN;

    # check uid
    # grep { $uid eq $_->uniqueid } @$entries;

    my %numbers = map {
        $_->content => 1,
    } @{ $entry->numbers };

    # check name or number
    # This means we cannot rename?!
    grep {
        my $c = $_;
            $c->name eq $entry->name
         or grep { $numbers{ $_->content } } @{ $c->numbers }
    } @$entries;
};

sub entry_is_different {
    my( $entry, $match ) = @_;

    my %numbers = map {
        $_->content => 1,
    } @{ $entry->numbers };

    #my %match_numbers = map {
    #    $_->content => 1,
    #} @{ $match->numbers };

    # check name or number
    # If one of the two is a mismatch, we are different
    #$match->name ne $entry->name
    #    or grep { $numbers{ $_->content } } @{ $c->numbers }
    #} @$entries;
};

sub add_contact {
    my( $vcard ) = @_;
    my $name = $vcard->VFN;
    my $contact = Net::Fritz::PhonebookEntry->new(
        name => $name,
        # I need a better unifier - the uniqueid gets assigned by the fb
        #uniqueid => $vcard->uid,
    );

    for my $number ($vcard->VPhones) {
        $contact->add_number($number->{value}, $number->{type});
    };

    if( 0+@{ $contact->numbers } and ! entry_exists( $contact )) {
        my $res = $book->add_entry($contact);
        die $res->error if $res->error;
    };
}

for my $item (@ARGV) {
    my @contacts;
    if( -f $item ) {
        require Net::CardDAVTalk::VCard;
        my $vcard = Net::CardDAVTalk::VCard->new_fromfile($item);
        push @contacts, $vcard;
    } else {
        require Net::CardDAVTalk;
        my $url = URI::URL->new( $item );

        my @userinfo = split /:/, $url->userinfo, 2;
        my $CardDAV = Net::CardDAVTalk->new(
            user => $userinfo[0],
            password => $userinfo[1],
            host => $url->host(),
            port => $url->port(),
            scheme => $url->scheme,
            url => $url->path,
            expandurl => 1,
            logger => sub { warn "DAV: @_" },
        );

        my $dav_addressbooks = $CardDAV->GetAddressBooks();
        for my $cal (@$dav_addressbooks) {
            print sprintf "%s (%s)\n", $cal->{name}, $cal->{path};

            if( $cal->{path} eq 'addresses' ) {
                my( $cards ) = $CardDAV->GetContacts( $cal->{path} );
                push @contacts, @$cards;
            }
        };
    };

    #my $fb_sync = time;
    for my $addr (@contacts) {
        add_contact( $addr );
    };
    #print sprintf "%d seconds taken to sync $url", time - $fb_sync;
};
