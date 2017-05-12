#!/usr/bin/perl
# Draw objects using ManualObject
# http://www.ogre3d.org/docs/api/html/classOgre_1_1ManualObject.html
# http://www.ogre3d.org/wiki/index.php/ManualObject
# http://www.ogre3d.org/wiki/index.php/Line3D
# http://www.ogre3d.org/wiki/index.php/Circle
#
# Note: sorry if the Perl gets a bit advanced in parts...
# I put a much simpler (though less flexible)
# version of drawing just a square after __END__.
#
# Note 2: you can move the camera around as normal
# with the arrow keys, Pg Up and Pg Down keys, and mouse
# (you can zoom in on the thick circle and hit 'r' to see the triangles)

package ManualObjectApp;

use strict;
use warnings;

use Ogre 0.35;
use Ogre::Math;
use Ogre::RenderOperation qw(:OperationType);

use Ogre::ExampleApplication;
@ManualObjectApp::ISA = qw(Ogre::ExampleApplication);

my %SHAPES = (
    'square' => sub { [
        [-100.0, -100.0, 0.0],
        [100.0, -100.0, 0.0],
        [100.0,  100.0, 0.0],
        [-100.0,  100.0, 0.0],
    ] },
    'line 3D' => sub { [
        [-80, -70, 50],
        [40, -20, 10],
    ] },
    'circle XY' => \&circle_xy,
    'circle thick' => \&circle_thick,
);

sub createScene {
    my ($self) = @_;

    $self->{mCamera}->setPosition(250, 150, 300);
    $self->{mCamera}->lookAt(0, 0, 0);

    foreach my $shape (keys %SHAPES) {
        $self->createObject($shape, $SHAPES{$shape}->());
    }
}

my %index_meth = (
    1 => 'index',
    3 => 'triangle',
    4 => 'quad',
);

# maybe I shouldn't've made this so "fancy"
# since it makes it harder to understand
sub createObject {
    # $vertices is an array ref of array refs
    my ($self, $name, $vertices, $index_tri_quad) = @_;
    $index_tri_quad = 1 unless defined $index_tri_quad;

    my $manual = $self->{mSceneMgr}->createManualObject($name);
    $manual->begin($self->getMaterialName,
                   $index_tri_quad == 1 ? OT_LINE_STRIP : OT_TRIANGLE_LIST);


    # position the vertices
    foreach my $vertex (@$vertices) {
        $manual->position(@$vertex);
    }

    # index the vertices
    foreach my $p (map {$index_tri_quad * $_} 0 .. (@$vertices / $index_tri_quad) - 1) {
        # this is $manual->index($p) or $manual->quad($p, $p + 1, ...) ...
        $manual->${\$index_meth{$index_tri_quad}}(map {$p + $_} 0 .. $index_tri_quad - 1);
    }
    $manual->index(0) if $index_tri_quad == 1;   # connect to beginning


    $manual->end();
    $self->{mSceneMgr}->getRootSceneNode->createChildSceneNode->attachObject($manual);
}

sub getMaterialName {
    my ($self) = @_;

    # "BaseWhiteNoLighting" comes from somewhere in the ogre Samples/ directory
    return "BaseWhiteNoLighting";

    # you could alternatively create a material manually, here "manual1Material"
    # (see the Line3D example - URL at top)
    # but I still need to wrap the `create` method
    #MaterialPtr myManualObjectMaterial = MaterialManager::getSingleton().create("manual1Material","debugger"); 
    #myManualObjectMaterial->setReceiveShadows(false); 
    #myManualObjectMaterial->getTechnique(0)->setLightingEnabled(true); 
    #myManualObjectMaterial->getTechnique(0)->getPass(0)->setDiffuse(0,0,1,0); 
    #myManualObjectMaterial->getTechnique(0)->getPass(0)->setAmbient(0,0,1); 
    #myManualObjectMaterial->getTechnique(0)->getPass(0)->setSelfIllumination(0,0,1); 
}

sub circle_xy {
    my $z = -40;
    my $radius = 70;
    my $accuracy = 5;
    my $pi = Ogre::Math->PI;

    my @vertices = ();
    for (my $theta = 0; $theta <= 2 * $pi; $theta += ($pi / ($radius * $accuracy))) {
        push @vertices, [$radius * cos($theta), $radius * sin($theta), $z];
    }

    return \@vertices;
}

# uses triangles for thickness
sub circle_thick {
    my $z = 10;
    my $radius = 50;
    my $thickness = 4;  # must be less than $radius..
    my $accuracy = 5;
    my $pi = Ogre::Math->PI;

    my @vertices = ();
    for (my $theta = 0; $theta <= 2 * $pi; $theta += ($pi / ($radius * $accuracy))) {
        # NB: order is important here; only one side of the circle is visible
        # so its triangles' normals have to be facing you
        # (I guess that's a property of the material?)
        push @vertices, [($radius - $thickness) * cos($theta),
                         ($radius - $thickness) * sin($theta),
                         $z];
        push @vertices, [($radius - $thickness) * cos($theta - $pi / ($radius * $accuracy)),
                         ($radius - $thickness) * sin($theta - $pi / ($radius * $accuracy)),
                         $z];
        push @vertices, [$radius * cos($theta - $pi / ($radius * $accuracy)),
                         $radius * sin($theta - $pi / ($radius * $accuracy)),
                         $z];
        push @vertices, [$radius * cos($theta),
                         $radius * sin($theta),
                         $z];
    }

    # the 2nd return value tells createObject() to use quad (4)
    # instead of index (the default == 1) or triangle (3)
    return (\@vertices, 4);
}


1;


package main;

ManualObjectApp->new->go();


__END__

#!/usr/bin/perl

package ManualObjectApp;

use strict;
use warnings;

use Ogre 0.35;
use Ogre::Math;
use Ogre::RenderOperation qw(:OperationType);

use Ogre::ExampleApplication;
@ManualObjectApp::ISA = qw(Ogre::ExampleApplication);

sub createScene {
    my ($self) = @_;

    my $manual = $self->{mSceneMgr}->createManualObject("square");

    $manual->begin("BaseWhiteNoLighting", OT_LINE_STRIP);

    $manual->position(-100.0, -100.0, 0.0);
    $manual->index(0);

    $manual->position(100.0, -100.0, 0.0);
    $manual->index(1);

    $manual->position(100.0,  100.0, 0.0);
    $manual->index(2);

    $manual->position(-100.0,  100.0, 0.0);
    $manual->index(3);

    $manual->index(0);   # close the loop

    $manual->end();

    $self->{mSceneMgr}->getRootSceneNode->createChildSceneNode->attachObject($manual);
}


1;


package main;

ManualObjectApp->new->go();
