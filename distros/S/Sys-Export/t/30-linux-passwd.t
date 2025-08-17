use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Fcntl 'S_IFREG';
use Sys::Export::Linux;

package Sys::Export::MockDst {
   sub new($class) { bless { files => {} }, $class }
   sub files($self) { $self->{files} }
   sub add($self, $attrs) { $self->{files}{$attrs->{name}}= $attrs; }
   sub finish($self)      {}
}

# my $pass_hash= crypt("test", q{$6$12345678$});   breaks on Win32, so just hard-code it
my $pass_hash= '$6$12345678$8Vkis/4wY9G5zD48pxdrbx3GyPCSsno5BigQ5pCfBXdoDBRxHNrLoKOWo9uI8DJ6i7vliOboPQaqxwn3knEOh.';

my $tmp= File::Temp->newdir;
my $dst= Sys::Export::MockDst->new();
my $exporter= Sys::Export::Linux->new(
   src => $tmp,
   dst => $dst,
   src_userdb => {
      auto_import => 0,
      users => {
         u1 => { uid => 1001, groups => ['users'], passwd => $pass_hash },
         u2 => { uid => 1002, groups => ['users','g3'] },
         u3 => { uid => 1003, groups => ['g2','g3'] },
         u4 => { uid => 1004, groups => ['g2'] },
      },
      groups => {
         users => { gid => 100 },
         g1 => { gid => 1001 },
         g2 => { gid => 1002 },
         g3 => { gid => 1003 },
      },
   }
);

$exporter->add([ file => 'a', '', { uid => 1001 }]);
$exporter->add([ file => 'b', '', { uid => 1003, gid => 100 }]);
$exporter->add([ file => 'c', '', { user => 'u1', group => 'g3' }]);

$exporter->add_passwd;
$exporter->finish;

my %passwd= $exporter->dst->{files}->%{'etc/passwd','etc/group','etc/shadow'};
is( \%passwd,
   {
      'etc/passwd' => hash {
         field uid => 0;
         field gid => 0;
         field mode => (S_IFREG | 0644);
         field data => <<~END;
         u1:x:1001:100:::
         u3:*:1003:1002:::
         END
         etc;
      },
      'etc/group'  => hash {
         field uid => 0;
         field gid => 0;
         field mode => (S_IFREG | 0644);
         field data => <<~END;
         users:*:100:
         g2:*:1002:
         g3:*:1003:u3
         END
         etc;
      },
      'etc/shadow' => hash {
         field uid => 0;
         field gid => 0;
         field mode => (S_IFREG | 0600);
         field data => <<~END;
         u1:${pass_hash}:::::::
         END
         etc;
      },
   },
   'passwd entries'
);
   


done_testing;
