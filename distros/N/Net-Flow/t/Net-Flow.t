# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Flow.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('Net::Flow') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $packet = pack( "H*",
	"000A00B047C6277C00000000508E964200020034012C00068001FFFF0000768F00960004800500040000768F800AFFFF0000768F8003FFFF0000768F800B00010000768F000300340119000500008002FFFF0000768F8004FFFF0000768F800C00080000768F8008FFFF0000768F8009FFFF0000768F000001190020046E316471008743EDB73C8B4EE10A2F527074722056302E31000000012C0018057A7A317A7A47C6277C00000000000081000000"
);

my $InputTemplateArrayRef;
my ( $HeaderHashRef, $TemplateArrayRef, $FlowArrayRef, $ErrorsArrayRef ) = Net::Flow::decode( \$packet, $InputTemplateArrayRef );

ok( $HeaderHashRef->{VersionNum} == 10, "Version" );

my $t0 = $TemplateArrayRef->[0];
my $t1 = $TemplateArrayRef->[1];

ok( $t0->{TemplateId} == 300, "Template0 ID" );
ok( $t1->{TemplateId} == 281, "Template1 ID" );

ok( $t0->{Template}->[0]->{Id}     eq "30351.1",  "Template0 Field0 ID" );
ok( $t0->{Template}->[0]->{Length} eq 65535,      "Template0 Field0 Length" );
ok( $t1->{Template}->[2]->{Id}     eq "30351.12", "Template0 Field2 ID" );
ok( $t1->{Template}->[2]->{Length} == 8, "Template0 Field2 Length" );

ok( $FlowArrayRef->[0]->{'30351.2'} eq 'n1dq', "Flow0 30351.2" );
ok( $FlowArrayRef->[0]->{SetId} == 281, "Flow0 SetId" );
ok( $FlowArrayRef->[1]->{'30351.1'} eq 'zz1zz', "Flow1 30351.1" );
ok( $FlowArrayRef->[1]->{SetId} == 300, "Flow1 SetId" );


1;

__END__


# Local Variables: ***
# mode:CPerl ***
# cperl-indent-level:2 ***
# perl-indent-level:2 ***
# tab-width: 2 ***
# indent-tabs-mode: nil ***
# End: ***
#
# vim: ts=2 sw=2 expandtab
