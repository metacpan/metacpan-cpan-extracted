use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use OpenGL ':all';

# Get an OpenGL context
glutInit();
glutInitDisplayMode(GLUT_RGBA);
glutInitWindowSize(1,1);
my $Window_ID = glutCreateWindow( "OpenGL::Shader test" );
glutHideWindow();

require OpenGL::Shader;

my $types = OpenGL::Shader::GetTypes();
plan skip_all => "Your installation has no available shader support"
  if !keys %$types;

#3 Get Shader Types
my $hasARB = 0;
my $hasGLSL = 0;
my $hasCG = 0;

my $good = 0;
foreach my $type (sort keys(%$types))
{
  if ($type eq 'ARB') {
    $hasARB = 1;
  } elsif ($type eq 'GLSL') {
    $hasGLSL = 1;
  } elsif ($type eq 'CG') {
    $hasCG = 1;
  } else {
    fail '  Unknown shader type - '.$type.': '.$types->{$type}->{version};
    delete($types->{$type});
    next;
  }
  pass '  '.$type.' v'.$types->{$type}{version}.' - '.
    $types->{$type}{description};
  $good++;
}
die "No known shader types available" if !$good;

pass "at least one test";
test_shader('ARB');
test_shader('CG');
test_shader('GLSL');

sub test_shader {
  my($test) = @_;
  my $lctype = lc($test);
  my $uctype = uc($test);
  return if !OpenGL::Shader::HasType($test);
  my $shdr = OpenGL::Shader->new($test);
  die "Unable to instantiate $uctype shader" if !$shdr;
  my $stat = $shdr->LoadFiles(map catfile("t", $_), "fragment.$lctype","vertex.$lctype");
  if ($stat) {
    fail "Unable to load $uctype shader: $stat";
    return;
  }
  pass "Loaded $uctype shader from: fragment.$lctype, vertex.$lctype";
}

glutDestroyWindow($Window_ID);

done_testing;
