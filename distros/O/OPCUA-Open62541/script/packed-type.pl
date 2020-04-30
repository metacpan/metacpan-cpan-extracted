#!/usr/bin/perl

use strict;
use warnings;

open(my $in, '<', "Open62541-packed.xsh")
    or die "Open 'Open62541-packed.xsh' for reading failed: $!";
my @types = map { m{^static UA_(\w+) XS_unpack_UA_\w+} } <$in>
    or die "No types found";

local $\ = "\n";
open(my $out, '>', "Open62541-packed-type.xsh")
    or die "Open 'Open62541-packed-type.xsh' for writing failed: $!";

foreach my $type (@types) {
    print $out <<"EOF";
static void
unpack_UA_$type(SV *sv, void *p)
{
	UA_$type *data = p;
	*data = XS_unpack_UA_$type(sv);
}
static void
pack_UA_$type(SV *sv, void *p)
{
	UA_$type *data = p;
	XS_pack_UA_$type(sv, *data);
}
EOF
}

print $out "typedef void (*packed_UA)(SV *, void *);";
print $out "static packed_UA unpack_UA_table[UA_TYPES_COUNT] = {";
foreach my $type (@types) {
	my $index = "UA_TYPES_". uc($type);
	print $out "	[$index] = unpack_UA_$type,";
}
print $out "};";

print $out "static packed_UA pack_UA_table[UA_TYPES_COUNT] = {";
foreach my $type (@types) {
	my $index = "UA_TYPES_". uc($type);
	print $out "	[$index] = pack_UA_$type,";
}
print $out "};";

close($out)
    or die "Close 'Open62541-packed-type.xsh' after writing failed: $!";
