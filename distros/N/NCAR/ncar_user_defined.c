

void agchnl_( 
  int* IAXS,       /* INTEGER IAXS       */
  float* VILS,     /* REAL VILS          */
  char* CHRM,      /* CHARACTER*(*) CHRM */
  int* MCIM,       /* length of CHRM     */
  int* NCIM,       /* INTEGER NCIM       */
  int* IPXM,       /* INTEGER IPXM       */
  char* CHRE,      /* CHARACTER*(*) CHRE */
  int* MCIE,       /* length of CHRE     */
  int* NCIE,       /* INTEGER NCIE       */
  long CHRM_len,
  long CHRE_len
) {
    const char* name = "NCAR::agchnl";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncaragchnl_( 
            IAXS, VILS, CHRM, MCIM, NCIM, IPXM, CHRE, MCIE, NCIE,
            CHRM_len, CHRE_len
      );

    } else {
    
      dSP;

      SV* sv_IAXS;
      SV* sv_VILS;
      SV* sv_CHRM;
      SV* sv_MCIM;
      SV* sv_NCIM;
      SV* sv_IPXM;
      SV* sv_CHRE;
      SV* sv_MCIE;
      SV* sv_NCIE;

      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IAXS = sv_2mortal( newSViv( ( IV )( *IAXS ) ) );
      sv_VILS = sv_2mortal( newSVnv( ( NV )( *VILS ) ) );
      sv_CHRM = sv_2mortal( newSVpv( CHRM, (STRLEN)CHRM_len ) );
      sv_MCIM = sv_2mortal( newSViv( ( IV )( *MCIM ) ) );
      sv_NCIM = sv_2mortal( newSViv( ( IV )( *NCIM ) ) );
      sv_IPXM = sv_2mortal( newSViv( ( IV )( *IPXM ) ) );
      sv_CHRE = sv_2mortal( newSVpv( CHRE, (STRLEN)CHRE_len ) );
      sv_MCIE = sv_2mortal( newSViv( ( IV )( *MCIE ) ) );
      sv_NCIE = sv_2mortal( newSViv( ( IV )( *NCIE ) ) );
      
      XPUSHs( sv_IAXS );
      XPUSHs( sv_VILS );
      XPUSHs( sv_CHRM );
      XPUSHs( sv_MCIM );
      XPUSHs( sv_NCIM );
      XPUSHs( sv_IPXM );
      XPUSHs( sv_CHRE );
      XPUSHs( sv_MCIE );
      XPUSHs( sv_NCIE );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      strncpy( CHRM, SvPV_nolen( sv_CHRM ), (size_t)CHRM_len ); 
      *NCIM = (int)  SvIV(sv_NCIM);
      *IPXM = (int)  SvIV(sv_IPXM);
      strncpy( CHRE, SvPV_nolen( sv_CHRE ), (size_t)CHRE_len ); 
      *NCIE = (int)  SvIV(sv_NCIE);

      FREETMPS;
      LEAVE;
    }
                      
}

void agutol_( 
  int* IAXS,       /* INTEGER IAXS       */
  float* FUNS,     /* REAL FUNS          */
  int* IDMA,       /* INTEGER IDMA       */
  float* VINP,     /* REAL VINP          */
  float* VOTP      /* REAL VOTP          */
) {
    const char* name = "NCAR::agutol";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncaragutol_( 
            IAXS, FUNS, IDMA, VINP, VOTP
      );

    } else {
    
      dSP ;
      
      SV* sv_IAXS;
      SV* sv_FUNS;
      SV* sv_IDMA;
      SV* sv_VINP;
      SV* sv_VOTP;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IAXS = sv_2mortal( newSViv( ( IV )( *IAXS ) ) );
      sv_FUNS = sv_2mortal( newSVnv( ( NV )( *FUNS ) ) );
      sv_IDMA = sv_2mortal( newSViv( ( IV )( *IDMA ) ) );
      sv_VINP = sv_2mortal( newSVnv( ( NV )( *VINP ) ) );
      sv_VOTP = sv_2mortal( newSVnv( ( NV )( *VOTP ) ) );
      
      XPUSHs( sv_IAXS );
      XPUSHs( sv_FUNS );
      XPUSHs( sv_IDMA );
      XPUSHs( sv_VINP );
      XPUSHs( sv_VOTP );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      *VOTP = (float)SvNV(sv_VOTP);

      FREETMPS;
      LEAVE;
    }
                      
}

void agchax_( 
  int* IFLG,       /* INTEGER IFLG       */
  int* IAXS,       /* INTEGER IAXS       */
  int* IPRT,       /* INTEGER IPRT       */
  float* VILS      /* REAL VILS          */
) {
    const char* name = "NCAR::agchax";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncaragchax_( 
            IFLG, IAXS, IPRT, VILS
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
      SV* sv_IAXS;
      SV* sv_IPRT;
      SV* sv_VILS;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      sv_IAXS = sv_2mortal( newSViv( ( IV )( *IAXS ) ) );
      sv_IPRT = sv_2mortal( newSViv( ( IV )( *IPRT ) ) );
      sv_VILS = sv_2mortal( newSVnv( ( NV )( *VILS ) ) );
      
      XPUSHs( sv_IFLG );
      XPUSHs( sv_IAXS );
      XPUSHs( sv_IPRT );
      XPUSHs( sv_VILS );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void agchcu_( 
  int* IFLG,       /* INTEGER IFLG       */
  int* KDSH        /* INTEGER KDSH       */
) {
    const char* name = "NCAR::agchcu";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncaragchcu_( 
            IFLG, KDSH
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
      SV* sv_KDSH;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      sv_KDSH = sv_2mortal( newSViv( ( IV )( *KDSH ) ) );
      
      XPUSHs( sv_IFLG );
      XPUSHs( sv_KDSH );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void agchil_( 
  int* IFLG,       /* INTEGER IFLG       */
  char* LBNM,      /* CHARACTER*(*) LBNM */
  int* LNNO,       /* INTEGER LNNO       */
  long LBNM_len
) {

    const char* name = "NCAR::agchil";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncaragchil_( 
         IFLG, LBNM, LNNO, 
         LBNM_len   
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
      SV* sv_LBNM;
      SV* sv_LNNO;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      sv_LBNM = sv_2mortal( newSVpv( LBNM, (STRLEN)LBNM_len ) );
      sv_LNNO = sv_2mortal( newSViv( ( IV )( *LNNO ) ) );
      
      XPUSHs( sv_IFLG );
      XPUSHs( sv_LBNM );
      XPUSHs( sv_LNNO );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void cpchcf_( 
  int* IFLG        /* INTEGER IFLG       */
) {
    const char* name = "NCAR::cpchcf";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarcpchcf_( 
            IFLG
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      
      XPUSHs( sv_IFLG );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void cpchcl_( 
  int* IFLG        /* INTEGER IFLG       */
) {
    const char* name = "NCAR::cpchcl";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarcpchcl_( 
            IFLG
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      
      XPUSHs( sv_IFLG );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}


void cpchhl_( 
  int* IFLG        /* INTEGER IFLG       */
) {
    const char* name = "NCAR::cpchhl";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarcpchhl_( 
            IFLG
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      
      XPUSHs( sv_IFLG );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void cpchll_( 
  int* IFLG        /* INTEGER IFLG       */
) {
    const char* name = "NCAR::cpchll";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarcpchll_( 
            IFLG
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      
      XPUSHs( sv_IFLG );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void cpchil_( 
  int* IFLG        /* INTEGER IFLG       */
) {
    const char* name = "NCAR::cpchil";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarcpchil_( 
            IFLG
      );

    } else {
      dSP;
      
      SV* sv_IFLG;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      
      XPUSHs( sv_IFLG );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void mapeod_(
  int* NOUT,   /* INTEGER NOUT     */
  int* NSEG,   /* INTEGER NSEG     */
  int* IDLS,   /* INTEGER IDLS     */
  int* IDRS,   /* INTEGER IDRS     */
  int* NPTS,   /* INTEGER NPTS     */
  float* PNTS  /* REAL PNTS(*)     */
) {
    const char* name = "NCAR::mapeod";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarmapeod_( 
            NOUT, NSEG, IDLS, IDRS, NPTS, PNTS
      );

    } else {
      dSP;
      
      PDL_Long PNTS_dims[1];
      SV* sv_NOUT;
      SV* sv_NSEG;
      SV* sv_IDLS;
      SV* sv_IDRS;
      SV* sv_NPTS;
      SV* sv_pdl_PNTS;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      PNTS_dims[0] = 2 * (*NPTS);
      sv_NOUT = sv_2mortal( newSViv( ( IV )( *NOUT ) ) );
      sv_NSEG = sv_2mortal( newSViv( ( IV )( *NSEG ) ) );
      sv_IDLS = sv_2mortal( newSViv( ( IV )( *IDLS ) ) );
      sv_IDRS = sv_2mortal( newSViv( ( IV )( *IDRS ) ) );
      sv_NPTS = sv_2mortal( newSViv( ( IV )( *NPTS ) ) );
      sv_pdl_PNTS = pointer2piddle( ( void* )PNTS, 1, PNTS_dims, PDL_F );
      
      XPUSHs( sv_NOUT );
      XPUSHs( sv_NSEG );
      XPUSHs( sv_IDLS );
      XPUSHs( sv_IDRS );
      XPUSHs( sv_NPTS );
      XPUSHs( sv_pdl_PNTS );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      *NPTS = (int)SvNV(sv_NPTS);

      FREETMPS;
      LEAVE;
    }

}

void mapusr_( 
  int* IPRT        /* INTEGER IPRT       */
) {
    const char* name = "NCAR::mapusr";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarmapeod_( 
            IPRT
      );

    } else {
      dSP;
      
      SV* sv_IPRT;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IPRT = sv_2mortal( newSViv( ( IV )( *IPRT ) ) );
      
      XPUSHs( sv_IPRT );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}

void mpchln_(
  int* IFLG,   /* INTEGER NOUT     */
  int* ILTY,   /* INTEGER ILTY     */
  int* IOAL,   /* INTEGER IOAL     */
  int* IOAR,   /* INTEGER IOAR     */
  int* NPTS,   /* INTEGER NPTS     */
  float* PNTS  /* REAL PNTS(*)     */
) {
    const char* name = "NCAR::mpchln";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarmpchln_( 
            IFLG, ILTY, IOAL, IOAR, NPTS, PNTS
      );

    } else {
      dSP;
      
      PDL_Long PNTS_dims[1];
      SV* sv_IFLG;
      SV* sv_ILTY;
      SV* sv_IOAL;
      SV* sv_IOAR;
      SV* sv_NPTS;
      SV* sv_pdl_PNTS;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      PNTS_dims[0] = 2 * (*NPTS);
      sv_IFLG = sv_2mortal( newSViv( ( IV )( *IFLG ) ) );
      sv_ILTY = sv_2mortal( newSViv( ( IV )( *ILTY ) ) );
      sv_IOAL = sv_2mortal( newSViv( ( IV )( *IOAL ) ) );
      sv_IOAR = sv_2mortal( newSViv( ( IV )( *IOAR ) ) );
      sv_NPTS = sv_2mortal( newSViv( ( IV )( *NPTS ) ) );
      sv_pdl_PNTS = pointer2piddle( ( void* )PNTS, 1, PNTS_dims, PDL_F );
      
      XPUSHs( sv_IFLG );
      XPUSHs( sv_ILTY );
      XPUSHs( sv_IOAL );
      XPUSHs( sv_IOAR );
      XPUSHs( sv_NPTS );
      XPUSHs( sv_pdl_PNTS );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      *IOAL = (int)SvNV(sv_IOAL);
      *IOAR = (int)SvNV(sv_IOAR);
      *NPTS = (int)SvNV(sv_NPTS);

      FREETMPS;
      LEAVE;
    }

}

void slubkg_( 
  int* IPOC        /* INTEGER IPOC       */
) {
    const char* name = "NCAR::mpchln";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarslubkg_( 
            IPOC
      );

    } else {
      dSP;
      
      SV* sv_IPOC;
      
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IPOC = sv_2mortal( newSViv( ( IV )( *IPOC ) ) );
      
      XPUSHs( sv_IPOC );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );

      FREETMPS;
      LEAVE;
    }
                      
}


void cpmpxy_( 
  int* IMAP,       /* INTEGER IMAP       */
  float* XINP,     /* REAL XINP          */
  float* YINP,     /* REAL YINP          */
  float* XOTP,     /* REAL XOTP          */
  float* YOTP      /* REAL YOTP          */
) {
    const char* name = "NCAR::cpmpxy";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarcpmpxy_( 
            IMAP, XINP, YINP, XOTP, YOTP
      );

    } else {
      dSP;
      
      SV* sv_IMAP;
      SV* sv_XINP;
      SV* sv_YINP;
      SV* sv_XOTP;
      SV* sv_YOTP;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IMAP = sv_2mortal( newSViv( ( IV )( *IMAP ) ) );
      sv_XINP = sv_2mortal( newSVnv( ( NV )( *XINP ) ) );
      sv_YINP = sv_2mortal( newSVnv( ( NV )( *YINP ) ) );
      sv_XOTP = sv_2mortal( newSVnv( ( NV )( *XOTP ) ) );
      sv_YOTP = sv_2mortal( newSVnv( ( NV )( *YOTP ) ) );
      
      XPUSHs( sv_IMAP );
      XPUSHs( sv_XINP );
      XPUSHs( sv_YINP );
      XPUSHs( sv_XOTP );
      XPUSHs( sv_YOTP );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      *XINP = (float)SvNV(sv_XINP);
      *YINP = (float)SvNV(sv_YINP);
      *XOTP = (float)SvNV(sv_XOTP);
      *YOTP = (float)SvNV(sv_YOTP);

      FREETMPS;
      LEAVE;
    }
                      
}

void pcmpxy_( 
  int* IMAP,       /* INTEGER IMAP       */
  float* XINP,     /* REAL XINP          */
  float* YINP,     /* REAL YINP          */
  float* XOTP,     /* REAL XOTP          */
  float* YOTP      /* REAL YOTP          */
) {
    const char* name = "NCAR::pcmpxy";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarpcmpxy_( 
            IMAP, XINP, YINP, XOTP, YOTP
      );

    } else {
      dSP;
      
      SV* sv_IMAP;
      SV* sv_XINP;
      SV* sv_YINP;
      SV* sv_XOTP;
      SV* sv_YOTP;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_IMAP = sv_2mortal( newSViv( ( IV )( *IMAP ) ) );
      sv_XINP = sv_2mortal( newSVnv( ( NV )( *XINP ) ) );
      sv_YINP = sv_2mortal( newSVnv( ( NV )( *YINP ) ) );
      sv_XOTP = sv_2mortal( newSVnv( ( NV )( *XOTP ) ) );
      sv_YOTP = sv_2mortal( newSVnv( ( NV )( *YOTP ) ) );
      
      XPUSHs( sv_IMAP );
      XPUSHs( sv_XINP );
      XPUSHs( sv_YINP );
      XPUSHs( sv_XOTP );
      XPUSHs( sv_YOTP );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      if( *IMAP == 0 ) { /* Damn it !! */
        *YINP = (float)SvNV(sv_YINP);
      }
      *XOTP = (float)SvNV(sv_XOTP);
      *YOTP = (float)SvNV(sv_YOTP);

      FREETMPS;
      LEAVE;
    }
                      
}


void vvumxy_( 
  float* X,        /* REAL X             */
  float* Y,        /* REAL Y             */
  float* U,        /* REAL U             */
  float* V,        /* REAL V             */
  float* UVM,      /* REAL UVM           */
  float* XB,       /* REAL XB            */
  float* YB,       /* REAL YB            */
  float* XE,       /* REAL XE            */
  float* YE,       /* REAL YE            */
  int* IST         /* INTEGER IST        */
) {
    const char* name = "NCAR::vvumxy";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarvvumxy_( 
            X, Y, U, V, UVM, XB, YB, XE, YE, IST
      );

    } else {
      dSP;
      
      SV* sv_X;
      SV* sv_Y;
      SV* sv_U;
      SV* sv_V;
      SV* sv_UVM;
      SV* sv_XB;
      SV* sv_YB;
      SV* sv_XE;
      SV* sv_YE;
      SV* sv_IST;
    
      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_X    = sv_2mortal( newSVnv( ( NV )( *X    ) ) );
      sv_Y    = sv_2mortal( newSVnv( ( NV )( *Y    ) ) );
      sv_U    = sv_2mortal( newSVnv( ( NV )( *U    ) ) );
      sv_V    = sv_2mortal( newSVnv( ( NV )( *V    ) ) );
      sv_UVM  = sv_2mortal( newSVnv( ( NV )( *UVM  ) ) );
      sv_XB   = sv_2mortal( newSVnv( ( NV )( *XB   ) ) );
      sv_YB   = sv_2mortal( newSVnv( ( NV )( *YB   ) ) );
      sv_XE   = sv_2mortal( newSVnv( ( NV )( *XE   ) ) );
      sv_YE   = sv_2mortal( newSVnv( ( NV )( *YE   ) ) );
      sv_IST  = sv_2mortal( newSViv( ( IV )( *IST  ) ) );
      
      XPUSHs( sv_X    );
      XPUSHs( sv_Y    );
      XPUSHs( sv_U    );
      XPUSHs( sv_V    );
      XPUSHs( sv_UVM  );
      XPUSHs( sv_XB   );
      XPUSHs( sv_YB   );
      XPUSHs( sv_XE   );
      XPUSHs( sv_YE   );
      XPUSHs( sv_IST  );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      *XB   = (float)SvNV(sv_XB);
      *YB   = (float)SvNV(sv_YB);
      *XE   = (float)SvNV(sv_XE);
      *YE   = (float)SvNV(sv_YE);
      *IST  = (int)SvIV(sv_IST);

      FREETMPS;
      LEAVE;
    }
                      
}


void agpwrt_( 
  float* XPOS,     /* REAL XPOS          */
  float* YPOS,     /* REAL YPOS          */
  char* CHRS,      /* CHARACTER*(*) CHRS */
  int* NCHS,       /* length of CHRS     */
  int* ISIZ,       /* INTEGER ISIZ       */
  int* IORI,       /* INTEGER IORI       */
  int* ICEN,       /* INTEGER ICEN       */
  long CHRS_len
) {
    const char* name = "NCAR::agpwrt";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncaragpwrt_( 
            XPOS, YPOS, CHRS, NCHS, ISIZ, IORI, ICEN, CHRS_len
      );

    } else {
    
      dSP;

      SV* sv_XPOS;
      SV* sv_YPOS;
      SV* sv_CHRS;
      SV* sv_NCHS;
      SV* sv_ISIZ;
      SV* sv_IORI;
      SV* sv_ICEN;

      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      sv_XPOS = sv_2mortal( newSVnv( ( NV )( *XPOS ) ) );
      sv_YPOS = sv_2mortal( newSVnv( ( NV )( *YPOS ) ) );
      sv_CHRS = sv_2mortal( newSVpv( CHRS, (STRLEN)CHRS_len ) );
      sv_NCHS = sv_2mortal( newSViv( ( IV )( *NCHS ) ) );
      sv_ISIZ = sv_2mortal( newSViv( ( IV )( *ISIZ ) ) );
      sv_IORI = sv_2mortal( newSViv( ( IV )( *IORI ) ) );
      sv_ICEN = sv_2mortal( newSViv( ( IV )( *ICEN ) ) );
      
      XPUSHs( sv_XPOS );
      XPUSHs( sv_YPOS );
      XPUSHs( sv_CHRS );
      XPUSHs( sv_NCHS );
      XPUSHs( sv_ISIZ );
      XPUSHs( sv_IORI );
      XPUSHs( sv_ICEN );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      FREETMPS;
      LEAVE;
    }
                      
}

void fdum_(
) {
    const char* name = "NCAR::fdum";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
    
      ncarfdum_( 
      );

    } else {
  
      dSP;
    
      ENTER;
      SAVETMPS; 
       
      PUSHMARK(SP);
    
      PUTBACK;
    
      call_pv( name, G_DISCARD );
    
      FREETMPS;
      LEAVE;
    }

}

void lbfill_( 
  int* IFTP,       /* INTEGER IFTP       */
  float* XCRA,     /* REAL XCRA(*)       */
  float* YCRA,     /* REAL YCRA(*)       */
  int* NCRA,       /* INTEGER NCRA       */
  int* INDX        /* INTEGER INDX       */
) {
    const char* name = "NCAR::lbfill";
    
    if( get_cv( name, (I32)0 ) == NULL ) {
      
      ncarlbfill_( 
            IFTP, XCRA, YCRA, NCRA, INDX
      );

    } else {
    
      dSP;

      PDL_Long XCRA_dims[1];
      PDL_Long YCRA_dims[1];
      SV* sv_IFTP;
      SV* sv_pdl_XCRA;
      SV* sv_pdl_YCRA;
      SV* sv_NCRA;
      SV* sv_INDX;

      ENTER;
      SAVETMPS;  
      PUSHMARK(SP);

      XCRA_dims[0] = *NCRA;
      YCRA_dims[0] = *NCRA;
      sv_IFTP = sv_2mortal( newSViv( ( IV )( *IFTP ) ) );
      sv_pdl_XCRA = pointer2piddle( ( void* )XCRA, 1, XCRA_dims, PDL_F );
      sv_pdl_YCRA = pointer2piddle( ( void* )YCRA, 1, YCRA_dims, PDL_F );
      sv_NCRA = sv_2mortal( newSViv( ( IV )( *NCRA ) ) );
      sv_INDX = sv_2mortal( newSViv( ( IV )( *INDX ) ) );
      
      XPUSHs( sv_IFTP );
      XPUSHs( sv_pdl_XCRA );
      XPUSHs( sv_pdl_YCRA );
      XPUSHs( sv_NCRA );
      XPUSHs( sv_INDX );
  
      PUTBACK;
      
      call_pv( name, G_DISCARD );
      
      FREETMPS;
      LEAVE;
    }
                      
}

