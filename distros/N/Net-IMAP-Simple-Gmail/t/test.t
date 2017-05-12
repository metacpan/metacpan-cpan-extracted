use Test::More qw{no_plan};

BEGIN {
  use_ok('Net::IMAP::Simple::Gmail');
}

can_ok('Net::IMAP::Simple::Gmail', ('new'));

my $imap = Net::IMAP::Simple::Gmail->new('imap.gmail.com');
isa_ok($imap, 'Net::IMAP::Simple::Gmail');

