# Adapted from file by ASKSH@cpan.org with RT#29604
use strict;
use warnings;

use Test::More tests => 2;

use Pod::WikiDoc;

sub _RTAB ($) {
   (my $a = $_[0]) =~ s/^\s+([^\s])/$1/xmsg; $a;
}

sub _QTAB ($) {
   (my $a = quotemeta $_[0]) =~ s/^\s+([^\s])/$1/xmsg;
   $a =~ s/\\(\s+)/$1/xmsg;
   my $s = q{\s*};
   $a =~ s{\s+}{$s}xmsg;
   return qr/$a/xms;
}

sub _PODQUOTE ($) {
   my ($pod) = @_;
   my %quotenames = (
      '<' => 'lt',
      '>' => 'gt',
      '/' => 'sol',
   );
   my %reverse_quotenames;
   while (my ($key, $value) = each %quotenames) {
      $reverse_quotenames{$value} = $key;
   }
   my $quotemap = join q{}, map { quotemeta $_ } keys %quotenames;
   $pod =~ s/E\<(.+?)\>/$reverse_quotenames{$1}/xmsg;
   my $re = "(?<!E)([$quotemap])";
   $pod =~ s/(?<!E)([$quotemap])/E<$quotenames{$1}>/xmsg;
   return $pod;
}

my $parser    = Pod::WikiDoc->new();

# Test =for passthrough.
my $T1 = _RTAB q{
   =begin wikidoc

   = Test =for passthrough.

   =for drmengele -> "10 cases of terpentine" <- [];

   =end wikidoc
};
my $ret            = $parser->convert($T1);
my $we_think_it_is = q{
   =pod

   =head1 Test =for passthrough.

   =for drmengele -> "10 cases of terpentine" <- [];
};
like( $ret, _QTAB $we_think_it_is,
   '=for passthrough'
);

# Test =begin/=end passthrough.
#

my $T2 = _RTAB '
   =begin wikidoc

   = Test =begin/=end passthrough.

   =begin graph

   node { fill: silver; }
   [ Multi ] --> [ Line ]

   =end graph

   =end wikidoc
';
$ret            = $parser->convert($T2);
$we_think_it_is = '
   =pod

   =head1 Test =beginE<sol>=end passthrough.

   =begin graph

   node { fill: silver; }
   [ Multi ] --> [ Line ]

   =end graph
';

like( $ret, _QTAB $we_think_it_is,
   '=begin/=end passthrough'
);
