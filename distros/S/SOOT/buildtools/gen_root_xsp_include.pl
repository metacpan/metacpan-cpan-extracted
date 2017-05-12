use strict;
use warnings;
use File::Spec;
use inc::latest 'ExtUtils::Typemap';

my $xsp_dir = 'ROOT_XSP';
my $xsp_dir_compile = File::Spec->catdir(File::Spec->updir, 'ROOT_XSP');

opendir my $dh, $xsp_dir or die $!;
open my $oh_xs, '>', 'rootclasses.xsinclude' or die $!;
open my $oh_h, '>', 'rootclasses.h' or die $!;
unlink('rootclasses.map');
my $typemap = ExtUtils::Typemap->new(file => 'rootclasses.map');

while(defined(my $file = readdir($dh))) {
  next if $file !~ /^(.+)\.xsp$/i;
  my $basename = $1;
  my $full = File::Spec->catfile($xsp_dir_compile, $file);
  print $oh_xs <<ENDXSCODE;

INCLUDE_COMMAND: \$^X -MExtUtils::XSpp::Cmd -e xspp -- -t ../typemap.xsp $full

ENDXSCODE
  print $oh_h <<ENDHCODE;
#include <$basename.h>
ENDHCODE
  
  $typemap->add_typemap(ctype => "$basename *", xstype => 'O_OBJECT');
}

$typemap->write();

