use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

eval q{ use Net::hostent };
is $@, '';

is gethost('bar')->name, 'foo.example.com', 'gethost(bar).name = foo.example.com';

done_testing;

__DATA__

@@ lib/Net/hostent.pm
package Net::hostent;

use strict;
use warnings;
use base qw( Exporter );
our @EXPORT = qw( gethost );

sub gethost
{
  my $input_name = shift;
  return unless $input_name =~ /^(foo|bar|baz|foo.example.com)$/;
  bless {}, 'Net::hostent';
}

sub name { 'foo.example.com' }
sub aliases { qw( foo.example.com foo bar baz ) }

1;
