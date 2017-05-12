# Palm-SMS.t - Palm::SMS test file
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl
# Palm-SMS.t'
#
# $Id: Palm-SMS.t,v 1.1 2009/01/10 16:17:59 drhyde Exp $

use Test::More;

BEGIN {
  @expected_fields =
    (
     { 'smsh'      => 'SMSh',
       'id'        => 5117162,
       'category'  => 1,
       'name'      => 'N' x 7,
       'firstName' => 'F' x 5,
       'phone'     => '+012345678901',
       'folder'    => 1, # Sent
       'timestamp' => 1096772944,
       'text'      => 'T' x 146,
     },
     { 'smsh'      => 'SMSh',
       'id'        => 5117163,
       'category'  => 0,
       'name'      => 'N' x 7,
       'firstName' => 'F' x 5,
       'phone'     => '+012345678901',
       'folder'    => 0, # Inbox
       'timestamp' => 1096804711,
       'text'      => 'T' x 157,
     },
    );

  plan tests => 9
              + ($#expected_fields + 1) * keys %{$expected_fields[0]};
};


# Module load
BEGIN { use_ok('Palm::PDB'); };
BEGIN { use_ok('Palm::SMS'); };

# Module dependencies
require_ok('Palm::Raw');

# Module methods
can_ok('Palm::SMS', qw(import new new_Record ParseRecord PackRecord));

# ISA
my $pdb = new Palm::PDB;
isa_ok($pdb, 'Palm::PDB');

# Load sample PDB
#
# sample.pdb file wasn't created from scratch.  It is a real SMS PDB
# file manipulated with Palm::SMS as little as possible.  Only two
# text messages of the original PDB file have been kept, deleteing the
# others via delete().  Of these two text messages, name, firstName,
# phone, and text fields have been masked with meaningless values
# while preserving their original length.  Doing this way, I hope
# unknown bits have been preserved.
#
# Note that Load() dies in case of errors
my $sample_pdb = 't/sample.pdb';
$pdb->Load($sample_pdb);
ok(1, "$sample_pdb Load()ed");

# PDB fields
is($pdb->{name},     'SMS Messages',  'PDB Name field');
is($pdb->{type},     'DATA',          'PDB DATA field');
is($pdb->{creator},  'SMS!',          'PDB Creator field');

# Record fields
for (my $i = 0; $i <= $#{$pdb->{records}}; $i++) {
  my $record = $pdb->{records}[$i];

  foreach my $field (keys %{$expected_fields[$i]}) {
    is($record->{$field},
       $expected_fields[$i]{$field},
       "Record: $i, field: $field");
  }

}
