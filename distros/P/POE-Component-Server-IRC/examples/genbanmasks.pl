use 5.012;
use strict;
use warnings;
use Acme::MetaSyntactic;

my @suffix = qw[uk com org fr ru ch net in usa];
my $cnt = scalar @suffix;
my $mask = { };

foreach my $tang ( metaname('legoharrypotter',1000) ) {
  if ( !keys %$mask ) {
    $tang =~ s!^professor_!!;
    $mask->{nick} = substr $tang, 0, 9;
    next;
  }
  if ( $mask->{nick} && !$mask->{user} && !$mask->{host} ) {
    $mask->{user} = substr $tang, 0, 12; $mask->{user} =~ s!_!!g;
    next;
  }
  if ( $mask->{nick} && $mask->{user} && !$mask->{host} ) {
    $tang =~ s!_!.!g;
    $mask->{host} = join '.', $tang, $suffix[int(rand($cnt))];
    say $mask->{nick} . '!' . $mask->{user} . '@' . $mask->{host};
    $mask = {};
    next;
  }
}
