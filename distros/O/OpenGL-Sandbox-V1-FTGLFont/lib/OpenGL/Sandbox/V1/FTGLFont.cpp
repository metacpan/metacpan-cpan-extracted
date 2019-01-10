#include <ftgl.h>
#include <GL/gl.h>
#define SCALAR_REF_DATA(obj) (SvROK(obj) && SvPOK(SvRV(obj))? (void*)SvPVX(SvRV(obj)) : (void*)0)
#define SCALAR_REF_LEN(obj)  (SvROK(obj) && SvPOK(SvRV(obj))? SvCUR(SvRV(obj)) : 0)

static const char * next_utf8(const char *str);
static int count_utf8(const char *str);

class FTFontWrapper {
	SV *mmap_obj;
	FTFont *font;
public:
	/* Constructor takes one parameter of type OpenGL::Sandbox::MMap,
	 * and retains a reference to it until destroyed.
	 */
	FTFontWrapper(SV *mmap, const char *font_class):
		mmap_obj(mmap), font(NULL)
	{
		void *data= SCALAR_REF_DATA(mmap);
		int len= SCALAR_REF_LEN(mmap);
		if (!data || !len)
			croak("Expected MMap or scalar ref to non-empty font data buffer");
		
		/* most common first */
		if (strcmp(font_class, "FTTextureFont") == 0)
			font= new FTTextureFont((const unsigned char*) data, len);
		else if (strcmp(font_class, "FTExtrudeFont") == 0)
			font= new FTExtrudeFont((const unsigned char*) data, len);
		else if (strcmp(font_class, "FTPolygonFont") == 0)
			font= new FTPolygonFont((const unsigned char*) data, len);
		else if (strcmp(font_class, "FTPixmapFont") == 0)
			font= new FTPixmapFont((const unsigned char*) data, len);
		else if (strcmp(font_class, "FTOutlineFont") == 0)
			font= new FTOutlineFont((const unsigned char*) data, len);
		else if (strcmp(font_class, "FTBufferFont") == 0)
			font= new FTBufferFont((const unsigned char*) data, len);
		else if (strcmp(font_class, "FTBitmapFont") == 0)
			font= new FTBitmapFont((const unsigned char*) data, len);
		else
			croak("Un-handled font class %s", font_class);
		SvREFCNT_inc_void_NN(mmap_obj);
	}
	~FTFontWrapper() {
		if (font) {
			delete font;
			font= NULL;
		}
		if (mmap_obj) {
			SvREFCNT_dec(mmap_obj);
			mmap_obj= NULL;
		}
	}

	/* I'd prefer to subclass FTFont and export the methods of the parent class directly,
	 * but can't figure out a way to get Inline::CPP to process the classes from the FTGL
	 * headers.  Also, some methods are overloaded.
	 * So, just re-publish them with perl-friendly names.
	 */
	double ascender()     { return font->Ascender(); }
	double descender()    { return font->Descender(); }
	double line_height()  { return font->LineHeight(); }
	
	int face_size(...) { /* first arg is object, optional second is point-size, optional third is resolution */
		Inline_Stack_Vars;
		int pt, res= 0;
		if (Inline_Stack_Items > 1) { /* If extra args, invoke "setter" */
			pt= SvIV(Inline_Stack_Item(1));
			if (Inline_Stack_Items > 2 && SvOK(Inline_Stack_Item(2)))
				res= SvIV(Inline_Stack_Item(1));
			if (res <= 0) res= 72; /* Sanity, because otherwise FTFont goes haywire */
			if (!font->FaceSize(pt, res)) croak("invalid size");
		}
		return font->FaceSize();
	}
	
	void depth(float d) {
		font->Depth(d);
	}
	void outset(...) {
		Inline_Stack_Vars;
		if (Inline_Stack_Items > 2) {
			font->Outset( SvNV(Inline_Stack_Item(1)), SvNV(Inline_Stack_Item(2)) );
		} else if (Inline_Stack_Items > 1) {
			font->Outset( SvNV(Inline_Stack_Item(1)) );
		} else
			croak("Require one or two arguments to outset");
		Inline_Stack_Void;
	}
	void use_display_list(bool en) {
		font->UseDisplayList(en);
	}

	double advance(const char *text) { return font->Advance(text, -1); }
	void render(const char *text, ...);
};

void FTFontWrapper::render(const char *text, ...) {
	FTPoint pos(0,0);
	float x= 0, y= 0, z= 0, xalign= 0, yalign= 0, scale= 1, xscale= 1, yscale= 1,
		width= 0, monospace= 0;
	int i, alter_matrix= 0;
	const char *key;
	SV *value;
	
	Inline_Stack_Vars;
	if (Inline_Stack_Items & 1)
		/* stack items includes $self and $text, and key=>value after that */
		croak("Odd number of parameters passed to ->render");
	
	for (i= 2; i < Inline_Stack_Items-1; i+= 2) {
		key= SvPV_nolen(Inline_Stack_Item(i));
		value= Inline_Stack_Item(i+1);
		if (!SvOK(value)) continue; /* ignore anything that isn't defined */
		switch (*key) {
		case 'x': if (!key[1]) x= SvNV(value);
			else if (strcmp("xalign", key) == 0) xalign= SvNV(value);
			else
		case 'y': if (!key[1]) y= SvNV(value);
			else if (strcmp("yalign", key) == 0) {
				yalign= SvNV(value);
				if (yalign > 0)
					pos.Y(-font->Ascender() * yalign);
				else
					pos.Y(font->Descender() * yalign);
			}
			else
		case 'z': if (!key[1]) {
				z= SvNV(value);
				if (z) alter_matrix= 1;
			}
			else
		case 'w': if (!key[1] || strcmp("width", key) == 0) {
				width= SvNV(value);
				alter_matrix= 1;
			}
			else
		case 'h': if (!key[1] || strcmp("height", key) == 0) {
				yscale= SvNV(value) / font->Ascender();
				if (yscale != 1) alter_matrix= 1;
			}
			else
		case 's': if (strcmp("scale", key) == 0) {
				scale= SvNV(value);
				if (scale != 1) alter_matrix= 1;
			}
			else
		case 'm': if (strcmp("monospace", key) == 0) monospace= SvNV(value);
			else
		default:
			croak("Invalid key '%s' in call to render()", key);
		}
	}
	
	if (width || xalign) {
		float advance = monospace? monospace * count_utf8(text) : font->Advance(text, -1);
		if (width) /* change xscale to match this overall width: advance * xscale = width */
			xscale= width / advance;
		if (xalign) /* adjust (scaled) x-pos according to percentage of advance */
			pos.X(-advance * xalign);
	}
	
	/* Need to use Pushmatrix/Popmatrix if scale or z coordinate changes */
	if (alter_matrix) {
		if (xscale == 1)
			xscale= yscale == 1? scale : yscale;
		if (yscale == 1)
			yscale= xscale == 1? scale : xscale;
		glPushMatrix();
		glTranslated(x, y, z);
		glScaled(xscale, yscale, 1);
	}
	else { /* Else can just adjust the starting position */
		pos.X(pos.X() + x);
		pos.Y(pos.Y() + y);
	}
	
	/* FTGL doesn't have a monospace option, so make one by rendering single characters */
	if (monospace) {
		for (const char *c= text; *c; c= next_utf8(c)) {
			float charWidth= font->Advance(c, 1);
			float xOfs= 0.5*(monospace - charWidth);
			font->Render(c, 1, pos+FTPoint(xOfs,0));
			pos.X(pos.X()+monospace);
		}
	}
	else
		font->Render(text, -1, pos);
	
	if (alter_matrix)
		glPopMatrix();
	
	Inline_Stack_Void;
}

static const char * next_utf8(const char *str) {
	if (!*str) return str;
	++str;
	while ((*str & 0xC0) == 0x80) str++;
	return str;
}

static int count_utf8(const char *str) {
	int n= 0;
	while (*str) {
		if ((*str++ & 0xC0) != 0x80) n++;
	}
	return n;
}
