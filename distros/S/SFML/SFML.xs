// Perl Headers
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#ifdef __cplusplus
}
#endif

//Remove name clash:
#undef do_open
#undef do_close

#include <SFML/System.hpp>
#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>
#include <vector>
#include <string>

using std::string;

#define ARG_P_BEGIN for(int arg_p_n = 1; arg_p_n < items; arg_p_n++){

#define ARG_P_OPTION(x) if(strcmp(SvPV_nolen(ST(arg_p_n)),(x)) == 0){ arg_p_n++; if(arg_p_n >= items) break;

#define ARG_P (ST(arg_p_n))

#define ARG_P_OPTION_END continue; }

#define ARG_P_END }

#define STACK_DUMP { \
	fprintf(stderr, "Items: %i\n", items); \
	for(int i = 0; i < items; i ++){ \
		fprintf(stderr, "ST(%i):\n", i); \
		sv_dump(ST(i)); \
	}}

using namespace sf;

typedef Event::SizeEvent		SizeEvent;
typedef Event::KeyEvent			KeyEvent;
typedef Event::TextEvent		TextEvent;
typedef Event::MouseMoveEvent		MouseMoveEvent;
typedef Event::MouseButtonEvent		MouseButtonEvent;
typedef Event::MouseWheelEvent		MouseWheelEvent;
typedef Event::JoystickMoveEvent	JoystickMoveEvent;
typedef Event::JoystickButtonEvent	JoystickButtonEvent;
typedef Event::JoystickConnectEvent	JoystickConnectEvent;

MODULE = SFML		PACKAGE = SFML		

PROTOTYPES: ENABLE

INCLUDE: xsrc/Window.xs
INCLUDE: xsrc/Graphics.xs
