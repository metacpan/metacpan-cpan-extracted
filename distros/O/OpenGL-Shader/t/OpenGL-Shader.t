#!/usr/bin/perl -w
use strict;
use OpenGL(':all');


# Init tests
my $t = new MyTests(6,'Testing OpenGL::Shader');


#1 Test OpenGL version
my $pogl_ver = $OpenGL::VERSION;
my $has_pogl = $pogl_ver ge '0.55';
$t->bail("Requires OpenGL v0.55 or newer to use; v$pogl_ver installed") if (!$has_pogl);
$t->ok("Installed: OpenGL v$pogl_ver");


# Get an OpenGL context
eval {glutInit(); 1} or $t->bail("This test requires GLUT");
glutInitDisplayMode(GLUT_RGBA);
glutInitWindowSize(1,1);
my $Window_ID = glutCreateWindow( "OpenGL::Shader test" );
glutHideWindow();


#2 Get module version
my $mod_ver;
my $exec = qq
{
  use OpenGL\::Shader;
  \$mod_ver = \$OpenGL::Shader::VERSION;
};
eval($exec);
$t->bail("OpenGL::Shader failed to load: $@") if ($@ || !$mod_ver);
$t->ok("OpenGL::Shader module loaded: v$mod_ver");


#3 Get Shader Types
my $hasARB = 0;
my $hasGLSL = 0;
my $hasCG = 0;

my $types = OpenGL::Shader::GetTypes();
if (!scalar(%$types))
{
  $t->done("Your installation has no available shader support");
  exit 0;
}

my $good = 0;
my $unk = 0;
$t->status("Available shader types:");
foreach my $type (sort keys(%$types))
{
  if ($type eq 'ARB')
  {
    $hasARB = 1;
  }
  elsif ($type eq 'GLSL')
  {
    $hasGLSL = 1;
  }
  elsif ($type eq 'CG')
  {
    $hasCG = 1;
  }
  else
  {
    $t->status('  Unknown shader type - '.$type.': '.$types->{$type}->{version});
    delete($types->{$type});
    $unk++;
    next;
  }

  $t->status('  '.$type.' v'.$types->{$type}->{version}.' - '.
    $types->{$type}->{description});
  $good++;
}
$t->bail("No known shader types available") if (!$good);

if ($unk)
{
  $t->fail("$unk unknown shader type(s) reported");
}
else
{
  $t->ok("$good shader type(s) reported");
}


#4 Test ARB
test_shader('ARB');


#5 Test GLSL
test_shader('GLSL');


#6 Test CG
test_shader('CG');


$t->done();
glutDestroyWindow($Window_ID);
exit 0;




sub test_shader
{
  my($test) = @_;
  my $lctype = lc($test);
  my $uctype = uc($test);

  my $info = OpenGL::Shader::HasType($test);

  if (!$info)
  {
    $t->skip("$uctype shader test");
    return;
  }

  my $shdr = new OpenGL::Shader($test);
  $t->bail("Unable to instantiate $uctype shader") if (!$shdr);

  my $ver = $info->{version};
  my $desc = $info->{description};
  $t->status("Instantiated $uctype v$ver");

  my $stat = $shdr->LoadFiles("fragment.$lctype","vertex.$lctype");
  if ($stat)
  {
    $t->fail("Unable to load $uctype shader: $stat");
    return;
  }

  # Done
  $t->ok("Loaded $uctype shader from: fragment.$lctype, vertex.$lctype");
}





package MyTests;
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {count=>0};
  bless($self,$class);

  my($tests,$title) = @_;
  $self->{tests} = $tests;
  print "1..$tests\n";
  $self->status("\n________________________________________");
  $self->status($title);
  $self->status("----------------------------------------");

  return $self;
}
sub status
{
  my($self,$msg) = @_;
  print STDERR "$msg\n";
}
sub ok
{
  my($self,$msg) = @_;
  $self->status("* ok: $msg");
  print 'ok '.++$self->{count}."\n";
}
sub skip
{
  my($self,$msg) = @_;
  $self->status("* skip: $msg");
  print 'ok '.++$self->{count}." \# skip $msg\n";
}
sub fail
{
  my($self,$msg) = @_;
  $self->status("* fail: $msg");
  print 'not ok '.++$self->{count}."\n";
}
sub bail
{
  my($self,$msg) = @_;
  $self->status("* bail: $msg\n");
  print "Bail out!\n";
  exit 0;
}
sub done
{
  my($self,$msg) = @_;

  for (my $c=$self->{count}; $self->{count} < $self->{tests}; $c++)
  {
    $self->skip('#'.($c+1)." - $msg");
  }

  $self->status("________________________________________");
}

__END__
