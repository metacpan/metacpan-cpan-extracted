Setup required to run examples

This directory contains examples of using the Perl bindings
for OGRE. To run the examples, you need to have two config files
in the current directory: plugins.cfg and resources.cfg.

plugins.cfg might be a pointer to a system-wide file;
for example, on Ubuntu you should `ln -s /usr/share/OGRE/plugins.cfg`.

[XXX: needs updated for 1.7.2]
resources.cfg is taken from the Samples/Common/bin directory in OGRE,
but I put it here also. For resources.cfg, you need to make sure
it points to the Samples directory from OGRE 1.6.
(It's important to point to 1.6 media, not 1.4, because some
of the syntax has changed. You can edit resources.cfg to point
wherever you want.) If you checked out Ogre's source from subversion
as mentioned in README.txt, then create a symlink to the Samples
directory like this:

  ln -s $HOME/ogre/src/ogre/v1-6/Samples


Brief descriptions of the examples

- robot.pl: very minimal, just shows a robot that's been rotated
  and scaled a bit (taken from one of the basic OGRE tutorials;
  if you're not familiar with the tutorials, probably should do
  them before trying this)

- ninja.pl: another minimal demo, this time using OIS to handle input
  (just exiting the application when ESC is pressed), and the robot
  is replaced by a cool-looking ninja under different lighting

- listeningninja.pl: same cool ninja scene, but showing how to implement
  a FrameListener to handle user input (e.g. keyboard)

- buffered.pl: demo of buffered input handling, this implements OGRE's
  "Basic Tutorial 5"

# NB: sky.pl, darksky.pl, and terrain.pl aren't currently working
# because they used TerrainSceneManager, which was removed in 1.8.0
# and I haven't fixed them yet
# http://www.ogre3d.org/tikiwiki/tiki-index.php?page=ByatisNotes
#- sky.pl: demo of Terrain, Sky, and Fog, this implements OGRE's
#  "Basic Tutorial 3"
#
#- darksky.pl: same as sky.pl but more evil-looking
#
#- terrain.pl: implementing OGRE's "Terrain" sample app, this demos
#  using RaySceneQuery to maintain the camera at a fixed distance
#  above a terrain (if you've played "Medieval: Total War", it's like
#  moving the camera over the 3D-battle terrains).

- animate.pl: watch the robot walk
  (note: this is still a little incomplete, so the robot will "moonwalk"
   once he reaches the first waypoint - I have to wrap a few more Node
   and Quaternion methods, and fix some overloaded operators)

#- gtk2robot.pl, wx.pl: NOT WORKING YET, but if it were it should
#  show how to make gtk2 and wxPerl work with Ogre.

- cameratrack.pl: demo of animation tracks and camera auto-tracking,
  implements OGRE's "CameraTrack" sample application

- particleFX.pl: pretty particle effects demo, implements OGRE's
  "ParticleFX" sample application

- skeletalanim.pl: implements OGRE's "SkeletalAnimation" sample application
  (very cool with the ladies sneaking around :)

- lighting.pl: OGRE's "Lighting" sample app, shows how to use ControllerValue
  and ControllerFunction interfaces, as well as using RibbonTrails
  and animations (note: this is still incomplete, though it works fine)

- manualobject.pl: use ManualObject to draw arbitrary shapes
  (taken from several wiki articles)

#- sdlrobot.pl: render Ogre in an SDL-Perl application
# needs updating
