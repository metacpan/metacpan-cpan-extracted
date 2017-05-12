// SFONT - SDL Font Library by Karl Bartel <karlb@gmx.net>

#include "SDL.h"

// Initializes the font
// Font: this is the surface which contains the font.
void InitFont(SDL_Surface *Font);

// Blits a string to a surface
// Destination: the suface you want to blit to
// text: a string containing the text you want to blit.
void PutString( SDL_Surface *Destination, int x, int y, char *text);

// Returns the width of "text" in pixels
int TextWidth( char *text);

// Allows the user to enter text
// Width: What is the maximum width of the text (in pixels)
// text: This string contains the text which was entered by the user
void SFont_Input( SDL_Surface Destination, int x, int y, int Width, char *text);