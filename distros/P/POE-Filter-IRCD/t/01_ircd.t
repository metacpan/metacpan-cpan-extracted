use Test::More tests => 11;
BEGIN { use_ok('POE::Filter::IRCD') };

my $filter = POE::Filter::IRCD->new();

isa_ok( $filter, 'POE::Filter::IRCD' );

my $original = ':test!test@test.test PRIVMSG #Test :This is a test case';
foreach my $irc_event ( @{ $filter->get( [ $original ] ) } ) {
  ok( $irc_event->{prefix} eq 'test!test@test.test', 'Prefix Test' );
  ok( $irc_event->{params}->[0] eq '#Test', 'Params Test One' );
  ok( $irc_event->{params}->[1] eq 'This is a test case', 'Params Test Two' );
  ok( $irc_event->{command} eq 'PRIVMSG', 'Command Test');
  foreach my $parsed ( @{ $filter->put( [ $irc_event ] ) } ) {
	ok( $parsed eq $original, 'Self Test' );
  }
}

my $filter2 = POE::Filter::IRCD->new( colonify => 1 );

isa_ok( $filter2, 'POE::Filter::IRCD' );

my $original2 = ':test!test@test.test PRIVMSG #Test :Test';

foreach my $irc_event ( @{ $filter2->get( [ $original2 ] ) } ) {
  foreach my $parsed ( @{ $filter2->put( [ $irc_event ] ) } ) {
	ok( $parsed eq $original2, 'Self Test' );
  }
}

my $filter3 = $filter2->clone();

isa_ok( $filter3, 'POE::Filter::IRCD' );

foreach my $irc_event ( @{ $filter3->get( [ $original2 ] ) } ) {
  foreach my $parsed ( @{ $filter3->put( [ $irc_event ] ) } ) {
	ok( $parsed eq $original2, 'Self Test' );
  }
}
