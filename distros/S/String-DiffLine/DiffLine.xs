#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = String::DiffLine		PACKAGE = String::DiffLine		

PROTOTYPES: ENABLE

void 
diffline(s1,s2)
  char *s1;
  char *s2;
  PREINIT:
    STRLEN l,l1,l2,nll,i,lpos,lines;
    char *nl,lnl;
  PPCODE:
    l1=SvCUR(ST(0));
    l2=SvCUR(ST(1));
    nl=SvPV(perl_get_sv("/",FALSE),nll);
    if(nll==0) nl="\n";
    lnl=nl[nll?nll-1:0];
    lpos=0;lines=1;
    EXTEND(sp,3);
    /*printf("s1=%s l1=%d s2=%s l2=%d nl=%s nll=%d\n",s1,l1,s2,l2,nl,nll);*/
    l=l1<l2?l1:l2;
    for(i=0;i<l;i++)
    {
      if(s1[i]!=s2[i])
      {
        PUSHs(sv_2mortal(newSViv(i)));
        PUSHs(sv_2mortal(newSViv(lines)));
        PUSHs(sv_2mortal(newSViv(i-lpos)));
        XSRETURN(3);
      }
	  /* check if we're at last character of end-of-line 'nl' */
      if(s1[i]==lnl &&
         (nll==1 || 
          (nll?i-lpos+1>=nll && memcmp(s1+i-nll+1,nl,nll)==0:
               i==l-1 || s1[i+1]!=lnl)))
          lines++,lpos=i+1;
    }
    if(l1==l2)
      PUSHs(&PL_sv_undef);
    else
      PUSHs(sv_2mortal(newSViv(l)));
    PUSHs(sv_2mortal(newSViv(lines)));
    PUSHs(sv_2mortal(newSViv(i-lpos)));
    
  
