#line 1
package Module::Install::ReadmePodFromPod;
use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.01';

sub readme_pod_from {
  my $self = shift;
  return unless $Module::Install::AUTHOR;
  my $file = shift || return;

  require Pod::Perldoc::ToPod;
  open my $out, '>', 'README.pod' or die "can not create README.pod file: $!";
  my $parser = Pod::Perldoc::ToPod->new;
  $parser->parse_from_file($file, $out);
  return 1;
}

'let README.pod render Pod as ... Pod!';
__END__

#line 75
