#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "hpdf.h"

void
error_handler  (HPDF_STATUS   error_no,
                HPDF_STATUS   detail_no,
                void         *user_data)
{
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVuv((HPDF_UINT)error_no)));
	XPUSHs(sv_2mortal(newSVuv((HPDF_UINT)detail_no)));
	PUTBACK;

	call_pv("PDF::Haru::_ErrorHandler", G_DISCARD);

	FREETMPS;
	LEAVE;
}

typedef HPDF_Doc	PDF__Haru;
typedef HPDF_Page	PDF__Haru__Page;
typedef HPDF_Font	PDF__Haru__Font;
typedef HPDF_ExtGState PDF__Haru__ExtGState;
typedef HPDF_Encoder	PDF__Haru__Encoder;
typedef HPDF_Outline	PDF__Haru__Outline;
typedef HPDF_Image	PDF__Haru__Image;
typedef HPDF_Destination	PDF__Haru__Destination;
typedef HPDF_Annotation	PDF__Haru__Annotation;

MODULE = PDF::Haru		PACKAGE = PDF::Haru		

PROTOTYPES: DISABLE

PDF::Haru
New()
	CODE:
	RETVAL = HPDF_New(error_handler,NULL);
	OUTPUT:
	RETVAL

void
Free(pdf)
	PDF::Haru pdf
	CODE:
	HPDF_Free(pdf);

HPDF_STATUS
NewDoc  (pdf)
	PDF::Haru  pdf
	CODE:
	RETVAL = HPDF_NewDoc(pdf);
	OUTPUT:
	RETVAL	

void
FreeDoc  (pdf)
	PDF::Haru pdf
	CODE:
	HPDF_FreeDoc  (pdf);
	
void
FreeDocAll  (pdf)
	PDF::Haru pdf
	CODE:
	HPDF_FreeDocAll  (pdf);
	
HPDF_STATUS
SaveToFile(pdf,filename)
	PDF::Haru pdf
	char* filename	
	CODE:
	RETVAL = HPDF_SaveToFile(pdf,filename);
    OUTPUT:
    RETVAL
	
void
SaveAsString(pdf)
	PDF::Haru pdf
	PREINIT:
	unsigned char * buf;
	unsigned int siz;
	PPCODE:
	HPDF_SaveToStream (pdf);
	HPDF_ResetStream (pdf);
	siz = HPDF_GetStreamSize  (pdf);
	buf = (unsigned char*)malloc(siz);
	HPDF_ReadFromStream (pdf, buf, &siz);
	XPUSHs(sv_2mortal(newSVpvn((const char*)buf,siz)));
	free(buf);
	
HPDF_STATUS
SetPagesConfiguration  (pdf, page_per_pages)
	PDF::Haru    pdf
	HPDF_UINT   page_per_pages
	CODE:
	RETVAL = HPDF_SetPagesConfiguration  (pdf, page_per_pages);
	OUTPUT:
	RETVAL	

HPDF_STATUS
SetPageLayout (pdf, layout)
	PDF::Haru pdf
	HPDF_PageLayout layout
	CODE:
	RETVAL = HPDF_SetPageLayout(pdf,layout);
	OUTPUT:
	RETVAL	

HPDF_PageLayout
GetPageLayout  (pdf);
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_GetPageLayout(pdf);
	OUTPUT:
	RETVAL	
	
HPDF_STATUS
SetPageMode  (pdf, mode)
	PDF::Haru pdf
	HPDF_PageMode mode
	CODE:
	RETVAL = HPDF_SetPageMode  (pdf, mode);   
	OUTPUT:
	RETVAL	

HPDF_PageMode
GetPageMode  (pdf);
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_GetPageMode(pdf);
	OUTPUT:
	RETVAL	

HPDF_STATUS
SetOpenAction  (pdf, open_action);
	PDF::Haru           pdf
	PDF::Haru::Destination   open_action
	CODE:
	RETVAL = HPDF_SetOpenAction  (pdf, open_action);
	OUTPUT:
	RETVAL	

PDF::Haru::Page
GetCurrentPage  (pdf)
	PDF::Haru pdf
	CODE:
	RETVAL = HPDF_GetCurrentPage  (pdf);
	OUTPUT:
	RETVAL	

PDF::Haru::Page
AddPage  (pdf)
	PDF::Haru pdf
	CODE:
	RETVAL = HPDF_AddPage  (pdf);
	OUTPUT:
	RETVAL	

PDF::Haru::Page
InsertPage  (pdf, target)
	PDF::Haru pdf
	PDF::Haru::Page target
	CODE:
	RETVAL = HPDF_InsertPage  (pdf,target);
	OUTPUT:
	RETVAL	

const char*
LoadType1FontFromFile  (pdf, afmfilename,  pfmfilename)
	PDF::Haru     pdf
	const char  *afmfilename
	const char  *pfmfilename
	CODE:
	RETVAL = HPDF_LoadType1FontFromFile  (pdf, afmfilename,  pfmfilename);
	OUTPUT:
	RETVAL	

const char*
LoadTTFontFromFile ( pdf, file_name, embedding)
	PDF::Haru         pdf
	const char      *file_name
	int        embedding
	CODE:
	RETVAL = HPDF_LoadTTFontFromFile ( pdf, file_name, embedding);
	OUTPUT:
	RETVAL	

const char*
LoadTTFontFromFile2 (pdf, file_name, index, embedding)
	PDF::Haru     pdf
	const char  *file_name
	unsigned int    index
	int    embedding
	CODE:
	RETVAL = HPDF_LoadTTFontFromFile2 (pdf, file_name, index, embedding);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
AddPageLabel  (pdf, page_num, style, first_page, prefix)
	PDF::Haru            pdf
	HPDF_UINT           page_num
	HPDF_PageNumStyle   style
	HPDF_UINT           first_page
	const char         *prefix
	CODE:
	RETVAL = HPDF_AddPageLabel  (pdf, page_num, style, first_page, prefix);
	OUTPUT:
	RETVAL

PDF::Haru::Font
GetFont  (pdf, font_name, encoding_name)
	PDF::Haru     pdf
	const char  *font_name
	const char  *encoding_name
	CODE:
	RETVAL = HPDF_GetFont(pdf, font_name, encoding_name);
	OUTPUT:
	RETVAL

HPDF_STATUS
UseJPFonts   (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseJPFonts   (pdf);
	OUTPUT:
	RETVAL

HPDF_STATUS
UseKRFonts   (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseKRFonts   (pdf);
	OUTPUT:
	RETVAL

HPDF_STATUS
UseCNSFonts   (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseCNSFonts   (pdf);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
UseCNTFonts   (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseCNTFonts   (pdf);
	OUTPUT:
	RETVAL

PDF::Haru::ExtGState
HPDF_CreateExtGState  (pdf);
	PDF::Haru  pdf
	CODE:
	RETVAL = HPDF_CreateExtGState   (pdf);
	OUTPUT:
	RETVAL
	
PDF::Haru::Encoder
GetEncoder (pdf, encoding_name);
	PDF::Haru pdf
	const char *encoding_name
	CODE:
	RETVAL = HPDF_GetEncoder   (pdf, encoding_name);
	OUTPUT:
	RETVAL
	
PDF::Haru::Encoder
GetCurrentEncoder (pdf);
	PDF::Haru pdf
	CODE:
	RETVAL = HPDF_GetCurrentEncoder   (pdf);
	OUTPUT:
	RETVAL
		
HPDF_STATUS
SetCurrentEncoder  (pdf, encoding_name)
	PDF::Haru     pdf
	const char  *encoding_name
	CODE:
	RETVAL = HPDF_SetCurrentEncoder (pdf, encoding_name);
	OUTPUT:
	RETVAL

HPDF_STATUS
UseJPEncodings  (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseJPEncodings   (pdf);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
UseKREncodings  (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseKREncodings   (pdf);
	OUTPUT:
	RETVAL

HPDF_STATUS
UseCNSEncodings  (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseCNSEncodings   (pdf);
	OUTPUT:
	RETVAL

HPDF_STATUS
UseCNTEncodings  (pdf)
	PDF::Haru   pdf
	CODE:
	RETVAL = HPDF_UseCNTEncodings   (pdf);
	OUTPUT:
	RETVAL
	 
PDF::Haru::Outline
CreateOutline (pdf, parent, title, encoder);
	PDF::Haru pdf
	PDF::Haru::Outline parent
	const char *title
	PDF::Haru::Encoder encoder
	CODE:
	RETVAL = HPDF_CreateOutline   (pdf, parent, title, encoder);
	OUTPUT:
	RETVAL
	
PDF::Haru::Image
LoadPngImageFromFile (pdf, filename)
	PDF::Haru pdf
	const char *filename
	CODE:
	RETVAL = HPDF_LoadPngImageFromFile (pdf, filename);
	OUTPUT:
	RETVAL

PDF::Haru::Image
LoadPngImageFromFile2 (pdf, filename)
	PDF::Haru pdf
	const char *filename
	CODE:
	RETVAL = HPDF_LoadPngImageFromFile2 (pdf, filename);
	OUTPUT:
	RETVAL

PDF::Haru::Image
LoadJpegImageFromFile (pdf, filename)
	PDF::Haru pdf
	const char *filename
	CODE:
	RETVAL = HPDF_LoadJpegImageFromFile (pdf, filename);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetInfoAttr (pdf, type, value)
	PDF::Haru pdf
	HPDF_InfoType type
	const char  *value
	CODE:
	RETVAL = HPDF_SetInfoAttr (pdf, type, value);
	OUTPUT:
	RETVAL

const char*
GetInfoAttr (pdf,type);
	PDF::Haru  pdf
	HPDF_InfoType  type
	CODE:
	RETVAL = HPDF_GetInfoAttr (pdf, type);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetInfoDateAttr (pdf,type,year,month,day,hour,minutes,seconds,ind,off_hour,off_minutes)
	PDF::Haru       pdf
	HPDF_InfoType  type
	int year
	int month
	int day
	int hour
	int minutes
	int seconds
	char ind
	int off_hour
	int off_minutes 
	PREINIT:
	HPDF_Date date;
	CODE:
	date.year = year;
	date.month = month;
	date.day = day;
	date.hour = hour;
	date.minutes = minutes;
	date.seconds = seconds;
	date.ind = ind;
	date.off_hour = off_hour;
	date.off_minutes = off_minutes;
	RETVAL = HPDF_SetInfoDateAttr (pdf, type,date);
 	OUTPUT:
	RETVAL                                      

HPDF_STATUS
SetPassword  (pdf, owner_passwd, user_passwd)
	PDF::Haru      pdf
	const char   *owner_passwd
	const char   *user_passwd
	CODE:
	RETVAL = HPDF_SetPassword  (pdf, owner_passwd, user_passwd);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetPermission  (pdf, permission)
	PDF::Haru    pdf
	HPDF_UINT   permission
	CODE:
	RETVAL = HPDF_SetPermission  (pdf, permission);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetEncryptionMode  (pdf, mode, key_len)
	PDF::Haru           pdf
	HPDF_EncryptMode   mode
	HPDF_UINT          key_len
	CODE:
	RETVAL = HPDF_SetEncryptionMode  (pdf, mode, key_len);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetCompressionMode  (pdf, mode)
	PDF::Haru    pdf
	HPDF_UINT   mode
	CODE:
	RETVAL = HPDF_SetCompressionMode  (pdf, mode);
	OUTPUT:
	RETVAL

MODULE = PDF::Haru		PACKAGE = PDF::Haru::Page

HPDF_STATUS
SetWidth  (page, value)
	PDF::Haru::Page   page
	HPDF_REAL   value
	CODE:
	RETVAL = HPDF_Page_SetWidth  (page, value);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetHeight  (page, value)
	PDF::Haru::Page   page
	HPDF_REAL   value
	CODE:
	RETVAL = HPDF_Page_SetHeight  (page, value);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetSize  (page, size, direction)
	PDF::Haru::Page            page
	HPDF_PageSizes       size
	HPDF_PageDirection   direction
	CODE:
	RETVAL = HPDF_Page_SetSize  (page, size, direction);
	OUTPUT:
	RETVAL

void
SetRotate  (page,  angle)
	PDF::Haru::Page     page
	HPDF_UINT16   angle
	CODE:
	HPDF_Page_SetRotate  (page,  angle);

HPDF_REAL
GetWidth  (page)
	PDF::Haru::Page   page
	CODE:
	RETVAL = HPDF_Page_GetWidth  (page);
	OUTPUT:
	RETVAL

HPDF_REAL
GetHeight  (page)
	PDF::Haru::Page   page
	CODE:
	RETVAL = HPDF_Page_GetHeight  (page);
	OUTPUT:
	RETVAL

PDF::Haru::Destination
CreateDestination  (page)
	PDF::Haru::Page   page
	CODE:
	RETVAL = HPDF_Page_CreateDestination  (page);
	OUTPUT:
	RETVAL

PDF::Haru::Annotation
CreateTextAnnot (page,text,encoder,left,bottom,right,top);
	PDF::Haru::Page       page
	const char     *text
	PDF::Haru::Encoder    encoder
	float left
	float bottom
	float right
	float top
	PREINIT:
	HPDF_Rect rect;
	CODE:
	rect.left = left;
	rect.bottom = bottom;
	rect.right = right;
	rect.top = top;
	RETVAL = HPDF_Page_CreateTextAnnot  (page,rect,text,encoder);
	OUTPUT:
	RETVAL

PDF::Haru::Annotation
CreateLinkAnnot (page,dst,left,bottom,right,top);
	PDF::Haru::Page       page
	PDF::Haru::Destination   dst
	float left
	float bottom
	float right
	float top
	PREINIT:
	HPDF_Rect       rect;
	CODE:
	rect.left = left;
	rect.bottom = bottom;
	rect.right = right;
	rect.top = top;
	RETVAL = HPDF_Page_CreateLinkAnnot  (page,rect,dst);
	OUTPUT:
	RETVAL

PDF::Haru::Annotation
CreateURILinkAnnot (page,uri,left,bottom,right,top);
	PDF::Haru::Page       page
	const char   *uri
	float left
	float bottom
	float right
	float top
	PREINIT:
	HPDF_Rect       rect;
	CODE:
	rect.left = left;
	rect.bottom = bottom;
	rect.right = right;
	rect.top = top;
	RETVAL = HPDF_Page_CreateURILinkAnnot  (page,rect,uri);
	OUTPUT:
	RETVAL

HPDF_REAL
TextWidth  (page, text)
	PDF::Haru::Page    page
	const char  *text
	CODE:
	RETVAL = HPDF_Page_TextWidth  (page, text);
	OUTPUT:
	RETVAL

HPDF_UINT
MeasureText  (page, text, width, wordwrap)
	PDF::Haru::Page    page
	const char  *text
	HPDF_REAL    width
	int    wordwrap
	CODE:
	RETVAL = HPDF_Page_MeasureText  (page, text, width, wordwrap,NULL);
	OUTPUT:
	RETVAL

unsigned short
GetGMode (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetGMode  (page);
	OUTPUT:
	RETVAL
	
void
GetCurrentPos  (page)
	PDF::Haru::Page   page
	PREINIT:
	HPDF_Point point;
	PPCODE:
	point = HPDF_Page_GetCurrentPos  (page);
	XPUSHs(sv_2mortal(newSVnv(point.x)));
	XPUSHs(sv_2mortal(newSVnv(point.y)));

void
GetCurrentTextPos  (page)
	PDF::Haru::Page   page
	PREINIT:
	HPDF_Point point;
	PPCODE:
	point = HPDF_Page_GetCurrentTextPos  (page);
	XPUSHs(sv_2mortal(newSVnv(point.x)));
	XPUSHs(sv_2mortal(newSVnv(point.y)));

PDF::Haru::Font
GetCurrentFont  (page)
	PDF::Haru::Page   page
	CODE:
	RETVAL = HPDF_Page_GetCurrentFont  (page);
	OUTPUT:
	RETVAL

HPDF_REAL
GetCurrentFontSize  (page)
	PDF::Haru::Page   page
	CODE:
	RETVAL = HPDF_Page_GetCurrentFontSize  (page);
	OUTPUT:
	RETVAL

void 
GetTransMatrix (page)
	PDF::Haru::Page   page
	PREINIT:
	HPDF_TransMatrix matrix;
	PPCODE:
	matrix = HPDF_Page_GetTransMatrix  (page);
	XPUSHs(sv_2mortal(newSVnv(matrix.a)));
	XPUSHs(sv_2mortal(newSVnv(matrix.b)));	
	XPUSHs(sv_2mortal(newSVnv(matrix.c)));
	XPUSHs(sv_2mortal(newSVnv(matrix.d)));	
	XPUSHs(sv_2mortal(newSVnv(matrix.x)));
	XPUSHs(sv_2mortal(newSVnv(matrix.y)));	

float
GetLineWidth (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_GetLineWidth  (page);
	OUTPUT:
	RETVAL

HPDF_LineCap
GetLineCap  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_GetLineCap  (page);
	OUTPUT:
	RETVAL

HPDF_LineJoin
GetLineJoin  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_GetLineJoin  (page);
	OUTPUT:
	RETVAL

float
GetMiterLimit (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_GetMiterLimit(page);
	OUTPUT:
	RETVAL

void
GetDash (page)
	PDF::Haru::Page  page
	PREINIT:
	AV * ptn;
	int n;
	HPDF_DashMode mode;
	PPCODE:
	mode = HPDF_Page_GetDash (page);
	ptn = (AV *)sv_2mortal((SV *)newAV());
	for (n = 0; n < mode.num_ptn; n++) {
		av_push(ptn, newSViv(mode.ptn[n]));
	}
	XPUSHs(newRV((SV *)ptn));	
	XPUSHs(sv_2mortal(newSViv(mode.phase)));	

float
GetFlat (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetFlat (page);
	OUTPUT:
	RETVAL

float
GetCharSpace (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetCharSpace (page);
	OUTPUT:
	RETVAL

float
GetWordSpace (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetWordSpace (page);
	OUTPUT:
	RETVAL

float
GetHorizontalScalling (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetHorizontalScalling (page);
	OUTPUT:
	RETVAL

float
GetTextLeading (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetTextLeading (page);
	OUTPUT:
	RETVAL

float
GetTextRenderingMode (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetTextRenderingMode (page);
	OUTPUT:
	RETVAL

float
GetTextRise (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetTextRise (page);
	OUTPUT:
	RETVAL

void
GetRGBFill (page)
	PDF::Haru::Page page
	PREINIT:
	HPDF_RGBColor color;
	PPCODE:
	color = HPDF_Page_GetRGBFill (page);
	XPUSHs(sv_2mortal(newSVnv(color.r)));
	XPUSHs(sv_2mortal(newSVnv(color.g)));
	XPUSHs(sv_2mortal(newSVnv(color.b)));

void
GetRGBStroke (page)
	PDF::Haru::Page page
	PREINIT:
	HPDF_RGBColor color;
	PPCODE:
	color = HPDF_Page_GetRGBStroke (page);
	XPUSHs(sv_2mortal(newSVnv(color.r)));
	XPUSHs(sv_2mortal(newSVnv(color.g)));
	XPUSHs(sv_2mortal(newSVnv(color.b)));

void
GetCMYKFill (page)
	PDF::Haru::Page page
	PREINIT:
	HPDF_CMYKColor color;
	PPCODE:
	color = HPDF_Page_GetCMYKFill (page);
	XPUSHs(sv_2mortal(newSVnv(color.c)));
	XPUSHs(sv_2mortal(newSVnv(color.m)));
	XPUSHs(sv_2mortal(newSVnv(color.y)));
	XPUSHs(sv_2mortal(newSVnv(color.k)));

void
GetCMYKStroke (page)
	PDF::Haru::Page page
	PREINIT:
	HPDF_CMYKColor color;
	PPCODE:
	color = HPDF_Page_GetCMYKStroke (page);
	XPUSHs(sv_2mortal(newSVnv(color.c)));
	XPUSHs(sv_2mortal(newSVnv(color.m)));
	XPUSHs(sv_2mortal(newSVnv(color.y)));
	XPUSHs(sv_2mortal(newSVnv(color.k)));

float
GetGrayFill (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetGrayFill (page);
	OUTPUT:
	RETVAL
	
float
GetGrayStroke (page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetGrayStroke (page);
	OUTPUT:
	RETVAL

HPDF_ColorSpace
GetStrokingColorSpace(page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetStrokingColorSpace (page);
	OUTPUT:
	RETVAL

HPDF_ColorSpace
GetFillingColorSpace(page)
	PDF::Haru::Page page
	CODE:
	RETVAL = HPDF_Page_GetFillingColorSpace (page);
	OUTPUT:
	RETVAL

void 
GetTextMatrix (page)
	PDF::Haru::Page   page
	PREINIT:
	HPDF_TransMatrix matrix;
	PPCODE:
	matrix = HPDF_Page_GetTextMatrix  (page);
	XPUSHs(sv_2mortal(newSVnv(matrix.a)));
	XPUSHs(sv_2mortal(newSVnv(matrix.b)));	
	XPUSHs(sv_2mortal(newSVnv(matrix.c)));
	XPUSHs(sv_2mortal(newSVnv(matrix.d)));	
	XPUSHs(sv_2mortal(newSVnv(matrix.x)));
	XPUSHs(sv_2mortal(newSVnv(matrix.y)));	

HPDF_UINT
GetGStateDepth (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_GetGStateDepth  (page);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetSlideShow  (page,type,disp_time,trans_time)
	PDF::Haru::Page            page
	HPDF_TransitionStyle   type
	HPDF_REAL            disp_time
	HPDF_REAL            trans_time
	CODE:
	RETVAL = HPDF_Page_SetSlideShow  (page,type,disp_time,trans_time);
	OUTPUT:
	RETVAL	

HPDF_STATUS
Arc  (page, x, y, ray, ang1, ang2)
	PDF::Haru::Page    page
	HPDF_REAL    x
	HPDF_REAL    y
	HPDF_REAL    ray
	HPDF_REAL    ang1
	HPDF_REAL    ang2
	CODE:
	RETVAL = HPDF_Page_Arc  (page, x, y, ray, ang1, ang2);
	OUTPUT:
	RETVAL

HPDF_STATUS
BeginText(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_BeginText(page);
	OUTPUT:
	RETVAL

HPDF_STATUS
Circle  (page, x, y, ray)
	PDF::Haru::Page     page
	HPDF_REAL     x
	HPDF_REAL     y
	HPDF_REAL     ray
	CODE:
	RETVAL = HPDF_Page_Circle  (page, x, y, ray);
	OUTPUT:
	RETVAL

HPDF_STATUS
Clip  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_Clip  (page);
	OUTPUT:
	RETVAL

HPDF_STATUS
ClosePath  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_ClosePath  (page);
	OUTPUT:
	RETVAL

HPDF_STATUS
ClosePathStroke  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_ClosePathStroke  (page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
ClosePathEofillStroke(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_ClosePathEofillStroke(page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
ClosePathFillStroke(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_ClosePathFillStroke(page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
Concat  (page, a, b, c, d, x, y)
	PDF::Haru::Page    page
	HPDF_REAL    a
	HPDF_REAL    b
	HPDF_REAL    c
	HPDF_REAL    d
	HPDF_REAL    x
	HPDF_REAL    y
	CODE:
	RETVAL = HPDF_Page_Concat  (page, a, b, c, d, x, y);
	OUTPUT:
	RETVAL
			
HPDF_STATUS
CurveTo  (page,  x1, y1, x2, y2, x3, y3)
	PDF::Haru::Page    page
	HPDF_REAL    x1
	HPDF_REAL    y1
	HPDF_REAL    x2
	HPDF_REAL    y2
	HPDF_REAL    x3
	HPDF_REAL    y3
	CODE:
	RETVAL = HPDF_Page_CurveTo  (page,  x1, y1, x2, y2, x3, y3);
	OUTPUT:
	RETVAL

HPDF_STATUS
CurveTo2  (page,  x2, y2, x3, y3)
	PDF::Haru::Page    page
	HPDF_REAL    x2
	HPDF_REAL    y2
	HPDF_REAL    x3
	HPDF_REAL    y3
	CODE:
	RETVAL = HPDF_Page_CurveTo2 (page, x2, y2, x3, y3);
	OUTPUT:
	RETVAL

HPDF_STATUS
CurveTo3  (page,  x1, y1, x3, y3)
	PDF::Haru::Page    page
	HPDF_REAL    x1
	HPDF_REAL    y1
	HPDF_REAL    x3
	HPDF_REAL    y3
	CODE:
	RETVAL = HPDF_Page_CurveTo3  (page,  x1, y1, x3, y3);
	OUTPUT:
	RETVAL

HPDF_STATUS
DrawImage  (page, image, x, y, width, height)
	PDF::Haru::Page    page
	PDF::Haru::Image   image
	HPDF_REAL    x
	HPDF_REAL    y
	HPDF_REAL    width
	HPDF_REAL    height
	CODE:
	RETVAL = HPDF_Page_DrawImage  (page, image, x, y, width, height);
	OUTPUT:
	RETVAL

HPDF_STATUS
Ellipse  (page, x, y, xray, yray)
	PDF::Haru::Page     page
	HPDF_REAL     x
	HPDF_REAL     y
	HPDF_REAL     xray
	HPDF_REAL     yray
	CODE:
	RETVAL = HPDF_Page_Ellipse  (page, x, y, xray, yray);
	OUTPUT:
	RETVAL

HPDF_STATUS
EndPath(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_EndPath(page);
	OUTPUT:
	RETVAL

HPDF_STATUS
EndText(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_EndText(page);
	OUTPUT:
	RETVAL

HPDF_STATUS
Eoclip  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_Eoclip  (page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
Eofill(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_Eofill(page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
EofillStroke(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_EofillStroke(page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
Fill(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_Fill(page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
FillStroke(page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_FillStroke(page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
GRestore  (page)
	PDF::Haru::Page    page
	CODE:
	RETVAL = HPDF_Page_GRestore  (page);
	OUTPUT:
	RETVAL
		
HPDF_STATUS
GSave  (page)
	PDF::Haru::Page    page
	CODE:
	RETVAL = HPDF_Page_GSave  (page);
	OUTPUT:
	RETVAL

HPDF_STATUS
LineTo  (page, x, y)
	PDF::Haru::Page  page
	HPDF_REAL  x
	HPDF_REAL  y
	CODE:
	RETVAL = HPDF_Page_LineTo  (page, x, y);
	OUTPUT:
	RETVAL

HPDF_STATUS
MoveTextPos  (page, x, y)
	PDF::Haru::Page  page
	HPDF_REAL  x
	HPDF_REAL  y
	CODE:
	RETVAL = HPDF_Page_MoveTextPos  (page, x, y);
	OUTPUT:
	RETVAL

HPDF_STATUS
MoveTextPos2  (page, x, y)
	PDF::Haru::Page  page
	HPDF_REAL  x
	HPDF_REAL  y
	CODE:
	RETVAL = HPDF_Page_MoveTextPos2  (page, x, y);
	OUTPUT:
	RETVAL

HPDF_STATUS
MoveTo  (page, x, y)
	PDF::Haru::Page  page
	HPDF_REAL  x
	HPDF_REAL  y
	CODE:
	RETVAL = HPDF_Page_MoveTo  (page, x, y);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
MoveToNextLine  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_MoveToNextLine  (page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
Rectangle  (page, x, y, width, height)
	PDF::Haru::Page  page
	HPDF_REAL  x
	HPDF_REAL  y
	HPDF_REAL  width
	HPDF_REAL  height
	CODE:
	RETVAL = HPDF_Page_Rectangle  (page, x, y, width, height);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetCharSpace  (page, value)
	PDF::Haru::Page  page
	HPDF_REAL  value
	CODE:
	RETVAL = HPDF_Page_SetCharSpace  (page, value);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetCMYKFill  (page, c, m, y, k)
	PDF::Haru::Page  page
	HPDF_REAL  c
	HPDF_REAL  m
	HPDF_REAL  y
	HPDF_REAL  k
	CODE:
	RETVAL = HPDF_Page_SetCMYKFill  (page, c, m, y, k);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetCMYKStroke  (page, c, m, y, k)
	PDF::Haru::Page  page
	HPDF_REAL  c
	HPDF_REAL  m
	HPDF_REAL  y
	HPDF_REAL  k
	CODE:
	RETVAL = HPDF_Page_SetCMYKStroke (page, c, m, y, k);
	OUTPUT:
	RETVAL
				
HPDF_STATUS
SetDash  (page,dash_ptn,phase)
	PDF::Haru::Page page
	SV * dash_ptn
	HPDF_UINT  phase
	PREINIT:
	HPDF_UINT16  ptn[8];
	int num_elem;
	int n;
	CODE:
	if ((!SvROK(dash_ptn)) || (SvTYPE(SvRV(dash_ptn)) != SVt_PVAV)) {
	   croak("not an array reference");
	}
    num_elem = av_len((AV *)SvRV(dash_ptn));
    if(num_elem > 7) { num_elem = 7; }
	for (n = 0; n <= num_elem; n++) {
		ptn[n] = SvIV(*av_fetch((AV *)SvRV(dash_ptn), n, 0));
	}
	RETVAL = HPDF_Page_SetDash  (page, ptn, num_elem + 1, phase);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetExtGState  (page, ext_gstate);
	PDF::Haru::Page        page
	PDF::Haru::ExtGState   ext_gstate
	CODE:
	RETVAL = HPDF_Page_SetExtGState  (page, ext_gstate);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetGrayFill  (page, gray)
	PDF::Haru::Page   page
	HPDF_REAL   gray
	CODE:
	RETVAL = HPDF_Page_SetGrayFill  (page, gray);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetGrayStroke  (page, gray)
	PDF::Haru::Page   page
	HPDF_REAL   gray
	CODE:
	RETVAL = HPDF_Page_SetGrayStroke  (page, gray);
	OUTPUT:
	RETVAL	

HPDF_STATUS
SetFontAndSize  (page, font, size)
	PDF::Haru::Page  page
	PDF::Haru::Font  font
	HPDF_REAL  size
	CODE:
	RETVAL = HPDF_Page_SetFontAndSize  (page, font, size);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetHorizontalScalling  (page, value)
	PDF::Haru::Page  page
	HPDF_REAL  value
	CODE:
	RETVAL = HPDF_Page_SetHorizontalScalling (page, value);
	OUTPUT:
	RETVAL	

HPDF_STATUS
SetLineCap  (page,line_cap)
	PDF::Haru::Page     page
	HPDF_LineCap  line_cap
	CODE:
	RETVAL = HPDF_Page_SetLineCap  (page,line_cap);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetLineJoin  (page, line_join)
	PDF::Haru::Page      page
	HPDF_LineJoin  line_join
	CODE:
	RETVAL = HPDF_Page_SetLineJoin  (page, line_join);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetLineWidth  (page, line_width)
	PDF::Haru::Page  page
	HPDF_REAL  line_width
	CODE:
	RETVAL = HPDF_Page_SetLineWidth  (page, line_width);
	OUTPUT:
	RETVAL		

HPDF_STATUS
SetMiterLimit  (page,miter_limit)
	PDF::Haru::Page  page
	HPDF_REAL  miter_limit
	CODE:
	RETVAL = HPDF_Page_SetMiterLimit  (page,miter_limit);
	OUTPUT:
	RETVAL	
	
HPDF_STATUS
SetRGBFill  (page, r, g, b)
	PDF::Haru::Page  page
	HPDF_REAL  r
	HPDF_REAL  g
	HPDF_REAL  b
	CODE:
	RETVAL = HPDF_Page_SetRGBFill  (page, r, g, b);
	OUTPUT:
	RETVAL						

HPDF_STATUS
SetRGBStroke  (page, r, g, b)
	PDF::Haru::Page  page
	HPDF_REAL  r
	HPDF_REAL  g
	HPDF_REAL  b
	CODE:
	RETVAL = HPDF_Page_SetRGBStroke  (page, r, g, b);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetTextLeading  (page, value)
	PDF::Haru::Page  page
	HPDF_REAL  value
	CODE:
	RETVAL = HPDF_Page_SetTextLeading (page, value);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetTextMatrix  (page,a,b,c,d,x,y)
	PDF::Haru::Page         page
	HPDF_REAL    a
	HPDF_REAL    b
	HPDF_REAL    c
	HPDF_REAL    d
	HPDF_REAL    x
	HPDF_REAL    y
	CODE:
	RETVAL = HPDF_Page_SetTextMatrix  (page,a,b,c,d,x,y);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetTextRenderingMode  (page, mode)
	PDF::Haru::Page               page
	HPDF_TextRenderingMode  mode
	CODE:
	RETVAL = HPDF_Page_SetTextRenderingMode  (page, mode);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetTextRise  (page, value)
	PDF::Haru::Page page
	float  value
	CODE:
	RETVAL = HPDF_Page_SetTextRise(page,value);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
SetWordSpace  (page, value)
	PDF::Haru::Page  page
	HPDF_REAL  value
	CODE:
	RETVAL = HPDF_Page_SetWordSpace  (page, value);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
ShowText  (page, text)
	PDF::Haru::Page    page
	char  *text
	CODE:
	RETVAL = HPDF_Page_ShowText  (page, text);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
ShowTextNextLine  (page, text)
	PDF::Haru::Page    page
	char  *text
	CODE:
	RETVAL = HPDF_Page_ShowTextNextLine  (page, text);
	OUTPUT:
	RETVAL				

HPDF_STATUS
ShowTextNextLineEx  (page,  word_space, char_space, text)
	PDF::Haru::Page    page
	HPDF_REAL    word_space
	HPDF_REAL    char_space
	char  *text
	CODE:
	RETVAL = HPDF_Page_ShowTextNextLineEx  (page,  word_space, char_space, text);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
Stroke  (page)
	PDF::Haru::Page  page
	CODE:
	RETVAL = HPDF_Page_Stroke  (page);
	OUTPUT:
	RETVAL
	
HPDF_STATUS
TextOut  (page, xpos, ypos, text)
	PDF::Haru::Page    page
	HPDF_REAL    xpos
	HPDF_REAL    ypos
	char  *text
	CODE:
	RETVAL = HPDF_Page_TextOut  (page, xpos, ypos, text);
	OUTPUT:
	RETVAL

HPDF_STATUS
TextRect  (page, left, top, right, bottom, text, align)
	PDF::Haru::Page            page
	HPDF_REAL            left
	HPDF_REAL            top
	HPDF_REAL            right
	HPDF_REAL            bottom
	char          *text
	HPDF_TextAlignment   align
	CODE:
	RETVAL = HPDF_Page_TextRect  (page, left,  top, right, bottom, text, align, NULL);
	OUTPUT:
	RETVAL	

MODULE = PDF::Haru		PACKAGE = PDF::Haru::Font

const char * 
GetFontName (font)
	PDF::Haru::Font font
	CODE:
	RETVAL = HPDF_Font_GetFontName (font);
	OUTPUT:
	RETVAL	

const char * 
GetEncodingName (font)
	PDF::Haru::Font font
	CODE:
	RETVAL = HPDF_Font_GetEncodingName (font);
	OUTPUT:
	RETVAL	

HPDF_INT 
GetUnicodeWidth (font, code)
	PDF::Haru::Font font
	HPDF_UINT16 code
	CODE:
	RETVAL = HPDF_Font_GetUnicodeWidth (font, code);
	OUTPUT:
	RETVAL	

void
GetBBox (font);
	PDF::Haru::Font font
	PREINIT:
	HPDF_Box box;
	PPCODE:
	box = HPDF_Font_GetBBox (font);
	XPUSHs(sv_2mortal(newSVnv(box.left)));
	XPUSHs(sv_2mortal(newSVnv(box.bottom)));
	XPUSHs(sv_2mortal(newSVnv(box.right)));
	XPUSHs(sv_2mortal(newSVnv(box.top)));
	
HPDF_INT 
GetAscent (font)
	PDF::Haru::Font font
	CODE:
	RETVAL = HPDF_Font_GetAscent (font);
	OUTPUT:
	RETVAL	

HPDF_INT 
GetDescent (font)
	PDF::Haru::Font font
	CODE:
	RETVAL = HPDF_Font_GetDescent (font);
	OUTPUT:
	RETVAL	
	
HPDF_UINT 
GetXHeight (font)
	PDF::Haru::Font font
	CODE:
	RETVAL = HPDF_Font_GetXHeight (font);
	OUTPUT:
	RETVAL

HPDF_UINT 
GetCapHeight (font)
	PDF::Haru::Font font
	CODE:
	RETVAL = HPDF_Font_GetCapHeight (font);
	OUTPUT:
	RETVAL

void 
TextWidth  (font,text,len);
	PDF::Haru::Font          font
	const char   *text
	HPDF_UINT          len
	PREINIT:
	HPDF_TextWidth textwidth;
	PPCODE:
	textwidth = HPDF_Font_TextWidth  (font,(const unsigned char*)text,len);
	XPUSHs(sv_2mortal(newSViv(textwidth.numchars)));
	XPUSHs(sv_2mortal(newSViv(textwidth.numwords)));
	XPUSHs(sv_2mortal(newSViv(textwidth.width)));
	XPUSHs(sv_2mortal(newSViv(textwidth.numspace)));	

HPDF_UINT 
MeasureText (font,text,len,width,font_size,char_space,word_space,wordwrap);
	PDF::Haru::Font          font
	const char   *text
	HPDF_UINT          len
	HPDF_REAL          width
	HPDF_REAL          font_size
	HPDF_REAL          char_space
	HPDF_REAL          word_space
	HPDF_BOOL          wordwrap
	CODE:
	RETVAL = HPDF_Font_MeasureText (font,(const unsigned char*)text,len,width,font_size,char_space,word_space,wordwrap,NULL);
	OUTPUT:
	RETVAL	

MODULE = PDF::Haru		PACKAGE = PDF::Haru::Annotation

HPDF_STATUS
LinkAnnot_SetHighlightMode (annot,mode)
	PDF::Haru::Annotation         annot
	HPDF_AnnotHighlightMode mode
	CODE:
	RETVAL = HPDF_LinkAnnot_SetHighlightMode (annot,mode);
	OUTPUT:
	RETVAL

HPDF_STATUS
LinkAnnot_SetBorderStyle  (annot,width,dash_on,dash_off)
	PDF::Haru::Annotation  annot
	HPDF_REAL        width
	HPDF_UINT16      dash_on
	HPDF_UINT16      dash_off
	CODE:
	RETVAL = HPDF_LinkAnnot_SetBorderStyle (annot,width,dash_on,dash_off);
	OUTPUT:
	RETVAL

HPDF_STATUS 
TextAnnot_SetIcon  (annot,icon)
	PDF::Haru::Annotation   annot
	HPDF_AnnotIcon    icon
	CODE:
	RETVAL = HPDF_TextAnnot_SetIcon  (annot,icon);
	OUTPUT:
	RETVAL

HPDF_STATUS
TextAnnot_SetOpened (annot,open)
	PDF::Haru::Annotation annot
	HPDF_BOOL       open
	CODE:
	RETVAL = HPDF_TextAnnot_SetOpened (annot,open);
	OUTPUT:
	RETVAL

MODULE = PDF::Haru		PACKAGE = PDF::Haru::Outline

HPDF_STATUS 
SetOpened  (outline,opened);
	PDF::Haru::Outline  outline
	HPDF_BOOL     opened
	CODE:
	RETVAL = HPDF_Outline_SetOpened (outline,opened);
	OUTPUT:
	RETVAL
	
HPDF_STATUS 
SetDestination  (outline,dst);
	PDF::Haru::Outline  outline
	PDF::Haru::Destination     dst
	CODE:
	RETVAL = HPDF_Outline_SetDestination (outline,dst);
	OUTPUT:
	RETVAL
	
MODULE = PDF::Haru		PACKAGE = PDF::Haru::Destination

HPDF_STATUS 
SetXYZ (dst,left,top,zoom)
	PDF::Haru::Destination  dst
	HPDF_REAL         left
	HPDF_REAL         top
	HPDF_REAL         zoom
	CODE:
	RETVAL = HPDF_Destination_SetXYZ (dst,left,top,zoom);
	OUTPUT:
	RETVAL	

HPDF_STATUS 
SetFit (dst)
	PDF::Haru::Destination  dst
	CODE:
	RETVAL = HPDF_Destination_SetFit (dst);
	OUTPUT:
	RETVAL	

HPDF_STATUS 
SetFitH (dst,top)
	PDF::Haru::Destination  dst
	HPDF_REAL         top
	CODE:
	RETVAL = HPDF_Destination_SetFitH (dst,top);
	OUTPUT:
	RETVAL	

HPDF_STATUS 
SetFitV  (dst,left)
	PDF::Haru::Destination  dst
	HPDF_REAL         left
	CODE:
	RETVAL = HPDF_Destination_SetFitV  (dst,left);
	OUTPUT:
	RETVAL	
	
HPDF_STATUS 
SetFitR  (dst,left,bottom,right,top)
	PDF::Haru::Destination  dst
	HPDF_REAL         left
	HPDF_REAL         bottom
	HPDF_REAL         right
	HPDF_REAL         top
	CODE:
	RETVAL = HPDF_Destination_SetFitR  (dst,left,bottom,right,top);
	OUTPUT:
	RETVAL		

HPDF_STATUS 
SetFitB (dst)
	PDF::Haru::Destination  dst
	CODE:
	RETVAL = HPDF_Destination_SetFitB (dst);
	OUTPUT:
	RETVAL		

HPDF_STATUS 
SetFitBH  (dst,top);
	PDF::Haru::Destination  dst
	HPDF_REAL         top
	CODE:
	RETVAL = HPDF_Destination_SetFitBH  (dst,top);
	OUTPUT:
	RETVAL	

HPDF_STATUS 
SetFitBV  (dst, top)
	PDF::Haru::Destination  dst
	HPDF_REAL         top
	CODE:
	RETVAL = HPDF_Destination_SetFitBV  (dst, top);
	OUTPUT:
	RETVAL	

MODULE = PDF::Haru		PACKAGE = PDF::Haru::Image

void
HPDF_Image_GetSize (image)
	PDF::Haru::Image image
	PREINIT:
	HPDF_Point point;
	PPCODE:
	point = HPDF_Image_GetSize (image);
	XPUSHs(sv_2mortal(newSVnv(point.x)));
	XPUSHs(sv_2mortal(newSVnv(point.y)));	

HPDF_UINT
GetWidth (image)
	PDF::Haru::Image  image
	CODE:
	RETVAL = HPDF_Image_GetWidth (image);
	OUTPUT:
	RETVAL

HPDF_UINT
GetHeight (image)
	PDF::Haru::Image  image
	CODE:
	RETVAL = HPDF_Image_GetHeight (image);
	OUTPUT:
	RETVAL

HPDF_UINT
GetBitsPerComponent (image)
	PDF::Haru::Image  image
	CODE:
	RETVAL = HPDF_Image_GetBitsPerComponent (image);
	OUTPUT:
	RETVAL

const char*
GetColorSpace(image)
	PDF::Haru::Image  image
	CODE:
	RETVAL = HPDF_Image_GetColorSpace(image);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetColorMask (image, rmin, rmax, gmin, gmax, bmin, bmax)
	PDF::Haru::Image   image
	HPDF_UINT    rmin
	HPDF_UINT    rmax
	HPDF_UINT    gmin
	HPDF_UINT    gmax
	HPDF_UINT    bmin
	HPDF_UINT    bmax
	CODE:
	RETVAL = HPDF_Image_SetColorMask (image, rmin, rmax, gmin, gmax, bmin, bmax);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetMaskImage  (image, mask_image)
	PDF::Haru::Image   image
	PDF::Haru::Image   mask_image
	CODE:
	RETVAL = HPDF_Image_SetMaskImage  (image, mask_image);
	OUTPUT:
	RETVAL

MODULE = PDF::Haru		PACKAGE = PDF::Haru::ExtGState

HPDF_STATUS
SetAlphaStroke  (ext_gstate, value)
	PDF::Haru::ExtGState   ext_gstate
	HPDF_REAL        value
	CODE:
	RETVAL = HPDF_ExtGState_SetAlphaStroke  (ext_gstate, value);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetAlphaFill  (ext_gstate, value)
	PDF::Haru::ExtGState   ext_gstate
	HPDF_REAL        value
	CODE:
	RETVAL = HPDF_ExtGState_SetAlphaFill  (ext_gstate, value);
	OUTPUT:
	RETVAL

HPDF_STATUS
SetBlendMode  (ext_gstate, bmode)
	PDF::Haru::ExtGState   ext_gstate
	HPDF_BlendMode   bmode
	CODE:
	RETVAL = HPDF_ExtGState_SetBlendMode  (ext_gstate, bmode);
	OUTPUT:
	RETVAL
