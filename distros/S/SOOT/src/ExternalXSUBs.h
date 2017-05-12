#ifndef __ExternalXSUBs_h_
#define __ExternalXSUBs_h_
extern "C" void XS_TObject_DESTROY(pTHX_ CV* cv);
extern "C" void XS_TObject_keep(pTHX_ CV* cv);
extern "C" void XS_TObject_as(pTHX_ CV* cv);
extern "C" void XS_TObject_delete(pTHX_ CV* cv);
#endif

