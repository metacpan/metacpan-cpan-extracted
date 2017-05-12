#include "SDL.h"

int CharPos[520];
SDL_Surface *Font;

#define SPACE_WIDTH CharPos[2]-CharPos[1]

Uint32 GetPixel (SDL_Surface *Surface, Sint32 X, Sint32 Y)
{

   Uint8  *bits;
   Uint32 Bpp;

   
   Bpp = Surface->format->BytesPerPixel;

   bits = ((Uint8 *)Surface->pixels)+Y*Surface->pitch+X*Bpp;

   // Get the pixel
   switch(Bpp) {
      case 1:
         return *((Uint8 *)Surface->pixels + Y * Surface->pitch + X);
         break;
      case 2:
         return *((Uint16 *)Surface->pixels + Y * Surface->pitch/2 + X);
         break;
      case 3: { // Format/endian independent 
         Uint8 r, g, b;
         r = *((bits)+Surface->format->Rshift/8);
         g = *((bits)+Surface->format->Gshift/8);
         b = *((bits)+Surface->format->Bshift/8);
         return SDL_MapRGB(Surface->format, r, g, b);
         }
         break;
      case 4:
         return *((Uint32 *)Surface->pixels + Y * Surface->pitch/4 + X);
         break;
   }

   return -1;
}

void InitFont(SDL_Surface *FontToUse)
{
    int x=0,i=0;

    Font=FontToUse;
    if (Font==NULL) {
	printf("ERROR: The font file could not be loaded\n");
	exit(1);
    }
    while (x<Font->w) {
	if (GetPixel(Font,x,0)==SDL_MapRGB(Font->format,255,0,255)) {
	    CharPos[i++]=x;
//	    printf("%d  ",x);
	    while (GetPixel(Font,x,0)==SDL_MapRGB(Font->format,255,0,255))
		x++;
	    CharPos[i++]=x;
//	    printf("%d  ",x);
	}
	x++;
//	printf("%d-",GetPixel(Font,x,0));
    }
}


void PutString(SDL_Surface *Surface, int x, int y, char *text)
{
    unsigned char ofs;
    int i=0;
    SDL_Rect srcrect,dstrect;
    
    while (text[i]!='\0') {
	if (text[i]==' ') {
	    x+=SPACE_WIDTH;
	    i++;
	} else {
	    ofs=(text[i]-33)*2+1;
//	    printf("printing %c %d\n",text[i],ofs);
    	    srcrect.w=dstrect.w=(CharPos[ofs+2]+CharPos[ofs+1])/2-(CharPos[ofs]+CharPos[ofs-1])/2;
    	    srcrect.h=dstrect.h=Font->h-1;
    	    srcrect.x=(CharPos[ofs]+CharPos[ofs-1])/2;
    	    srcrect.y=1;
    	    dstrect.x=x;
	    dstrect.y=y;
    	    SDL_BlitSurface( Font, &srcrect, Surface, &dstrect);
	    x+=CharPos[ofs+1]-CharPos[ofs];
	    i++;
	}
    }    
}

int TextWidth(char *text)
{
    int x=0,i=0;
    unsigned char ofs;

    while (text[i]!='\0') {
	if (text[i]==' ') {
	    x+=SPACE_WIDTH;
	    i++;
	} else {
	    ofs=(text[i]-33)*2+1;
	    x+=CharPos[ofs+1]-CharPos[ofs];
	    i++;
	}
    }
    return x+CharPos[ofs+2]-CharPos[ofs+1];
}

void SFont_Input( SDL_Surface *Dest, int x, int y, int PixelWidth, char *text)
{
    SDL_Event event;
    int ch;
    SDL_Surface *Back;
    SDL_Rect rect;
    
    Back = SDL_AllocSurface(Dest->flags,
    			    PixelWidth,
    			    Font->h,
    			    Dest->format->BitsPerPixel,
    			    Dest->format->Rmask,
    			    Dest->format->Gmask,
			    Dest->format->Bmask, 0);
    rect.x=x;
    rect.y=y;
    rect.w=PixelWidth;
    rect.h=Font->h;
    SDL_BlitSurface(Dest, &rect, Back, NULL);
    PutString(Dest ,x,y,text);
    SDL_UpdateRect(Dest, x, y, PixelWidth, Font->h);
    
    SDL_EnableUNICODE(1);
    while ((ch!=SDLK_RETURN)&&(SDL_WaitEvent(&event)))
    if (event.type==SDL_KEYDOWN) {
	ch=event.key.keysym.unicode;
	sprintf(text,"%s%c",text,ch);
	if (ch=='\b') text[strlen(text)-2]='\0';
	if (TextWidth(text)>PixelWidth) text[strlen(text)-1]='\0';
	//printf("%s  -  %c\n",Name,ch);
	SDL_BlitSurface( Back, NULL, Dest, &rect);
	PutString(Dest ,x,y,text);
	SDL_UpdateRect(Dest, x, y, PixelWidth, Font->h);
    }
    SDL_FreeSurface(Back);
}