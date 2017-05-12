package Ogre::Root;

use strict;
use warnings;


1;

__END__
=head1 NAME

Ogre::Root

=head1 SYNOPSIS

  use Ogre;
  use Ogre::Root;
  # (for now see examples/README.txt)

=head1 DESCRIPTION

See the online API documentation at
 L<http://www.ogre3d.org/docs/api/html/classOgre_1_1Root.html>

B<Note:> this Perl binding is currently I<experimental> and subject to API changes.

=head1 CLASS METHODS

=head2 Ogre::Root->new(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item Root *

=back

=head2 Ogre::Root->DESTROY()

This method is called automatically; don't call it yourself.

=head1 INSTANCE METHODS

=head2 $obj->saveConfig()

I<Returns>

=over

=item void

=back

=head2 $obj->restoreConfig()

I<Returns>

=over

=item bool

=back

=head2 $obj->showConfigDialog()

I<Returns>

=over

=item bool

=back

=head2 $obj->addRenderSystem($RenderSystem *newRend)

I<Parameter types>

=over

=item $RenderSystem *newRend : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderSystemByName($String name)

I<Parameter types>

=over

=item $String name : (no info available)

=back

I<Returns>

=over

=item RenderSystem *

=back

=head2 $obj->setRenderSystem($RenderSystem *system)

I<Parameter types>

=over

=item $RenderSystem *system : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderSystem()

I<Returns>

=over

=item RenderSystem *

=back

=head2 $obj->initialise($autoCreateWindow, ...)

I<Parameter types>

=over

=item $autoCreateWindow : bool

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item RenderWindow *

=back

=head2 $obj->isInitialised()

I<Returns>

=over

=item bool

=back

=head2 $obj->createSceneManager(...)

I<Parameter types>

=over

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item SceneManager *

=back

=head2 $obj->destroySceneManager($sm)

I<Parameter types>

=over

=item $sm : SceneManager *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getSceneManager($instanceName)

I<Parameter types>

=over

=item $instanceName : String

=back

I<Returns>

=over

=item SceneManager *

=back

=head2 $obj->getTextureManager()

I<Returns>

=over

=item TextureManager *

=back

=head2 $obj->getMeshManager()

I<Returns>

=over

=item MeshManager *

=back

=head2 $obj->getErrorDescription($errorNumber)

I<Parameter types>

=over

=item $errorNumber : long

=back

I<Returns>

=over

=item String

=back

=head2 $obj->addFrameListener($perlListener)

I<Parameter types>

=over

=item $perlListener : SV *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->removeFrameListener($perlListener)

I<Parameter types>

=over

=item $perlListener : SV *

=back

I<Returns>

=over

=item void

=back

=head2 $obj->queueEndRendering()

I<Returns>

=over

=item void

=back

=head2 $obj->startRendering()

I<Returns>

=over

=item void

=back

=head2 $obj->renderOneFrame()

I<Returns>

=over

=item bool

=back

=head2 $obj->shutdown()

I<Returns>

=over

=item void

=back

=head2 $obj->addResourceLocation($String name, $String locType, $String groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, $bool recursive=false)

I<Parameter types>

=over

=item $String name : (no info available)

=item $String locType : (no info available)

=item $String groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME : (no info available)

=item $bool recursive=false : (no info available)

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getAutoCreatedWindow()

I<Returns>

=over

=item RenderWindow *

=back

=head2 $obj->createRenderWindow($name, $width, $height, $fullScreen, ...)

I<Parameter types>

=over

=item $name : String

=item $width : unsigned int

=item $height : unsigned int

=item $fullScreen : bool

=item ... : this varies... (sorry, look in the .xs file)

=back

I<Returns>

=over

=item RenderWindow *

=back

=head2 $obj->detachRenderTarget($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getRenderTarget($name)

I<Parameter types>

=over

=item $name : String

=back

I<Returns>

=over

=item RenderTarget *

=back

=head2 $obj->loadPlugin($pluginName)

I<Parameter types>

=over

=item $pluginName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->unloadPlugin($pluginName)

I<Parameter types>

=over

=item $pluginName : String

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getCurrentFrameNumber()

I<Returns>

=over

=item unsigned long

=back

=head2 $obj->clearEventTimes()

I<Returns>

=over

=item void

=back

=head2 $obj->setFrameSmoothingPeriod($period)

I<Parameter types>

=over

=item $period : Real

=back

I<Returns>

=over

=item void

=back

=head2 $obj->getFrameSmoothingPeriod()

I<Returns>

=over

=item Real

=back

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
