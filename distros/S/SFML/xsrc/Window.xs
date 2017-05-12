MODULE = SFML		PACKAGE = SFML::Window::Context

Context*
Context::new()

void
Context::DESTROY()

bool
Context::setActive(active)
	bool active

MODULE = SFML		PACKAGE = SFML::Window::ContextSettings

ContextSettings*
ContextSettings::new(...)
	CODE:
		//STACK_DUMP
		RETVAL = new ContextSettings();
		ARG_P_BEGIN
			ARG_P_OPTION("depthBits")
				RETVAL->depthBits = SvIV(ARG_P);
			ARG_P_OPTION_END
			ARG_P_OPTION("stencilBits")
				RETVAL->stencilBits = SvIV(ARG_P);
			ARG_P_OPTION_END
			ARG_P_OPTION("antialiasingLevel")
				RETVAL->antialiasingLevel = SvIV(ARG_P);
			ARG_P_OPTION_END
			ARG_P_OPTION("majorVersion")
				RETVAL->majorVersion = SvIV(ARG_P);
			ARG_P_OPTION_END
			ARG_P_OPTION("minorVersion")
				RETVAL->minorVersion = SvIV(ARG_P);
			ARG_P_OPTION_END
		ARG_P_END
	OUTPUT:
		RETVAL

void
ContextSettings::DESTROY()

unsigned int
ContextSettings::getDepthBits()
	CODE:
		RETVAL = THIS->depthBits;
	OUTPUT:
		RETVAL

unsigned int
ContextSettings::getStencilBits()
	CODE:
		RETVAL = THIS->stencilBits;
	OUTPUT:
		RETVAL

unsigned int
ContextSettings::getAntialiasingLevel()
	CODE:
		RETVAL = THIS->antialiasingLevel;
	OUTPUT:
		RETVAL

unsigned int
ContextSettings::getMajorVersion()
	CODE:
		RETVAL = THIS->majorVersion;
	OUTPUT:
		RETVAL

unsigned int
ContextSettings::getMinorVersion()
	CODE:
		RETVAL = THIS->minorVersion;
	OUTPUT:
		RETVAL


void
ContextSettings::setDepthBits(depthBits)
	unsigned int depthBits
	CODE:
		THIS->depthBits = depthBits;

void
ContextSettings::setStencilBits(stencilBits)
	unsigned int stencilBits
	CODE:
		THIS->stencilBits = stencilBits;

void
ContextSettings::setAntialiasingLevel(antialiasingLevel)
	unsigned int antialiasingLevel
	CODE:
		THIS->antialiasingLevel = antialiasingLevel;

void
ContextSettings::setMajorVersion(majorVersion)
	unsigned int majorVersion
	CODE:
		THIS->majorVersion = majorVersion;

void
ContextSettings::setMinorVersion(minorVersion)
	unsigned int minorVersion
	CODE:
		THIS->minorVersion = minorVersion;

MODULE = SFML		PACKAGE = SFML::Window::Joystick

bool
isConnected(joystick_id)
	unsigned int joystick_id
	CODE:
		RETVAL = Joystick::isConnected(joystick_id);
	OUTPUT:
		RETVAL

unsigned int
getButtonCount(joystick_id)
	unsigned int joystick_id
	CODE:
		RETVAL = Joystick::getButtonCount(joystick_id);
	OUTPUT:
		RETVAL

bool
hasAxis(joystick_id, axis)
	unsigned int joystick_id	
	int axis
	CODE:
		RETVAL = Joystick::hasAxis(joystick_id, (sf::Joystick::Axis) axis);
	OUTPUT:
		RETVAL

bool
isButtonPressed(joystick_id, button)
	unsigned int joystick_id
	unsigned int button
	CODE:
		RETVAL = Joystick::isButtonPressed(joystick_id,button);
	OUTPUT:
		RETVAL

float
getAxisPosition(joystick_id, axis)
	unsigned int joystick_id
	int axis
	CODE:
		RETVAL = Joystick::getAxisPosition(joystick_id, (sf::Joystick::Axis) axis);
	OUTPUT:
		RETVAL

void
update()
	CODE:
		Joystick::update();

MODULE = SFML		PACKAGE = SFML::Window::Keyboard

bool
isKeyPressed(key_id)
	int key_id
	CODE:
		RETVAL = Keyboard::isKeyPressed((sf::Keyboard::Key) key_id);
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Mouse

bool
isButtonPressed(button_id)
	int button_id
	CODE:
		RETVAL = Mouse::isButtonPressed((sf::Mouse::Button)button_id);
	OUTPUT:
		RETVAL

void
getPosition(...)
	PREINIT:
	Vector2i v;
	PPCODE:
		if(items > 0){
			if(!sv_isa(ST(4), "SFML::Window::Window"))
				croak("Usage: SFML::Window::Mouse::getPosition\n       SFML::Window::Mouse::getPosition(window)");
			v = Mouse::getPosition(*((Window*)SvIV(SvRV(ST(0)))));
		} else {
			v = Mouse::getPosition();
		}
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(v.x)));
		PUSHs(sv_2mortal(newSViv(v.y)));

void
setPosition(x,y,...)
	int x
	int y
	CODE:
		if(items > 3) {
			if(!sv_isa(ST(4), "SFML::Window::Window"))
				croak_xs_usage(cv, "x, y, window=current");
			Mouse::setPosition(Vector2i(x,y),*((Window*)SvIV(SvRV(ST(0)))));
		} else {
			Mouse::setPosition(Vector2i(x,y));
		}

MODULE = SFML		PACKAGE = SFML::Window::VideoMode

VideoMode*
VideoMode::new(width, height, ...)
	unsigned int width
	unsigned int height
	CODE:
		if (items == 4)
			RETVAL = new VideoMode(width, height, SvUV(ST(3)));
		else if (items == 3)
			RETVAL = new VideoMode(width, height);
		else if (items == 2 && sv_isobject(SvRV(ST(1))) && SvTYPE(SvRV(ST(1))) == SVt_PVMG)
			RETVAL = new VideoMode(*((VideoMode*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "CLASS, width, height, bitsPerPixel=32");
	OUTPUT:
		RETVAL

void
VideoMode::DESTROY()

bool
VideoMode::isValid()

unsigned int
VideoMode::getWidth()
	CODE:
		RETVAL = THIS->width;
	OUTPUT:
		RETVAL

unsigned int
VideoMode::getHeight()
	CODE:
		RETVAL = THIS->height;
	OUTPUT:
		RETVAL

unsigned int
VideoMode::getBitsPerPixel()
	CODE:
		RETVAL = THIS->bitsPerPixel;
	OUTPUT:
		RETVAL


void
VideoMode::setWidth(width)
	unsigned int width
	CODE:
		THIS->width = width;

void
VideoMode::setHeight(height)
	unsigned int height
	CODE:
		THIS->height = height;

void
VideoMode::setBitsPerPixel(bitsPerPixel)
	unsigned int bitsPerPixel
	CODE:
		THIS->bitsPerPixel = bitsPerPixel;

VideoMode*
getDesktopMode()
	PREINIT:
		const char * CLASS = "SFML::Window::VideoMode";
	CODE:
		RETVAL = new VideoMode(VideoMode::getDesktopMode());
	OUTPUT:
		RETVAL

void
getFullscreenModes()
	PREINIT:
	std::vector<VideoMode> vmv;
	PPCODE:
		vmv = VideoMode::getFullscreenModes();
		EXTEND(SP,vmv.size());
		for(unsigned int i = 0; i < vmv.size(); i++){
			SV* sv = newSV(0);
			sv_setref_pv(sv, "SFML::Window::VideoMode", (void*) new VideoMode(vmv[i]));
			PUSHs(sv_2mortal(sv));
		}

SV *
eq(left, right, swap)
	VideoMode* left
	VideoMode* right
	int swap
	OVERLOAD: ==
	CODE:
		RETVAL = newSViv((*right) == (*left));
	OUTPUT:
		RETVAL

SV *
ne(left, right, swap)
	VideoMode* left
	VideoMode* right
	int swap
	OVERLOAD: !=
	CODE:
		RETVAL = newSViv((*right) != (*left));
	OUTPUT:
		RETVAL

SV *
lt(left, right, swap)
	VideoMode* left
	VideoMode* right
	int swap
	OVERLOAD: <
	CODE:
		if(swap)
			RETVAL = newSViv((*right) < (*left));
		else
			RETVAL = newSViv((*left) < (*right));
	OUTPUT:
		RETVAL

SV *
gt(left, right, swap)
	VideoMode* left
	VideoMode* right
	int swap
	OVERLOAD: >
	CODE:
		if(swap)
			RETVAL = newSViv((*right) > (*left));
		else
			RETVAL = newSViv((*left) > (*right));
	OUTPUT:
		RETVAL

SV *
le(left, right, swap)
	VideoMode* left
	VideoMode* right
	int swap
	OVERLOAD: <=
	CODE:
		if(swap)
			RETVAL = newSViv((*right) <= (*left));
		else
			RETVAL = newSViv((*left) <= (*right));
	OUTPUT:
		RETVAL

SV *
ge(left, right, swap)
	VideoMode* left
	VideoMode* right
	int swap
	OVERLOAD: >=
	CODE:
		if(swap)
			RETVAL = newSViv((*right) >= (*left));
		else
			RETVAL = newSViv((*left) >= (*right));
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Window

Window*
Window::::new(...)
	CODE:
		RETVAL = 0;
		if (items == 1){
			RETVAL = new RenderWindow();
		} else if (items > 1 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Window::VideoMode")){
			char * title = SvPV_nolen(ST(2));
			VideoMode* mode = (VideoMode*)SvIV(SvRV(ST(1)));
			if (items == 4){
				RETVAL = new Window(*mode, std::string(title), SvIV(ST(3)));
			} else if(items == 5 &&
				sv_isobject(ST(4)) &&
				SvTYPE(SvRV(ST(4))) == SVt_PVMG &&
				sv_isa(ST(4), "SFML::Window::ContextSettings")){
				RETVAL = new Window(*mode, std::string(title), SvIV(ST(3)), *((ContextSettings*) SvIV(SvRV(ST(4)))));
			} else if(items == 3){
				RETVAL = new Window(*mode, std::string(title));
			}
		}
		if(RETVAL == 0)
			croak_xs_usage(cv, "THIS, mode, title, style=SFML::Window::Style::Default, contextSettings=default");
	OUTPUT:
		RETVAL

void
Window::DESTROY()

void
Window::create(mode, title, ...)
	VideoMode* mode
	char * title
	CODE:
		bool error = true;
		if (items == 4){
			error = false;
			THIS->create(*mode, std::string(title), SvIV(ST(3)));
		} else if(items == 5 &&
			sv_isobject(ST(4)) &&
			SvTYPE(SvRV(ST(4))) == SVt_PVMG &&
			sv_isa(ST(4), "SFML::Window::ContextSettings")){
			error = false;
			THIS->create(*mode, std::string(title), SvIV(ST(3)), *((ContextSettings*) SvIV(SvRV(ST(4)))));
		} else if(items == 3){
			error = false;
			THIS->create(*mode, std::string(title));
		}
		if(error)
			croak_xs_usage(cv, "CLASS, mode, title, style=SFML::Window::Style::Default, contextSettings=default");

void
Window::close()

bool
Window::isOpen()

ContextSettings*
Window::getSettings()
	PREINIT:
		const char * CLASS = "SFML::Window::ContextSettings";
	CODE:
		RETVAL = new ContextSettings(THIS->getSettings());
	OUTPUT:
		RETVAL

void
Window::getPosition()
	PREINIT:
		Vector2i v;
	PPCODE:
		v = THIS->getPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(v.x)));
		PUSHs(sv_2mortal(newSViv(v.y)));

void
Window::setPosition(x,y)
	int x
	int y
	CODE:
		THIS->setPosition(Vector2i(x,y));

void
Window::getSize()
	PREINIT:
	Vector2u v;
	PPCODE:
		v = THIS->getSize();
		//fprintf(stderr, "Size to %u, %u\n", v.x, v.y); 
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVuv(v.x)));
		PUSHs(sv_2mortal(newSVuv(v.y)));

void
Window::setSize(x,y)
	unsigned int x
	unsigned int y
	CODE:
		THIS->setSize(Vector2u(x,y));

void
Window::setTitle(title)
	char * title
	CODE:
		THIS->setTitle(std::string(title));

void
Window::setVisible(...)
	CODE:
		if(items >= 1)
			THIS->setVisible(SvTRUE(ST(1)));
		else
			THIS->setVisible(true);

void
Window::setVerticalSyncEnabled(...)
	CODE:
		if(items >= 1)
			THIS->setVerticalSyncEnabled(SvTRUE(ST(1)));
		else
			THIS->setVerticalSyncEnabled(true);

void
Window::setMouseCursorVisible(...)
	CODE:
		if(items >= 1)
			THIS->setMouseCursorVisible(SvTRUE(ST(1)));
		else
			THIS->setMouseCursorVisible(true);

void
Window::setKeyRepeatEnabled(...)
	CODE:
		if(items >= 1)
			THIS->setKeyRepeatEnabled(SvTRUE(ST(1)));
		else
			THIS->setKeyRepeatEnabled(true);

void
Window::setFramerateLimit(limit)
	unsigned int limit

void
Window::setJoystickThreshold(threshold)
	float threshold


bool
Window::setActive(...)
	CODE:
		if(items >= 1)
			RETVAL = THIS->setActive(SvTRUE(ST(1)));
		else
			RETVAL = THIS->setActive(true);
	OUTPUT:
		RETVAL

void
Window::display()

void
Window::setIcon(x,y,pixels)
	unsigned int x
	unsigned int y
	void * pixels
	CODE:
		THIS->setIcon(x,y,(Uint8*)pixels);

bool
Window::pollEvent(event)
	Event* event
	PREINIT:
		const char * CLASS = "SFML::Window::Event";
	CODE:
		RETVAL = THIS->pollEvent(*event);
	OUTPUT:
		RETVAL

bool
Window::waitEvent(event)
	Event* event
	PREINIT:
		const char * CLASS = "SFML::Window::Event";
	CODE:
		RETVAL = THIS->waitEvent(*event);
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

Event*
Event::new()

void
Event::DESTROY()

int
Event::type()
	CODE:
		RETVAL = THIS->type;
	OUTPUT:
		RETVAL

SizeEvent*
Event::size()
	PREINIT:
		const char * CLASS = "SFML::Window::SizeEvent";
	CODE:
		RETVAL = &THIS->size;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::SizeEvent

SizeEvent*
SizeEvent::new()

void
SizeEvent::DESTROY()

int
SizeEvent::width()
	CODE:
		RETVAL = THIS->width;
	OUTPUT:
		RETVAL

int
SizeEvent::height()
	CODE:
		RETVAL = THIS->height;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

KeyEvent*
Event::key()
	PREINIT:
		const char * CLASS = "SFML::Window::KeyEvent";
	CODE:
		RETVAL = &THIS->key;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::KeyEvent

KeyEvent*
KeyEvent::new()

void
KeyEvent::DESTROY()

int
KeyEvent::code()
	CODE:
		RETVAL = THIS->code;
	OUTPUT:
		RETVAL

bool
KeyEvent::alt()
	CODE:
		RETVAL = THIS->alt;
	OUTPUT:
		RETVAL

bool
KeyEvent::control()
	CODE:
		RETVAL = THIS->control;
	OUTPUT:
		RETVAL

bool
KeyEvent::shift()
	CODE:
		RETVAL = THIS->shift;
	OUTPUT:
		RETVAL

bool
KeyEvent::system()
	CODE:
		RETVAL = THIS->system;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

TextEvent*
Event::text()
	PREINIT:
		const char * CLASS = "SFML::Window::TextEvent";
	CODE:
		RETVAL = &THIS->text;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::TextEvent

TextEvent*
TextEvent::new()

void
TextEvent::DESTROY()

char*
TextEvent::unicode()
	CODE:
		RETVAL = (char*) malloc(4); //TODO: Figure out if this actually works!
		Uint32 ch = THIS->unicode;
		RETVAL[0] = (ch << 8*3) & 0x000000FF;
		RETVAL[1] = (ch << 8*2) & 0x0000FF00;
		RETVAL[2] = (ch << 8*1) & 0x00FF0000;
		RETVAL[3] = (ch       ) & 0xFF000000;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

MouseMoveEvent*
Event::mouseMove()
	PREINIT:
		const char * CLASS = "SFML::Window::MouseMoveEvent";
	CODE:
		RETVAL = &THIS->mouseMove;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::MouseMoveEvent

MouseMoveEvent*
MouseMoveEvent::new()

void
MouseMoveEvent::DESTROY()

int
MouseMoveEvent::x()
	CODE:
		RETVAL = THIS->x;
	OUTPUT:
		RETVAL

int
MouseMoveEvent::y()
	CODE:
		RETVAL = THIS->y;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

MouseButtonEvent*
Event::mouseButton()
	PREINIT:
		const char * CLASS = "SFML::Window::MouseButtonEvent";
	CODE:
		RETVAL = &THIS->mouseButton;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::MouseButtonEvent

MouseButtonEvent*
MouseButtonEvent::new()

void
MouseButtonEvent::DESTROY()

int
MouseButtonEvent::x()
	CODE:
		RETVAL = THIS->x;
	OUTPUT:
		RETVAL

int
MouseButtonEvent::y()
	CODE:
		RETVAL = THIS->y;
	OUTPUT:
		RETVAL

int
MouseButtonEvent::button()
	CODE:
		RETVAL = THIS->button;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

MouseWheelEvent*
Event::mouseWheel()
	PREINIT:
		const char * CLASS = "SFML::Window::MouseWheelEvent";
	CODE:
		RETVAL = &THIS->mouseWheel;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::MouseWheelEvent

MouseWheelEvent*
MouseWheelEvent::new()

void
MouseWheelEvent::DESTROY()

int
MouseWheelEvent::x()
	CODE:
		RETVAL = THIS->x;
	OUTPUT:
		RETVAL

int
MouseWheelEvent::y()
	CODE:
		RETVAL = THIS->y;
	OUTPUT:
		RETVAL

int
MouseWheelEvent::delta()
	CODE:
		RETVAL = THIS->delta;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

JoystickMoveEvent*
Event::joystickMove()
	PREINIT:
		const char * CLASS = "SFML::Window::JoystickMoveEvent";
	CODE:
		RETVAL = &THIS->joystickMove;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::JoystickMoveEvent

JoystickMoveEvent*
JoystickMoveEvent::new()

void
JoystickMoveEvent::DESTROY()

unsigned int
JoystickMoveEvent::joystickId()
	CODE:
		RETVAL = THIS->joystickId;
	OUTPUT:
		RETVAL

int
JoystickMoveEvent::axis()
	CODE:
		RETVAL = THIS->axis;
	OUTPUT:
		RETVAL

float
JoystickMoveEvent::position()
	CODE:
		RETVAL = THIS->position;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

JoystickButtonEvent*
Event::joystickButton()
	PREINIT:
		const char * CLASS = "SFML::Window::JoystickButtonEvent";
	CODE:
		RETVAL = &THIS->joystickButton;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::JoystickButtonEvent

JoystickButtonEvent*
JoystickButtonEvent::new()

void
JoystickButtonEvent::DESTROY()

unsigned int
JoystickButtonEvent::joystickId()
	CODE:
		RETVAL = THIS->joystickId;
	OUTPUT:
		RETVAL

int
JoystickButtonEvent::button()
	CODE:
		RETVAL = THIS->button;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::Event

JoystickConnectEvent*
Event::joystickConnect()
	PREINIT:
		const char * CLASS = "SFML::Window::JoystickConnectEvent";
	CODE:
		RETVAL = &THIS->joystickConnect;
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Window::JoystickConnectEvent

JoystickConnectEvent*
JoystickConnectEvent::new()

void
JoystickConnectEvent::DESTROY()

unsigned int
JoystickConnectEvent::joystickId()
	CODE:
		RETVAL = THIS->joystickId;
	OUTPUT:
		RETVAL
