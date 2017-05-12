MODULE = Ogre     PACKAGE = Ogre::AxisAlignedBoxSceneQuery

void
AxisAlignedBoxSceneQuery::setBox(const AxisAlignedBox *box)
  C_ARGS:
    *box

## const AxisAlignedBox & AxisAlignedBoxSceneQuery::getBox()
