MODULE = Ogre     PACKAGE = Ogre::ControllerReal

## void Controller::setSource(const SharedPtr< ControllerValue< T > > &src)

## const SharedPtr< ControllerValue<T> > & Controller::getSource()

## void Controller::setDestination(const SharedPtr< ControllerValue< T > > &dest)

## const SharedPtr< ControllerValue<T> > & Controller::getDestination()

bool
ControllerReal::getEnabled()

void
ControllerReal::setEnabled(bool enabled)

## void Controller::setFunction(const SharedPtr< ControllerFunction< T > > &func)

## const SharedPtr< ControllerFunction<T> > & Controller::getFunction()

void
ControllerReal::update()
