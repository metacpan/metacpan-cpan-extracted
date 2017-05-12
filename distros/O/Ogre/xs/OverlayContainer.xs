MODULE = Ogre     PACKAGE = Ogre::OverlayContainer

void
OverlayContainer::addChild(elem)
    OverlayElement * elem

## xxx: C++ has another version where you can pass an OverlayElement*
## but why not use addChild? Also, what is "Impl"?
void
OverlayContainer::addChildImpl(cont)
    OverlayContainer * cont

void
OverlayContainer::removeChild(name)
     String  name

OverlayElement *
OverlayContainer::getChild(name)
     String  name

void
OverlayContainer::initialise()

##  ChildIterator 	getChildIterator (void)
## ChildContainerIterator 	getChildContainerIterator (void)

bool
OverlayContainer::isContainer()

bool
OverlayContainer::isChildrenProcessEvents()

void
OverlayContainer::setChildrenProcessEvents(val)
    bool  val

OverlayElement *
OverlayContainer::findElementAt(Real x, Real y)

void
OverlayContainer::copyFromTemplate(OverlayElement *templateOverlay)

OverlayElement *
OverlayContainer::clone(String instanceName)
