use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use OpenGL ':all';
use OpenGL::Modern qw(:glewfunctions GLEW_OK glpSetAutoCheckErrors);

# Get an OpenGL context
glutInit();
glutInitDisplayMode(GLUT_RGBA);
glutInitWindowSize(1,1);
my $Window_ID = glutCreateWindow( "OpenGL::Shader test" );
glutHideWindow();
glpSetAutoCheckErrors(1);

require OpenGL::Shader;

my $types = OpenGL::Shader::GetTypes();
plan skip_all => "Your installation has no available shader support"
  if !keys %$types;

my %known = map +($_=>1), qw(ARB GLSL CG);

my $good = 0;
foreach my $type (sort keys(%$types))
{
  if (!$known{$type}) {
    fail '  Unknown shader type - '.$type.': '.$types->{$type}->{version};
    delete($types->{$type});
    next;
  }
  my $desc = $types->{$type};
  pass "$type v$desc->{version} - $desc->{description}";
  $good++;
}
die "No known shader types available" if !$good;

pass "at least one test";
test_shader('ARB');
test_shader('CG') if !OpenGL::glpCheckExtension('GL_EXT_Cg_shader');
test_shader('GLSL');

sub test_shader {
  my($test) = @_;
  my $lctype = lc($test);
  my $uctype = uc($test);
  return if !OpenGL::Shader::HasType($test);
  my $shdr = OpenGL::Shader->new($test);
  die "Unable to instantiate $uctype shader" if !$shdr;
  my $stat = $shdr->LoadFiles(map catfile("t", "$_.$lctype"), qw(fragment vertex));
  if ($stat) {
    fail "Unable to load $uctype shader: $stat";
    return;
  }
  pass "Loaded $uctype shader from: fragment.$lctype, vertex.$lctype";
}

glutDestroyWindow($Window_ID);

done_testing;
