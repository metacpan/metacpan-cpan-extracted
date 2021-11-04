#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.14;
use warnings;

open my $outh, ">", $ARGV[0] or
   die "Cannot write $ARGV[0] - $!\n";

local $/;

$outh->print( scalar do { <DATA> } );

$outh->print( scalar do {
   open my $in_h, "<", "include/object_pad.h" or
      die "Cannot open include/object_pad.h - $!";
   <$in_h> } );

__DATA__
package Object::Pad::ExtensionBuilder_data 0.56;

use v5.14;
use warnings;

# The contents of the "object_pad.h" file
my $object_pad_h = do {
   local $/;
   readline DATA;
};
sub OBJECT_PAD_H() { $object_pad_h }

0x55AA;

__DATA__
