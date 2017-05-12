# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Libnfc.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
use Data::Dumper;
BEGIN { use_ok('RFID::Libnfc') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use RFID::Libnfc ':all';
use RFID::Libnfc::Constants ':all';


my $pdi = nfc_connect();
if (!$pdi) { 
    print "No device! Skipping tests\n"; 
    exit 0;
}
nfc_initiator_init($pdi); 
# Drop the field for a while
nfc_configure($pdi, NDO_ACTIVATE_FIELD, 0);
# Let the reader only try once to find a tag
nfc_configure($pdi, NDO_INFINITE_SELECT, 0);
nfc_configure($pdi, NDO_HANDLE_CRC, 1);
nfc_configure($pdi, NDO_HANDLE_PARITY, 1);
# Enable field so more power consuming cards can power themselves up
nfc_configure($pdi, NDO_ACTIVATE_FIELD, 1);

printf("Reader:\t%s\n", $pdi->acName);

# Try to find a MIFARE Classic tag
my $pti = RFID::Libnfc::Target->new();
$pti->nm->nmt(IM_ISO14443A_106);
if (!nfc_initiator_select_passive_target($pdi, $pti->nm, 0, 0, $pti))
{
    printf("Error: no tag was found\n");
    nfc_disconnect($pdi);
    exit 0;
} else {
    printf("Card:\tNFC ISO14443A found\n");
}

# we are intereseted to the mifare part of the nfc_target_info_t union
my $mifare = $pti->nti->nai; 
# Test card type
printf("Type:\t%s\n",
     ($mifare->btSak==0x00)?"ULTRA":
     ($mifare->btSak==0x08)?"1K":
     ($mifare->btSak==0x09)?"MINI":
     ($mifare->btSak==0x18)?"4K":
     ($mifare->btSak==0x20)?"DESFIRE":
     ($mifare->btSak==0x28)?"JCOP30":
     ($mifare->btSak==0x38)?"JCOP40":
     ($mifare->btSak==0x88)?"OYSTER":
     ($mifare->btSak==0x98)?"GEMPLUS MPCOS":
     "unknown");

printf("ATQA:\t%x,%x\n", unpack("CC", $mifare->abtAtqa));

my $uidLen = $mifare->szUidLen;
my @uid = unpack("C".$uidLen, $mifare->abtUid);
printf("UID:\t". "%x " x $uidLen ."\n", @uid);

printf("SAK:\t%x\n", $mifare->btSak);

if ($mifare->uiAtsLen) {
    my $atsLen = $mifare->uiAtsLen;
    my @ats = unpack("C".$atsLen, $mifare->abtAts);
    printf("ATS:\t". "%x " x $atsLen ."\n", @ats);
}
  
nfc_disconnect($pdi);

