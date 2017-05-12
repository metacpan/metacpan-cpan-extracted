MODULE = SFML		PACKAGE = SFML::Graphics::CircleShape

CircleShape*
CircleShape::new(...)
	CODE:
		RETVAL = new CircleShape();
		ARG_P_BEGIN
			ARG_P_OPTION("radius")
				RETVAL->setRadius(SvNV(ARG_P));
			ARG_P_OPTION_END
			ARG_P_OPTION("pointCount")
				RETVAL->setPointCount(SvIV(ARG_P));
			ARG_P_OPTION_END
		ARG_P_END
	OUTPUT:
		RETVAL

CircleShape*
CircleShape::DESTROY()

void
CircleShape::setRadius(radius)
	float radius

float
CircleShape::getRadius()

void
CircleShape::setPointCount(count)
	unsigned int count

unsigned int
CircleShape::getPointCount()

void
CircleShape::getPoint(index)
	unsigned int index
	CODE:
		Vector2f v = THIS->getPoint(index);
		EXTEND(SP,1);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

void
CircleShape::setTexture(texture, ...)
	Texture* texture
	CODE:
		if(items >1)
			THIS->setTexture(texture, SvTRUE(ST(2)));
		else
			THIS->setTexture(texture);

void
CircleShape::setTextureRect(left, top, width, height)
	int left
	int top
	int width
	int height
	CODE:
		THIS->setTextureRect(IntRect(left,top,width,height));

void
CircleShape::setFillColor(color)
	Color* color
	CODE:
		THIS->setFillColor(*color);

void
CircleShape::setOutlineColor(color)
	Color* color
	CODE:
		THIS->setOutlineColor(*color);

void
CircleShape::setOutlineThickness(thickness)
	float thickness

void
CircleShape::getTextureRect()
	CODE:
		EXTEND(SP,4);
		IntRect r = THIS->getTextureRect();
		XPUSHs(sv_2mortal(newSViv(r.top)));
		XPUSHs(sv_2mortal(newSViv(r.left)));
		XPUSHs(sv_2mortal(newSViv(r.width)));
		XPUSHs(sv_2mortal(newSViv(r.height)));

Color*
CircleShape::getFillColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getFillColor());
	OUTPUT:
		RETVAL

Color*
CircleShape::getOutlineColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getOutlineColor());
	OUTPUT:
		RETVAL

float
CircleShape::getOutlineThickness()

void
CircleShape::getLocalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getLocalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
CircleShape::getGlobalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getGlobalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
CircleShape::setPosition(x,y)
	float x
	float y

void
CircleShape::setRotation(angle)
	float angle

void
CircleShape::setScale(factorX, factorY)
	float factorX
	float factorY

void
CircleShape::setOrigin(x,y)
	float x
	float y

void
CircleShape::getPosition()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getPosition();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

float
CircleShape::getRotation()

void
CircleShape::getScale()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getScale();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
CircleShape::getOrigin()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getOrigin();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
CircleShape::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
CircleShape::rotate(angle)
	float angle

void
CircleShape::scale(factorX, factorY)
	float factorX
	float factorY

Transform*
CircleShape::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
CircleShape::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Color

Color*
Color::new(...)
	CODE:
		if(items == 5)
			RETVAL = new Color(SvUV(ST(1)), SvUV(ST(2)), SvUV(ST(3)), SvUV(ST(4)));
		else if(items == 4)
			RETVAL = new Color(SvUV(ST(1)), SvUV(ST(2)), SvUV(ST(3)));
		else if(items == 1)
			RETVAL = new Color();
		else {
			croak_xs_usage(cv,  "THIS, red=0, green=0, blue=0, alpha=255");
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

void
Color::DESTROY()

unsigned int
Color::getA()
	CODE:
		RETVAL = THIS->a;
	OUTPUT:
		RETVAL

unsigned int
Color::getR()
	CODE:
		RETVAL = THIS->r;
	OUTPUT:
		RETVAL

unsigned int
Color::getG()
	CODE:
		RETVAL = THIS->g;
	OUTPUT:
		RETVAL

unsigned int
Color::getB()
	CODE:
		RETVAL = THIS->b;
	OUTPUT:
		RETVAL

unsigned int
Color::getRGBA()
	CODE:
		RETVAL = THIS->a & (THIS->b << 8) & (THIS->g << 16) & (THIS->b << 24);
	OUTPUT:
		RETVAL

void
Color::setA(a)
	unsigned int a
	CODE:
		THIS->a = a;

void
Color::setR(r)
	unsigned int r
	CODE:
		THIS->r = r;

void
Color::setG(g)
	unsigned int g
	CODE:
		THIS->g = g;

void
Color::setB(b)
	unsigned int b
	CODE:
		THIS->b = b;

void
Color::setRGBA(rgba)
	unsigned int rgba
	CODE:
		THIS->a = rgba & 0x000000FF >> 0;
		THIS->b = rgba & 0x0000FF00 >> 8;
		THIS->g = rgba & 0x00FF0000 >> 16;
		THIS->r = rgba & 0xFF000000 >> 24;

bool
color_eq(left, right, swap)
	Color* left
	Color* right
	bool swap
	OVERLOAD: ==
	CODE:
		RETVAL = (*left) == (*right);
	OUTPUT:
		RETVAL

bool
color_ne(left, right, swap)
	Color* left
	Color* right
	bool swap
	OVERLOAD: !=
	CODE:
		RETVAL = (*left) != (*right);
	OUTPUT:
		RETVAL

Color*
color_pl(left, right, swap)
	Color* left
	Color* right
	bool swap
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	OVERLOAD: +
	CODE:
		RETVAL = new Color((*left) + (*right));
	OUTPUT:
		RETVAL

Color*
color_ti(left, right, swap)
	Color* left
	Color* right
	bool swap
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	OVERLOAD: *
	CODE:
		RETVAL = new Color((*right) * (*left));
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::ConvexShape

ConvexShape*
ConvexShape::new(...)
	CODE:
		if(items == 1)
			RETVAL = new ConvexShape();
		else if(items == 2)
			RETVAL = new ConvexShape(SvUV(ST(1)));
		else
			croak_xs_usage(cv,  "THIS, pointCount=0");
	OUTPUT:
		RETVAL

void
ConvexShape::DESTROY()

void
ConvexShape::setPointCount(count)
	unsigned int count

unsigned int
ConvexShape::getPointCount()

void
ConvexShape::setPoint(index, x, y)
	unsigned int index
	float x
	float y
	CODE:
		THIS->setPoint(index, Vector2f(x,y));

void
ConvexShape::getPoint(index)
	unsigned int index
	CODE:
		EXTEND(SP,2);
		Vector2f v = THIS->getPoint(index);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

void
ConvexShape::setTexture(texture, ...)
	Texture* texture
	CODE:
		if(items == 1)
			THIS->setTexture(texture);
		else if(items == 2)
			THIS->setTexture(texture, SvTRUE(ST(2)));
		else
			croak_xs_usage(cv, "THIS, texture, resetRect=true");

void
ConvexShape::setTextureRect(x,y,width,height)
	int x
	int y
	int width
	int height
	CODE:
		THIS->setTextureRect(IntRect(x,y,width,height));

void
ConvexShape::setFillColor(color)
	Color* color
	CODE:
		THIS->setFillColor(*color);

void
ConvexShape::setOutlineColor(color)
	Color* color
	CODE:
		THIS->setFillColor(*color);

void
ConvexShape::setOutlineThickness(thickness)
	float thickness

void
ConvexShape::getTextureRect()
	CODE:
		EXTEND(SP,4);
		IntRect r = THIS->getTextureRect();
		XPUSHs(sv_2mortal(newSViv(r.top)));
		XPUSHs(sv_2mortal(newSViv(r.left)));
		XPUSHs(sv_2mortal(newSViv(r.width)));
		XPUSHs(sv_2mortal(newSViv(r.height)));

Color*
ConvexShape::getFillColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getFillColor());
	OUTPUT:
		RETVAL

Color*
ConvexShape::getOutlineColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getFillColor());
	OUTPUT:
		RETVAL

float
ConvexShape::getOutlineThickness()

void
ConvexShape::getLocalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getLocalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
ConvexShape::getGlobalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getGlobalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
ConvexShape::setPosition(x,y)
	float x
	float y

void
ConvexShape::setRotation(angle)
	float angle

void
ConvexShape::setScale(factorX, factorY)
	float factorX
	float factorY

void
ConvexShape::setOrigin(x,y)
	float x
	float y

void
ConvexShape::getPosition()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getPosition();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

float
ConvexShape::getRotation()

void
CircleShape::getScale()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getScale();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
ConvexShape::getOrigin()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getOrigin();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
ConvexShape::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
ConvexShape::rotate(angle)
	float angle

void
ConvexShape::scale(factorX, factorY)
	float factorX
	float factorY

Transform*
ConvexShape::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
ConvexShape::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Font

Font*
Font::new(...)
	CODE:
		SV* pv = SvRV(ST(1));
		if(items == 2){
			if(sv_isobject(ST(1)) && SvTYPE(pv) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Font"))
				RETVAL = new Font(*((Font*)SvIV(pv)));
			else {
				warn( "SFML::Graphics::Font::new() -- Argument is not a blessed SV reference" );
				XSRETURN_UNDEF;
			}
		} else if (items == 1)
			RETVAL = new Font();
		else
			croak_xs_usage(cv, "CLASS, [copy]");
	OUTPUT:
		RETVAL

Font*
Font::DESTROY()

bool
Font::loadFromFile(filename)
	char * filename
	CODE:
		RETVAL = THIS->loadFromFile(std::string(filename));
	OUTPUT:
		RETVAL

bool
Font::loadFromMemory(data)
	SV* data
	CODE:
		STRLEN len;
		void * dt = SvPV(data, len);
		RETVAL = THIS->loadFromMemory(dt, len);
	OUTPUT:
		RETVAL

Glyph*
Font::getGlyph(codePoint, characterSize, bold)
	unsigned int codePoint
	unsigned int characterSize
	bool bold
	PREINIT:
		const char * CLASS = "SFML::Graphics::Glyph";
	CODE:
		RETVAL = new Glyph(THIS->getGlyph(codePoint, characterSize, bold));
	OUTPUT:
		RETVAL

int
Font::getKerning(first, second, characterSize);
	unsigned int first
	unsigned int second
	unsigned int characterSize

int
Font::getLineSpacing(characterSize)
	unsigned int characterSize

Texture*
Font::getTexture(characterSize)
	unsigned int characterSize
	PREINIT:
		const char * CLASS = "SFML::Graphics::Texture";
	CODE:
		RETVAL = (Texture*)(void*)&THIS->getTexture(characterSize);
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Glyph

Glyph*
Glyph::new()

void
Glyph::DESTROY()

int
Glyph::getAdvance()
	CODE:
		RETVAL = THIS->advance;
	OUTPUT:
		RETVAL

void
Glyph::setAdvance(advance)
	int advance
	CODE:
		THIS->advance = advance;

void
Glyph::getBounds()
	CODE:
		EXTEND(SP,4);
		XPUSHs(sv_2mortal(newSViv(THIS->bounds.top)));
		XPUSHs(sv_2mortal(newSViv(THIS->bounds.left)));
		XPUSHs(sv_2mortal(newSViv(THIS->bounds.width)));
		XPUSHs(sv_2mortal(newSViv(THIS->bounds.height)));

void
Glyph::getTextureRect()
	CODE:
		EXTEND(SP,4);
		XPUSHs(sv_2mortal(newSViv(THIS->textureRect.top)));
		XPUSHs(sv_2mortal(newSViv(THIS->textureRect.left)));
		XPUSHs(sv_2mortal(newSViv(THIS->textureRect.width)));
		XPUSHs(sv_2mortal(newSViv(THIS->textureRect.height)));

void
Glyph::setBounds(top, left, width, height)
	int top
	int left
	int width
	int height
	CODE:
		THIS->bounds.top = top;
		THIS->bounds.left = left;
		THIS->bounds.width = width;
		THIS->bounds.height = height;

void
Glyph::setTextureRect(top, left, width, height)
	int top
	int left
	int width
	int height
	CODE:
		THIS->bounds.top = top;
		THIS->bounds.left = left;
		THIS->bounds.width = width;
		THIS->bounds.height = height;

MODULE = SFML		PACKAGE = SFML::Graphics::Image

Image*
Image::new(...)
	CODE:
		SV* pv = SvRV(ST(1));
		if(items == 2){
			if(sv_isobject(ST(1)) && SvTYPE(pv) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Image"))
				RETVAL = new Image(*((Image*)SvIV(pv)));
			else {
				warn( "SFML::Graphics::Image::new() -- Argument is not a blessed SV reference" );
				XSRETURN_UNDEF;
			}
		} else if (items == 1)
			RETVAL = new Image();
		else
			croak_xs_usage(cv, "CLASS, [copy]");
	OUTPUT:
		RETVAL

void
Image::DESTROY()

void
Image::create(width, height, ...)
	unsigned int width
	unsigned int height
	CODE:
		if(items == 4 && sv_isobject(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVMG && sv_isa(ST(3), "SFML::Graphics::Color"))
			THIS->create(width, height, *((Color*) SvIV(SvRV(ST(3)))));
		else if(items == 4){
			SV* pv = SvRV(ST(3));
			if(SvPOK(pv))
				THIS->create(width, height, (Uint8*) SvPV_nolen(pv));
			else
				THIS->create(width, height, (Uint8*) SvIV(pv));
		} else if(items == 3)
			THIS->create(width, height);
		else
			croak_xs_usage(cv, "THIS, width, height, (pixels | color)");

bool
Image::loadFromFile(filename)
	char * filename
	CODE:
		RETVAL = THIS->loadFromFile(std::string(filename));
	OUTPUT:
		RETVAL

bool
Image::loadFromMemory(data, size)
	void * data
	unsigned int size

bool
Image::saveToFile(filename)
	char * filename
	CODE:
		RETVAL = THIS->saveToFile(std::string(filename));
	OUTPUT:
		RETVAL

void
Image::getSize()
	CODE:
		EXTEND(SP,2);
		Vector2u r = THIS->getSize();
		XPUSHs(sv_2mortal(newSVuv(r.x)));
		XPUSHs(sv_2mortal(newSVuv(r.y)));

void
Image::createMaskFromColor(color, ...)
	Color* color
	CODE:
		if(items == 3)
			THIS->createMaskFromColor(*color, SvUV(ST(2)));
		else if (items == 2)
			THIS->createMaskFromColor(*color);
		else
			croak_xs_usage(cv, "THIS, color, alpha=0");

void
Image::copy(source, destX, destY, ...)
	Image* source
	unsigned int destX
	unsigned int destY
	CODE:
		if(items == 4)
			THIS->copy(*source, destX, destY);
		else if(items == 8)
			THIS->copy(*source, destX, destY, IntRect(SvIV(ST(4)), SvIV(ST(5)), SvIV(ST(6)), SvIV(ST(6))));
		else if(items == 9)
			THIS->copy(*source, destX, destY, IntRect(SvIV(ST(4)), SvIV(ST(5)), SvIV(ST(6)), SvIV(ST(6))), SvTRUE(ST(7)));
		else
			croak_xs_usage(cv, "THIS, source, destX, destY, sourceRect(top, left, width, height), applyAlpha");

void
Image::setPixel(x, y, color)
	unsigned int x
	unsigned int y
	Color* color
	CODE:
		THIS->setPixel(x,y,*color);

Color*
Image::getPixel(x,y)
	unsigned int x
	unsigned int y
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getPixel(x,y));
	OUTPUT:
		RETVAL

void*
Image::getPixelsPtr()
	CODE:
		RETVAL = (void*) THIS->getPixelsPtr();
	OUTPUT:
		RETVAL

void
Image::flipHorizontally()

void
Image::flipVertically()

MODULE = SFML		PACKAGE = SFML::Graphics::RectangleShape

RectangleShape*
RectangleShape::new(...)
	CODE:
		if(items == 3)
			RETVAL = new RectangleShape(Vector2f(SvNV(ST(1)), SvNV(ST(2))));
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::RectangleShape"))
			RETVAL = new RectangleShape(*((RectangleShape*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, ( copy | size(x,y) )");
	OUTPUT:
		RETVAL

void
RectangleShape::DESTROY()

unsigned int
RectangleShape::getPointCount()

void
RectangleShape::getPoint(index)
	unsigned int index
	CODE:
		Vector2f v = THIS->getPoint(index);
		EXTEND(SP,1);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

void
RectangleShape::getSize()
	CODE:
		Vector2f v = THIS->getSize();
		EXTEND(SP,1);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

void
RectangleShape::setSize(x,y)
	float x
	float y
	CODE:
		THIS->setSize(Vector2f(x,y));

void
RectangleShape::setTexture(texture, ...)
	Texture* texture
	CODE:
		if(items >1)
			THIS->setTexture(texture, SvTRUE(ST(2)));
		else
			THIS->setTexture(texture);

void
RectangleShape::setTextureRect(left, top, width, height)
	int left
	int top
	int width
	int height
	CODE:
		THIS->setTextureRect(IntRect(left,top,width,height));

void
RectangleShape::setFillColor(color)
	Color* color
	CODE:
		THIS->setFillColor(*color);

void
RectangleShape::setOutlineColor(color)
	Color* color
	CODE:
		THIS->setOutlineColor(*color);

void
RectangleShape::setOutlineThickness(thickness)
	float thickness

void
RectangleShape::getTextureRect()
	CODE:
		EXTEND(SP,4);
		IntRect r = THIS->getTextureRect();
		XPUSHs(sv_2mortal(newSViv(r.top)));
		XPUSHs(sv_2mortal(newSViv(r.left)));
		XPUSHs(sv_2mortal(newSViv(r.width)));
		XPUSHs(sv_2mortal(newSViv(r.height)));

Color*
RectangleShape::getFillColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getFillColor());
	OUTPUT:
		RETVAL

Color*
RectangleShape::getOutlineColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getOutlineColor());
	OUTPUT:
		RETVAL

float
RectangleShape::getOutlineThickness()

void
RectangleShape::getLocalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getLocalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
RectangleShape::getGlobalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getGlobalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
RectangleShape::setPosition(x,y)
	float x
	float y

void
RectangleShape::setRotation(angle)
	float angle

void
RectangleShape::setScale(factorX, factorY)
	float factorX
	float factorY

void
RectangleShape::setOrigin(x,y)
	float x
	float y

void
RectangleShape::getPosition()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getPosition();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

float
RectangleShape::getRotation()

void
RectangleShape::getScale()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getScale();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
RectangleShape::getOrigin()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getOrigin();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
RectangleShape::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
RectangleShape::rotate(angle)
	float angle

void
RectangleShape::scale(factorX, factorY)
	float factorX
	float factorY

Transform*
RectangleShape::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
RectangleShape::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::RenderStates

RenderStates*
RenderStates::new(...)
	CODE:
		bool error = false;
		if(items == 1)
			RETVAL = new RenderStates();
		else if(items == 2 ){
			if(sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG){
				SV* s = SvRV(ST(1));
				if(sv_isa(s, "SFML::Graphics::RenderStates"))
					RETVAL = new RenderStates(*((RenderStates*)SvIV(s)));
				else if(sv_isa(ST(1), "SFML::Graphics::Transform"))
					RETVAL = new RenderStates(*((Transform*)SvIV(s)));
				else if(sv_isa(ST(1), "SFML::Graphics::Texture"))
					RETVAL = new RenderStates((Texture*)SvIV(s));
				else if(sv_isa(ST(1), "SFML::Graphics::Shader"))
					RETVAL = new RenderStates((Shader*)SvIV(s));
				else
					error = true;
			} else
				RETVAL = new RenderStates((BlendMode)SvIV(ST(1)));
		} else if(items == 5) {
			for(int i = 2; i < 5; i++){
				error = (!(sv_isobject(ST(i)) && SvTYPE(SvRV(ST(i))) == SVt_PVMG)) | error;
			}
			if(!error &&
				sv_isa(ST(2), "SFML::Graphics::Transform") &&
				sv_isa(ST(3), "SFML::Graphics::Texture") &&
				sv_isa(ST(4), "SFML::Graphics::Shader"))
				RETVAL = new RenderStates((BlendMode)SvIV(ST(4)),
					*((Transform*)SvIV(SvRV(ST(4)))),
					(Texture*)SvIV(SvRV(ST(4))),
					(Shader*)SvIV(SvRV(ST(4))));
		}
		if(error){
			croak_xs_usage(cv, "THIS, (theBlendMode | theTransform | theTexture | "
				"theShader | theBlendMode, theTransform, theTexture, theShader");
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

void
RenderStates::DESTROY();

int
RenderStates::getBlendMode()
	CODE:
		RETVAL = THIS->blendMode;
	OUTPUT:
		RETVAL

Transform*
RenderStates::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = &THIS->transform;
	OUTPUT:
		RETVAL

Texture*
RenderStates::getTexture()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Texture";
	CODE:
		RETVAL = (Texture *) (void *) THIS->texture;
	OUTPUT:
		RETVAL

Shader*
RenderStates::getShader()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Shader";
	CODE:
		RETVAL = (Shader *) (void *) THIS->shader;
	OUTPUT:
		RETVAL

void
RenderStates::setBlendMode(blendMode)
	int blendMode
	CODE:
		THIS->blendMode = (BlendMode)blendMode;

void
RenderStates::setTransform(transform)
	Transform* transform
	CODE:
		THIS->transform = *transform;

void
RenderStates::setTexture(texture)
	Texture* texture
	CODE:
		THIS->texture = texture;

void
RenderStates::setShader(shader)
	Shader* shader
	CODE:
		THIS->shader = shader;

MODULE = SFML		PACKAGE = SFML::Graphics::RenderTexture

RenderTexture*
RenderTexture::new()

void
RenderTexture::DESTROY()

bool
RenderTexture::create(width, height, ...)
	unsigned int width
	unsigned int height
	CODE:
		if(items == 3)
			RETVAL = THIS->create(width, height);
		else if(items == 4)
			RETVAL = THIS->create(width, height, SvTRUE(ST(3)));
		else
			croak_xs_usage(cv, "THIS, width, height, depthBuffer=false");
	OUTPUT:
		RETVAL

void
RenderTexture::setSmooth(smooth)
	bool smooth

bool
RenderTexture::isSmooth()

bool
RenderTexture::setActive(...)
	CODE:
		if(items == 2)
			RETVAL = THIS->setActive(SvTRUE(ST(1)));
		else if(items == 1)
			RETVAL = THIS->setActive();
		else
			croak_xs_usage(cv, "THIS, active=true");
	OUTPUT:
		RETVAL

void
RenderTexture::display()

void
RenderTexture::getSize()
	CODE:
		EXTEND(SP,2);
		Vector2u r = THIS->getSize();
		XPUSHs(sv_2mortal(newSVuv(r.x)));
		XPUSHs(sv_2mortal(newSVuv(r.y)));

Texture*
RenderTexture::getTexture()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Texture";
	CODE:
		RETVAL = (Texture*)(void*)&THIS->getTexture();
	OUTPUT:
		RETVAL

void
RenderTexture::clear(...)
	CODE:
		if(items == 2 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Color"))
			THIS->setActive(SvTRUE(ST(1)));
		else if(items == 1)
			THIS->setActive();
		else
			croak_xs_usage(cv, "THIS, color=black");

void
RenderTexture::setView(view)
	View* view
	CODE:
		THIS->setView(*view);

View*
RenderTexture::getView()
	PREINIT:
		const char * CLASS = "SFML::Graphics::View";
	CODE:
		RETVAL = (View*)(void*)&THIS->getView();
	OUTPUT:
		RETVAL

View*
RenderTexture::getDefaultView()
	PREINIT:
		const char * CLASS = "SFML::Graphics::View";
	CODE:
		RETVAL = (View*)(void*)&THIS->getDefaultView();
	OUTPUT:
		RETVAL

void
RenderTexture::getViewport(view)
	View* view;
	CODE:
		EXTEND(SP,4);
		IntRect r = THIS->getViewport(*view);
		XPUSHs(sv_2mortal(newSViv(r.top)));
		XPUSHs(sv_2mortal(newSViv(r.left)));
		XPUSHs(sv_2mortal(newSViv(r.width)));
		XPUSHs(sv_2mortal(newSViv(r.height)));

void
RenderTexture::mapPixelToCoords(x, y, ...)
	int x
	int y
	CODE:
		Vector2f r;
		if(items == 2 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Color"))
			r = THIS->mapPixelToCoords(Vector2i(x,y), *((View*)SvIV(SvRV(ST(1)))));
		else if(items == 1)
			r = THIS->mapPixelToCoords(Vector2i(x,y));
		else
			croak_xs_usage(cv, "THIS, x, y, [view]");
		EXTEND(SP,2);
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
RenderTexture::mapCoordsToPixel(x, y, ...)
	float x
	float y
	CODE:
		Vector2i r;
		if(items == 2 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Color"))
			r = THIS->mapCoordsToPixel(Vector2f(x,y), *((View*)SvIV(SvRV(ST(1)))));
		else if(items == 1)
			r = THIS->mapCoordsToPixel(Vector2f(x,y));
		else
			croak_xs_usage(cv, "THIS, x, y, [view]");
		EXTEND(SP,2);
		XPUSHs(sv_2mortal(newSViv(r.x)));
		XPUSHs(sv_2mortal(newSViv(r.y)));

void
RenderTexture::draw(...)
	CODE:
		if((items == 3 || items == 2) &&
			sv_isobject(ST(1)) &&
			SvTYPE(SvRV(ST(1))) == SVt_PVMG){ // First option
			if(items == 3 && sv_isobject(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVMG && sv_isa(SvRV(ST(2)), "SFML::Graphics::RenderStates"))
				THIS->draw(*((Drawable*)SvIV(SvRV(ST(1)))), *((RenderStates*)SvIV(SvRV(ST(2)))));
			else
				THIS->draw(*((Drawable*)SvIV(SvRV(ST(1)))));
		} else if((items == 4 || items == 3) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) { // Second option
			AV* a = (AV*) SvRV(ST(1));
			unsigned int len = av_len(a);
			Vertex* vdata = (Vertex*) malloc(sizeof(Vertex)*len);
			for(int i=0; i < len; i++){
				vdata[i] = *((Vertex*)SvIV(SvRV(av_pop(a))));
			}
			if(items == 4 && sv_isobject(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVMG && sv_isa(SvRV(ST(3)), "SFML::Graphics::RenderStates"))
				THIS->draw(vdata, len, (PrimitiveType) SvIV(ST(2)),*((RenderStates*)SvIV(SvRV(ST(3)))));
			else
				THIS->draw(vdata, len, (PrimitiveType) SvIV(ST(2)));
		} else
			croak_xs_usage(cv, "THIS, (drawable, renderStates=default | vertices, type, renderStates=default)");

void
RenderTexture::pushGLStates()

void
RenderTexture::popGLStates()

void
RenderTexture::resetGLStates()

void
RenderTexture::setRepeated(repeated)
	bool repeated

bool
RenderTexture::isRepeated()

MODULE = SFML		PACKAGE = SFML::Graphics::RenderWindow

RenderWindow*
RenderWindow::new(...)
	CODE:
		RETVAL = 0;
		if (items == 1){
			RETVAL = new RenderWindow();
		} else if (items > 1 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Window::VideoMode")){
			char * title = SvPV_nolen(ST(2));
			VideoMode* mode = (VideoMode*)SvIV(SvRV(ST(1)));
			if (items == 4){
				RETVAL = new RenderWindow(*mode, std::string(title), SvIV(ST(3)));
			} else if(items == 5 &&
				sv_isobject(ST(4)) &&
				SvTYPE(SvRV(ST(4))) == SVt_PVMG &&
				sv_isa(ST(4), "SFML::Window::ContextSettings")){
				RETVAL = new RenderWindow(*mode, std::string(title), SvIV(ST(3)), *((ContextSettings*) SvIV(SvRV(ST(4)))));
			} else if(items == 3){
				RETVAL = new RenderWindow(*mode, std::string(title));
			}
		}
		if(RETVAL == 0)
			croak_xs_usage(cv, "THIS, mode, title, style=SFML::Window::Style::Default, contextSettings=default");
	OUTPUT:
		RETVAL

void
RenderWindow::DESTROY()

void
RenderWindow::create(mode, title, ...)
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
RenderWindow::close()

bool
RenderWindow::isOpen()

ContextSettings*
RenderWindow::getSettings()
	PREINIT:
		const char * CLASS = "SFML::Window::ContextSettings";
	CODE:
		RETVAL = new ContextSettings(THIS->getSettings());
	OUTPUT:
		RETVAL

void
RenderWindow::getPosition()
	PREINIT:
		Vector2i v;
	PPCODE:
		v = THIS->getPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(v.x)));
		PUSHs(sv_2mortal(newSViv(v.y)));

void
RenderWindow::setPosition(x,y)
	int x
	int y
	CODE:
		THIS->setPosition(Vector2i(x,y));

void
RenderWindow::getSize()
	PREINIT:
	Vector2u v;
	PPCODE:
		v = THIS->getSize();
		//fprintf(stderr, "Size to %u, %u\n", v.x, v.y); 
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVuv(v.x)));
		PUSHs(sv_2mortal(newSVuv(v.y)));

void
RenderWindow::setSize(x,y)
	unsigned int x
	unsigned int y
	CODE:
		THIS->setSize(Vector2u(x,y));

void
RenderWindow::setTitle(title)
	char * title
	CODE:
		THIS->setTitle(std::string(title));

void
RenderWindow::setVisible(...)
	CODE:
		if(items >= 1)
			THIS->setVisible(SvTRUE(ST(1)));
		else
			THIS->setVisible(true);

void
RenderWindow::setVerticalSyncEnabled(...)
	CODE:
		if(items >= 1)
			THIS->setVerticalSyncEnabled(SvTRUE(ST(1)));
		else
			THIS->setVerticalSyncEnabled(true);

void
RenderWindow::setMouseCursorVisible(...)
	CODE:
		if(items >= 1)
			THIS->setMouseCursorVisible(SvTRUE(ST(1)));
		else
			THIS->setMouseCursorVisible(true);

void
RenderWindow::setKeyRepeatEnabled(...)
	CODE:
		if(items >= 1)
			THIS->setKeyRepeatEnabled(SvTRUE(ST(1)));
		else
			THIS->setKeyRepeatEnabled(true);

void
RenderWindow::setFramerateLimit(limit)
	unsigned int limit

void
RenderWindow::setJoystickThreshold(threshold)
	float threshold

void
RenderWindow::setIcon(x,y,pixels)
	unsigned int x
	unsigned int y
	void * pixels
	CODE:
		THIS->setIcon(x,y,(Uint8*)pixels);

bool
RenderWindow::pollEvent(event)
	Event* event
	PREINIT:
		const char * CLASS = "SFML::Window::Event";
	CODE:
		RETVAL = THIS->pollEvent(*event);
	OUTPUT:
		RETVAL

bool
RenderWindow::waitEvent(event)
	Event* event
	PREINIT:
		const char * CLASS = "SFML::Window::Event";
	CODE:
		RETVAL = THIS->waitEvent(*event);
	OUTPUT:
		RETVAL

bool
RenderWindow::setActive(...)
	CODE:
		if(items == 2)
			RETVAL = THIS->setActive(SvTRUE(ST(1)));
		else if(items == 1)
			RETVAL = THIS->setActive();
		else
			croak_xs_usage(cv, "THIS, active=true");
	OUTPUT:
		RETVAL

void
RenderWindow::display()

void
RenderWindow::clear(...)
	CODE:
		if(items == 2 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Color"))
			THIS->setActive(SvTRUE(ST(1)));
		else if(items == 1)
			THIS->setActive();
		else
			croak_xs_usage(cv, "THIS, color=black");

void
RenderWindow::setView(view)
	View* view
	CODE:
		THIS->setView(*view);

View*
RenderWindow::getView()
	PREINIT:
		const char * CLASS = "SFML::Graphics::View";
	CODE:
		RETVAL = (View*)(void*)&THIS->getView();
	OUTPUT:
		RETVAL

View*
RenderWindow::getDefaultView()
	PREINIT:
		const char * CLASS = "SFML::Graphics::View";
	CODE:
		RETVAL = (View*)(void*)&THIS->getDefaultView();
	OUTPUT:
		RETVAL

void
RenderWindow::getViewport(view)
	View* view;
	CODE:
		EXTEND(SP,4);
		IntRect r = THIS->getViewport(*view);
		XPUSHs(sv_2mortal(newSViv(r.top)));
		XPUSHs(sv_2mortal(newSViv(r.left)));
		XPUSHs(sv_2mortal(newSViv(r.width)));
		XPUSHs(sv_2mortal(newSViv(r.height)));

void
RenderWindow::mapPixelToCoords(x, y, ...)
	int x
	int y
	CODE:
		Vector2f r;
		if(items == 2 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Color"))
			r = THIS->mapPixelToCoords(Vector2i(x,y), *((View*)SvIV(SvRV(ST(1)))));
		else if(items == 1)
			r = THIS->mapPixelToCoords(Vector2i(x,y));
		else
			croak_xs_usage(cv, "THIS, x, y, [view]");
		EXTEND(SP,2);
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
RenderWindow::mapCoordsToPixel(x, y, ...)
	float x
	float y
	CODE:
		Vector2i r;
		if(items == 2 && sv_isobject(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Color"))
			r = THIS->mapCoordsToPixel(Vector2f(x,y), *((View*)SvIV(SvRV(ST(1)))));
		else if(items == 1)
			r = THIS->mapCoordsToPixel(Vector2f(x,y));
		else
			croak_xs_usage(cv, "THIS, x, y, [view]");
		EXTEND(SP,2);
		XPUSHs(sv_2mortal(newSViv(r.x)));
		XPUSHs(sv_2mortal(newSViv(r.y)));

void
RenderWindow::draw(...)
	CODE:
		if((items == 3 || items == 2) &&
			sv_isobject(ST(1)) &&
			SvTYPE(SvRV(ST(1))) == SVt_PVMG){ // First option
			if(items == 3 && sv_isobject(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVMG && sv_isa(ST(2), "SFML::Graphics::RenderStates"))
				THIS->draw(*((Drawable*)SvIV(SvRV(ST(1)))), *((RenderStates*)SvIV(SvRV(ST(2)))));
			else
				THIS->draw(*((Drawable*)SvIV(SvRV(ST(1)))));
		} else if((items == 4 || items == 3) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) { // Second option
			AV* a = (AV*) SvRV(ST(1));
			unsigned int len = av_len(a);
			Vertex* vdata = (Vertex*) malloc(sizeof(Vertex)*len);
			for(int i=0; i < len; i++){
				vdata[i] = *((Vertex*)SvIV(SvRV(av_pop(a))));
			}
			if(items == 4 && sv_isobject(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVMG && sv_isa(ST(3), "SFML::Graphics::RenderStates"))
				THIS->draw(vdata, len, (PrimitiveType) SvIV(ST(2)),*((RenderStates*)SvIV(SvRV(ST(3)))));
			else
				THIS->draw(vdata, len, (PrimitiveType) SvIV(ST(2)));
		} else
			croak_xs_usage(cv, "THIS, (drawable, renderStates=default | vertices, type, renderStates=default)");

void
RenderWindow::pushGLStates()

void
RenderWindow::popGLStates()

void
RenderWindow::resetGLStates()

Image*
RenderWindow::capture()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Image";
	CODE:
		RETVAL = new Image(THIS->capture());
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Shader

Shader*
Shader::new()

void
Shader::DESTROY()

bool
Shader::loadFromFile(vfilename, sfilename)
	string vfilename
	string sfilename

bool
Shader::loadFromMemory(vstringy, sstringy)
	string vstringy
	string sstringy

void
Shader::setParameter(name, ...)
	string name
	CODE:
		if(items == 3)
			if(sv_isobject(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVMG){
				if(sv_isa(ST(2), "SFML::Graphics::Texture"))
					THIS->setParameter(name, *((Texture*)SvIV(SvRV(ST(2)))));
				else if(sv_isa(ST(2), "SFML::Graphics::Transform"))
					THIS->setParameter(name, *((Transform*)SvIV(SvRV(ST(2)))));
				else if(sv_isa(ST(2), "SFML::Graphics::Color"))
					THIS->setParameter(name, *((Color*)SvIV(SvRV(ST(2)))));
				else
					warn("Unknown object type!");
			} else {
				THIS->setParameter(name, SvNV(ST(2)));
			}
		else if(items == 4)
			THIS->setParameter(name, SvNV(ST(2)), SvNV(ST(3)));
		else if(items == 5)
			THIS->setParameter(name, SvNV(ST(2)), SvNV(ST(3)), SvNV(ST(4)));
		else if(items == 6)
			THIS->setParameter(name, SvNV(ST(2)), SvNV(ST(3)), SvNV(ST(4)), SvNV(ST(5)));
		else
			croak_xs_usage(cv, "THIS, (texture | transform | color | x | x,y | x,y,z | x,y,z,w)");

void
bind(shader)
	Shader* shader
	CODE:
		sf::Shader::bind(shader);

bool
isAvailable()
	CODE:
		RETVAL = sf::Shader::isAvailable();
	OUTPUT:
		RETVAL

MODULE = SFML			PACKAGE = SFML::Graphics::Sprite

Sprite*
Sprite::new(...)
	CODE:
		if(items == 1)
			RETVAL = new Sprite();
		else if((items == 2 || items == 6) && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Texture"))
			if(items == 6)
				RETVAL = new Sprite(*((Texture*)SvIV(SvRV(ST(1)))), IntRect(SvIV(ST(2)), SvIV(ST(3)), SvIV(ST(4)), SvIV(ST(5))));
			else
				RETVAL = new Sprite(*((Texture*)SvIV(SvRV(ST(1)))));
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Sprite"))
			RETVAL = new Sprite(*((Sprite*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, [ copy | texture, [top, left, width, height] ]");
	OUTPUT:
		RETVAL

void
Sprite::DESTROY()

void
Sprite::setTexture(texture, ...)
	Texture* texture
	CODE:
		if(items >1)
			THIS->setTexture(*texture, SvTRUE(ST(2)));
		else
			THIS->setTexture(*texture);

void
Sprite::setTextureRect(left, top, width, height)
	int left
	int top
	int width
	int height
	CODE:
		THIS->setTextureRect(IntRect(left,top,width,height));

void
Sprite::setColor(color)
	Color* color
	CODE:
		THIS->setColor(*color);

void
Sprite::getTextureRect()
	CODE:
		EXTEND(SP,4);
		IntRect r = THIS->getTextureRect();
		XPUSHs(sv_2mortal(newSViv(r.top)));
		XPUSHs(sv_2mortal(newSViv(r.left)));
		XPUSHs(sv_2mortal(newSViv(r.width)));
		XPUSHs(sv_2mortal(newSViv(r.height)));

Color*
Sprite::getColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getColor());
	OUTPUT:
		RETVAL

void
Sprite::getLocalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getLocalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
Sprite::getGlobalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getGlobalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
Sprite::setPosition(x,y)
	float x
	float y

void
Sprite::setRotation(angle)
	float angle

void
Sprite::setScale(factorX, factorY)
	float factorX
	float factorY

void
Sprite::setOrigin(x,y)
	float x
	float y

void
Sprite::getPosition()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getPosition();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

float
Sprite::getRotation()

void
Sprite::getScale()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getScale();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
Sprite::getOrigin()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getOrigin();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
Sprite::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
Sprite::rotate(angle)
	float angle

void
Sprite::scale(factorX, factorY)
	float factorX
	float factorY

Transform*
Sprite::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
Sprite::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL

Texture*
Sprite::getTexture()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Texture";
	CODE:
		RETVAL = (Texture *) (void *) THIS->getTexture();
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Text

Text*
Text::new(...)
	CODE:
		if(items == 1)
			RETVAL = new Text();
		else if((items == 3 || items == 4) && SvTYPE(SvRV(ST(2))) == SVt_PVMG && sv_isa(ST(2), "SFML::Graphics::Font"))
			if(items == 4)
				RETVAL = new Text(string(SvPV_nolen(ST(1))), *((Font*)SvIV(SvRV(ST(2)))), SvIV(ST(3)));
			else
				RETVAL = new Text(string(SvPV_nolen(ST(1))), *((Font*)SvIV(SvRV(ST(2)))));
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Text"))
			RETVAL = new Text(*((Text*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, [ copy | text, font, characterSize=30 ]");
	OUTPUT:
		RETVAL

void
Text::DESTROY()

void
Text::setFont(font)
	Font* font
	CODE:
		THIS->setFont(*font);

void
Text::setString(text)
	string text

void
Text::setStyle(style)
	unsigned int style

void
Text::setColor(color)
	Color* color
	CODE:
		THIS->setColor(*color);

string
Text::getString()

Font*
Text::getFont()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Font";
	CODE:
		RETVAL = (Font*)(void*) THIS->getFont();
	OUTPUT:
		RETVAL

unsigned int
Text::getCharacterSize()

void
Text::setCharacterSize(size)
	unsigned int size

unsigned int
Text::getStyle()

Color*
Text::getColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->getColor());
	OUTPUT:
		RETVAL

void
Text::findCharacterPos(index)
	unsigned int index
	CODE:
		EXTEND(SP,2);
		Vector2f s = THIS->findCharacterPos(index);
		XPUSHs(sv_2mortal(newSVnv(s.x)));
		XPUSHs(sv_2mortal(newSVnv(s.y)));

void
Text::getLocalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getLocalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
Text::getGlobalBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getGlobalBounds();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
Text::setPosition(x,y)
	float x
	float y

void
Text::setRotation(angle)
	float angle

void
Text::setScale(factorX, factorY)
	float factorX
	float factorY

void
Text::setOrigin(x,y)
	float x
	float y

void
Text::getPosition()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getPosition();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

float
Text::getRotation()

void
Text::getScale()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getScale();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
Text::getOrigin()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getOrigin();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
Text::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
Text::rotate(angle)
	float angle

void
Text::scale(factorX, factorY)
	float factorX
	float factorY

Transform*
Text::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
Text::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Texture

Texture*
Texture::new(...)
	CODE:
		if(items == 1)
			RETVAL = new Texture();
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Texture"))
			RETVAL = new Texture(*((Texture*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, [ copy ]");
	OUTPUT:
		RETVAL

void
Texture::DESTROY()

bool
Texture::create(width, height)
	unsigned int width
	unsigned int height

bool
Texture::loadFromFile(filename, ...)
	string filename
	CODE:
		if(items == 6)
			RETVAL = THIS->loadFromFile(filename, IntRect(SvIV(ST(2)), SvIV(ST(3)), SvIV(ST(4)), SvIV(ST(5))));
		else if(items == 2)
			RETVAL = THIS->loadFromFile(filename);
		else
			croak_xs_usage(cv, "THIS, filename, [ top, left, width, height ]");
	OUTPUT:
		RETVAL

bool
Texture::loadFromMemory(...)
	CODE:
		std::size_t len;
		void * data = SvPV(ST(1),len);
		if(items == 6)
			RETVAL = THIS->loadFromMemory(data, len, IntRect(SvIV(ST(2)), SvIV(ST(3)), SvIV(ST(4)), SvIV(ST(5))));
		else if(items == 2)
			RETVAL = THIS->loadFromMemory(data, len);
		else
			croak_xs_usage(cv, "THIS, data, [ top, left, width, height ]");
	OUTPUT:
		RETVAL

bool
Texture::loadFromImage(image, ...)
	Image* image
	CODE:
		if(items == 6)
			RETVAL = THIS->loadFromImage(*image, IntRect(SvIV(ST(2)), SvIV(ST(3)), SvIV(ST(4)), SvIV(ST(5))));
		else if(items == 2)
			RETVAL = THIS->loadFromImage(*image);
		else
			croak_xs_usage(cv, "THIS, image, [ top, left, width, height ]");
	OUTPUT:
		RETVAL

void
Texture::getSize()
	CODE:
		EXTEND(SP,2);
		Vector2u r = THIS->getSize();
		XPUSHs(sv_2mortal(newSVuv(r.x)));
		XPUSHs(sv_2mortal(newSVuv(r.y)));

Image*
Texture::copyToImage()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Image";
	CODE:
		RETVAL = new Image(THIS->copyToImage());
	OUTPUT:
		RETVAL

void
Texture::update(...)
	CODE:
		bool error = false;
		if(items >= 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG){
			if(sv_isa(ST(1), "SFML::Graphics::Image")){
				if(items == 2)
					THIS->update(*((Image*)SvIV(SvRV(ST(1)))));
				else if(items == 4)
					THIS->update(*((Image*)SvIV(SvRV(ST(1)))), SvUV(ST(2)), SvUV(ST(3)));
				else
					error = true;
			} else if(sv_isa(ST(2), "SFML::Graphics::Window")){
				if(items == 2)
					THIS->update(*((Window*)SvIV(SvRV(ST(1)))));
				else if(items == 4)
					THIS->update(*((Window*)SvIV(SvRV(ST(1)))), SvUV(ST(2)), SvUV(ST(3)));
				else
					error = true;
			} else {
				if(items == 2)
					THIS->update((Uint8*)SvPV_nolen(ST(1)));
				else if(items == 6)
					THIS->update((Uint8*)SvPV_nolen(ST(1)), SvUV(ST(2)), SvUV(ST(3)), SvUV(ST(4)), SvUV(ST(5)));
				else
					error = true;
			}
		}
		if(error)
			croak_xs_usage(cv, "THIS, ( image, [ x, y ] | window, [ x, y ] | pixels [ width, height, x, y ] )");

bool
Texture::isSmooth()

void
Texture::setSmooth(smooth)
	bool smooth

void
Texture::setRepeated(repeated)
	bool repeated

bool
Texture::isRepeated()

MODULE = SFML		PACKAGE = SFML::Graphics::Transform

Transform*
Transform::new(...)
	CODE:
		if(items == 1)
			RETVAL = new Transform();
		else if(items == 10)
			RETVAL = new Transform(
				SvNV(ST(1)), SvNV(ST(2)), SvNV(ST(3)),
				SvNV(ST(4)), SvNV(ST(5)), SvNV(ST(6)),
				SvNV(ST(7)), SvNV(ST(8)), SvNV(ST(9)));
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Transform"))
			RETVAL = new Transform(*((Transform*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, [ copy | a00, a01, a02, a10, a11, a12, a20, a21, a22 ]");
	OUTPUT:
		RETVAL

void
Transform::DESTROY()

void
Transform::getMatrix()
	CODE:
		const float * res = THIS->getMatrix();
		EXTEND(SP,16);
		for(int i=0; i<16;i++)
			XPUSHs(sv_2mortal(newSVnv(res[i])));

Transform*
Transform::getInverse()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverse());
	OUTPUT:
		RETVAL

void
Transform::transformPoint(x,y)
	float x
	float y
	CODE:
		EXTEND(SP,2);
		Vector2f v = THIS->transformPoint(x,y);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

void
Transform::transformRect(top, left, width, height)
	float top
	float left
	float width
	float height
	CODE:
		EXTEND(SP,4);
		FloatRect v = THIS->transformRect(FloatRect(top,left,width,height));
		XPUSHs(sv_2mortal(newSVnv(v.top)));
		XPUSHs(sv_2mortal(newSVnv(v.left)));
		XPUSHs(sv_2mortal(newSVnv(v.width)));
		XPUSHs(sv_2mortal(newSVnv(v.height)));

Transform*
Transform::combine(transform)
	Transform* transform
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = &THIS->combine(*transform);
	OUTPUT:
		RETVAL

Transform*
Transform::translate(x, y)
	float x
	float y
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = &THIS->translate(x,y);
	OUTPUT:
		RETVAL

Transform*
Transform::rotate(angle, ...)
	float angle
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		if(items == 2)
			RETVAL = &THIS->rotate(angle);
		else if(items == 4)
			RETVAL = &THIS->rotate(angle, SvNV(ST(2)), SvNV(ST(3)));
		else
			croak_xs_usage(cv, "THIS, angle, [ centerX, centerY ]");
	OUTPUT:
		RETVAL

Transform*
Transform::scale(x, y, ...)
	float x
	float y
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		if(items == 3)
			RETVAL = &THIS->scale(x, y);
		else if(items == 5)
			RETVAL = &THIS->scale(x, y, SvNV(ST(3)), SvNV(ST(4)));
		else
			croak_xs_usage(cv, "THIS, x, y, [ centerX, centerY ]");
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Transformable

Transformable*
Transformable::new(...)
	CODE:
		if(items == 1)
			RETVAL = new Transformable();
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Transformable"))
			RETVAL = new Transformable(*((Transformable*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, [ copy ]");
	OUTPUT:
		RETVAL

void
Transformable::DESTROY()

void
Transformable::setPosition(x,y)
	float x
	float y

void
Transformable::setRotation(angle)
	float angle

void
Transformable::setScale(factorX, factorY)
	float factorX
	float factorY

void
Transformable::setOrigin(x,y)
	float x
	float y

void
Transformable::getPosition()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getPosition();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
Transformable::getScale()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getScale();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

void
Transformable::getOrigin()
	CODE:
		EXTEND(SP,2);
		Vector2f r = THIS->getOrigin();
		XPUSHs(sv_2mortal(newSVnv(r.x)));
		XPUSHs(sv_2mortal(newSVnv(r.y)));

float
Transformable::getRotation()

void
Transformable::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
Transformable::rotate(angle)
	float angle

void
Transformable::scale(factorX, factorY)
	float factorX
	float factorY

Transform*
Transformable::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
Transformable::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL

MODULE = SFML		PACKAGE = SFML::Graphics::Vertex

Vertex*
Vertex::new(...)
	CODE:
		if(items == 1)
			RETVAL = new Vertex();
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::Vertex"))
			RETVAL = new Vertex(*((Vertex*)SvIV(SvRV(ST(1)))));
		else if(items == 3)
			RETVAL = new Vertex(Vector2f(SvNV(ST(1)), SvNV(ST(2))));
		else if((items == 4 || items == 6) && SvTYPE(SvRV(ST(3))) == SVt_PVMG && sv_isa(ST(3), "SFML::Graphics::Color")) {
			if(items == 4)
				RETVAL = new Vertex(Vector2f(SvNV(ST(1)), SvNV(ST(2))), *((Color*)SvIV(SvRV(ST(3)))));
			else
				RETVAL = new Vertex(Vector2f(SvNV(ST(1)), SvNV(ST(2))), *((Color*)SvIV(SvRV(ST(3)))), Vector2f(SvNV(ST(4)), SvNV(ST(5))));
		} else if (items == 5)
			RETVAL = new Vertex(Vector2f(SvNV(ST(1)), SvNV(ST(2))), Vector2f(SvNV(ST(4)), SvNV(ST(5))));
		else
			croak_xs_usage(cv, "THIS, [ ( copy | thePosition [, ( theColor [ u, v ] | u, v ) ] ]");
	OUTPUT:
		RETVAL

void
Vertex::DESTROY()

void
Vertex::getPosition()
	CODE:
		EXTEND(SP,2);
		XPUSHs(sv_2mortal(newSVnv(THIS->position.x)));
		XPUSHs(sv_2mortal(newSVnv(THIS->position.y)));

void
Vertex::setPosition(x,y)
	float x
	float y
	CODE:
		THIS->position.x = x;
		THIS->position.y = y;

void
Vertex::setColor(color)
	Color* color
	CODE:
		THIS->color = *color;

Color*
Vertex::getColor()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Color";
	CODE:
		RETVAL = new Color(THIS->color);
	OUTPUT:
		RETVAL

void
Vertex::getTexCoords()
	CODE:
		EXTEND(SP,2);
		XPUSHs(sv_2mortal(newSVnv(THIS->texCoords.x)));
		XPUSHs(sv_2mortal(newSVnv(THIS->texCoords.y)));

void
Vertex::setTexCoords(x,y)
	float x
	float y
	CODE:
		THIS->texCoords.x = x;
		THIS->texCoords.y = y;

MODULE = SFML		PACKAGE = SFML::Graphics::VertexArray

VertexArray*
VertexArray::new(...)
	CODE:
		if(items == 1)
			RETVAL = new VertexArray();
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::VertexArray"))
			RETVAL = new VertexArray(*((VertexArray*)SvIV(SvRV(ST(1)))));
		else if(items == 2)
			RETVAL = new VertexArray((PrimitiveType)SvIV(ST(1)));
		else if(items == 3)
			RETVAL = new VertexArray((PrimitiveType)SvIV(ST(1)), SvUV(ST(2)));
		else
			croak_xs_usage(cv, "THIS, [ ( copy | type, vertexCount=0 ]");
	OUTPUT:
		RETVAL

void
VertexArray::DESTROY()

unsigned int
VertexArray::getVertexCount()

Vertex*
VertexArray::get(index)
	unsigned int index
	PREINIT:
		const char * CLASS = "SFML::Graphics::Vertex";
	CODE:
		RETVAL = &((*THIS)[index]);
	OUTPUT:
		RETVAL

void
VertexArray::set(index, vertex)
	unsigned int index
	Vertex* vertex
	CODE:
		(*THIS)[index] = *vertex;

void
VertexArray::clear()

void
VertexArray::resize(vertexCount)
	unsigned int vertexCount

void
VertexArray::append(vertex)
	Vertex* vertex
	CODE:
		THIS->append(*vertex);

void
VertexArray::setPrimitiveType(type)
	int type
	CODE:
		THIS->setPrimitiveType((PrimitiveType)type);

int
VertexArray::getPrimitiveType()

void
VertexArray::getBounds()
	CODE:
		EXTEND(SP,4);
		FloatRect bounds = THIS->getBounds();
		XPUSHs(sv_2mortal(newSViv(bounds.top)));
		XPUSHs(sv_2mortal(newSViv(bounds.left)));
		XPUSHs(sv_2mortal(newSViv(bounds.width)));
		XPUSHs(sv_2mortal(newSViv(bounds.height)));

MODULE = SFML		PACKAGE = SFML::Graphics::View

View*
View::new(...)
	CODE:
		if(items == 1)
			RETVAL = new View();
		else if(items == 2 && SvTYPE(SvRV(ST(1))) == SVt_PVMG && sv_isa(ST(1), "SFML::Graphics::View"))
			RETVAL = new View(*((View*)SvIV(SvRV(ST(1)))));
		else
			croak_xs_usage(cv, "THIS, [ copy ]");
	OUTPUT:
		RETVAL

void
View::DESTROY()

void
View::setCenter(x, y)
	float x
	float y

void
View::setSize(width, height)
	float width
	float height

void
View::setRotation(angle)
	float angle

void
View::setViewport(top, left, width, height)
	float top
	float left
	float width
	float height
	CODE:
		THIS->setViewport(FloatRect(top, left, width, height));

void
View::reset(top, left, width, height)
	float top
	float left
	float width
	float height
	CODE:
		THIS->setViewport(FloatRect(top, left, width, height));

void
View::getCenter()
	CODE:
		Vector2f v = THIS->getCenter();
		EXTEND(SP,1);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

void
View::getSize()
	CODE:
		Vector2f v = THIS->getSize();
		EXTEND(SP,1);
		XPUSHs(sv_2mortal(newSVnv(v.x)));
		XPUSHs(sv_2mortal(newSVnv(v.y)));

float
View::getRotation()

void
View::getViewport()
	CODE:
		EXTEND(SP,4);
		FloatRect r = THIS->getViewport();
		XPUSHs(sv_2mortal(newSVnv(r.top)));
		XPUSHs(sv_2mortal(newSVnv(r.left)));
		XPUSHs(sv_2mortal(newSVnv(r.width)));
		XPUSHs(sv_2mortal(newSVnv(r.height)));

void
View::move(offsetX, offsetY)
	float offsetX
	float offsetY

void
View::rotate(angle)
	float angle

void
View::zoom(factor)
	float factor

Transform*
View::getTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getTransform());
	OUTPUT:
		RETVAL

Transform*
View::getInverseTransform()
	PREINIT:
		const char * CLASS = "SFML::Graphics::Transform";
	CODE:
		RETVAL = new Transform(THIS->getInverseTransform());
	OUTPUT:
		RETVAL
