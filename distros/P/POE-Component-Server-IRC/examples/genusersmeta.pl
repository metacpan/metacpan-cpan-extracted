use 5.012;
use strict;
use warnings;
use Acme::MetaSyntactic;

my @suffix = qw[uk com org fr ru ch net in usa];
my $cnt = scalar @suffix;
my $mask = { };
my %nicks;

foreach my $theme ( qw[legobatman legoharrypotter legopiratesofthecaribbean legocityundercover legostarwarstheforceawakens] ) {
foreach my $tang ( metaname($theme,200) ) {
  if ( !keys %$mask ) {
    $tang =~ s!^professor_!!i;
    $tang =~ s!^The_!!i;
    $tang =~ s!^Black_!!i;
    my $nick = substr $tang, 0, 9;
    next if $nicks{$nick};
    $nicks{$nick}++;
    $mask->{nick} = $nick;
    next;
  }
  if ( $mask->{nick} && !$mask->{user} && !$mask->{host} ) {
    $mask->{user} = substr $tang, 0, 12; $mask->{user} =~ s!_!!g;
    next;
  }
  if ( $mask->{nick} && $mask->{user} && !$mask->{host} ) {
    $tang =~ s!_!.!g;
    $mask->{host} = join '.', $tang, $suffix[int(rand($cnt))];
    say lc ($mask->{nick} . '!' . $mask->{user} . '@' . $mask->{host});
    $mask = {};
    next;
  }
}
}
