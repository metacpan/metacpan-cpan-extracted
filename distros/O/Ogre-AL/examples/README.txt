This directory contains examples of using Ogre::AL.

To run the examples, you need to have Ogre and OIS installed.

You also need (at least) two resource-related files:

1) plugins.cfg : this might be a symlink to a system-wide file,
for example on Ubuntu I did this:

  ln -s /etc/OGRE/plugins.cfg

2) resources.cfg : an example from OgreAL 0.2.5 has been included
already. Be sure that the file paths point to where your media
files are; for example, I copy the OgreAL Demos/Media/ files
into the examples directory like this:

  mkdir -p Demos/Media
  cp -r /tmp/OgreAL-Eihort/Demos/Media/* Demos/Media/

(OgreAL-Eihort is a svn checkout - see README.txt - the Demos/Media/
file is currently about 26MB, so not distributable on CPAN)
and in resources.cfg all the entries look something like this:

  FileSystem=Demos/Media/Materials/Scripts
  Zip=Demos/Media/Materials/Textures/cubemapsJS.zip
  ...

You can also use relative or absolute path names.


Here are brief descriptions of the examples.
They are each put in a single file, though they would normally
be put in several files. There may be more information
at the top of each file.
Note: these run for me but when exiting they crash.

- basic.pl : port of the Basic demo in the OgreAL distribution,
  shows how to stop and start sounds, and how the sounds are
  attached to nodes in the 3D scene

- directional.pl : port of the Directional demo in the OgreAL distribution,
  a rotating siren

- doppler.pl : port of the Doppler demo in the OgreAL distribution,
  a car going in a circle (the doppler effect doesn't seem to work for me
  though, not sure if it's just my drivers or what)
  Note: this requires Ogre::BetaGUI.

- multichannel.pl : port of the MultiChannel demo in the OgreAL distribution,
  just plays an .ogg file from left and right speakers

