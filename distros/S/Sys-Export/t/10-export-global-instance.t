use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );

package Sys::Export::MockDst {
   sub new($class) { bless { method_calls => [] }, $class }
   sub method_calls($self) { $self->{method_calls} }
   sub add($self, $attrs) { push @{$self->{method_calls}}, [ 'add', $attrs ] }
   sub finish($self)      { push @{$self->{method_calls}}, [ 'finish' ] }
}

my $src= __FILE__ =~ s,[^\\/]+$,,r;
my $dst= Sys::Export::MockDst->new;
ok( eval <<~'PL', 'example script' ) or diag $@;
   use Sys::Export -type => 'Unix', -src => $src, -dst => $dst;
   add '10-export-global-instance.t';
   add 'lib/Test2AndUtils.pm';
   skip find qr/\.t$/;
   add '04-stat-shorthand.t'; # should get ignored
   finish;
   PL

is($dst->method_calls,
   [ [ add => hash { field name => '10-export-global-instance.t'; etc; } ],
     [ add => hash { field name => 'lib'; etc; } ],
     [ add => hash { field name => 'lib/Test2AndUtils.pm'; etc; } ],
     [ 'finish' ],
   ], 'destination file list' );

done_testing;
