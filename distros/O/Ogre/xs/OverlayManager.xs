MODULE = Ogre     PACKAGE = Ogre::OverlayManager

static OverlayManager *
OverlayManager::getSingletonPtr()

Overlay *
OverlayManager::create(name)
    String  name

Overlay *
OverlayManager::getByName(name)
    String  name

# there is another version passing the Overlay*
void
OverlayManager::destroy(name)
    String  name

void
OverlayManager::destroyAll()

bool
OverlayManager::hasViewportChanged()

int
OverlayManager::getViewportHeight()

int
OverlayManager::getViewportWidth()

Real
OverlayManager::getViewportAspectRatio()

OverlayElement *
OverlayManager::createOverlayElement(String typeName, String instanceName, bool isTemplate=false)

## note: added to Perl, same as createOverlayElement
OverlayContainer *
OverlayManager::createOverlayContainer(String typeName, String instanceName, bool isTemplate=false)
  CODE:
    RETVAL = static_cast<OverlayContainer*>(THIS->createOverlayElement(typeName, instanceName, isTemplate));
  OUTPUT:
    RETVAL

## note: added to Perl, same as createOverlayElement
TextAreaOverlayElement *
OverlayManager::createTextAreaOverlayElement(String typeName, String instanceName, bool isTemplate=false)
  CODE:
    RETVAL = static_cast<TextAreaOverlayElement*>(THIS->createOverlayElement(typeName, instanceName, isTemplate));
  OUTPUT:
    RETVAL

## note: added to Perl, same as createOverlayElement
PanelOverlayElement *
OverlayManager::createPanelOverlayElement(String typeName, String instanceName, bool isTemplate=false)
  CODE:
    RETVAL = static_cast<PanelOverlayElement*>(THIS->createOverlayElement(typeName, instanceName, isTemplate));
  OUTPUT:
    RETVAL

## note: added to Perl, same as createOverlayElement
## but with a static_cast<BorderPanelOverlayElement*>
BorderPanelOverlayElement *
OverlayManager::createBorderPanelOverlayElement(String typeName, String instanceName, bool isTemplate=false)
  CODE:
    RETVAL = static_cast<BorderPanelOverlayElement*>(THIS->createOverlayElement(typeName, instanceName, isTemplate));
  OUTPUT:
    RETVAL


OverlayElement *
OverlayManager::getOverlayElement(name, isTemplate=false)
    String  name
    bool    isTemplate

# there is another version passing OverlayElement*
void
OverlayManager::destroyOverlayElement(instanceName, isTemplate=false)
    String  instanceName
    bool    isTemplate

void
OverlayManager::destroyAllOverlayElements(isTemplate=false)
    bool  isTemplate

# ....

bool
OverlayManager::isTemplate(strName)
    String strName
