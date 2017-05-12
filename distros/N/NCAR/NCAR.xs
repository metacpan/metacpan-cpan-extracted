#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>

#include "arrays.h"
#include "arrays.c"


/* typedefs for automatic arrays conversion */

typedef int   int1D;
typedef float float1D;
typedef char  string1D;

typedef int   int2D;
typedef float float2D;


#include "pdl_auto_include.h"
#include "ncar_pdl_check.c"
#include "ncar_callbacks.c"

#include "ncar_packages.h"
#include "ncar_functions.h"
#include "ncar_commons.h"
#include "ncar_user_defined.c"



MODULE = NCAR           PACKAGE = NCAR          

char*
semess( ITRIM )
      PREINIT:
        char _RETVAL[114];
      INPUT:
        int ITRIM;
      CODE:
        semess_( _RETVAL, (long)113, &ITRIM );
        _RETVAL[113] = '\0';
        RETVAL = (char*)_RETVAL;
      OUTPUT:
        RETVAL


char*
NCAR_FUNCTION_0000( IAIN, ILVL )
      ALIAS:
        mdfnme     = FUNCTION_NAME_MDFNME
        mpfnme     = FUNCTION_NAME_MPFNME
      PREINIT:
        typedef void (*ncar_function)( char*, long, int*, int* );
        char _RETVAL[129];
      INPUT:
        int IAIN;
        int ILVL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( _RETVAL, (long)128, &IAIN, &ILVL );
        _RETVAL[128] = '\0';
        RETVAL = (char*)_RETVAL;
      OUTPUT:
        RETVAL


char*
NCAR_FUNCTION_0001( IDSH )
      ALIAS:
        agbnch     = FUNCTION_NAME_AGBNCH
        agdshn     = FUNCTION_NAME_AGDSHN
      PREINIT:
        typedef void (*ncar_function)( char*, long, int* );
        char _RETVAL[17];
      INPUT:
        int IDSH;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( _RETVAL, (long)16, &IDSH );
        _RETVAL[16] = '\0';
        RETVAL = (char*)_RETVAL;
      OUTPUT:
        RETVAL


char*
pcpnwi( WHCH, IPAI )
      PREINIT:
        char _RETVAL[17];
      INPUT:
        char* WHCH;
        int IPAI;
      CODE:
        pcpnwi_( _RETVAL, (long)16, WHCH, &IPAI, (long)strlen( WHCH ) );
        _RETVAL[16] = '\0';
        RETVAL = (char*)_RETVAL;
      OUTPUT:
        RETVAL


char*
mpname( IAIN )
      PREINIT:
        char _RETVAL[65];
      INPUT:
        int IAIN;
      CODE:
        mpname_( _RETVAL, (long)64, &IAIN );
        _RETVAL[64] = '\0';
        RETVAL = (char*)_RETVAL;
      OUTPUT:
        RETVAL


char*
mdname( IAIN )
      PREINIT:
        char _RETVAL[69];
      INPUT:
        int IAIN;
      CODE:
        mdname_( _RETVAL, (long)68, &IAIN );
        _RETVAL[68] = '\0';
        RETVAL = (char*)_RETVAL;
      OUTPUT:
        RETVAL


double
mdscal( XCOP, YCOP, XCOQ, YCOQ )
      PREINIT:
      INPUT:
        float XCOP;
        float YCOP;
        float XCOQ;
        float YCOQ;
      CODE:
        RETVAL = mdscal_( &XCOP, &YCOP, &XCOQ, &YCOQ );
      OUTPUT:
        RETVAL


float
NCAR_FUNCTION_0002( RX )
      ALIAS:
        cfux       =   FUNCTION_NAME_CFUX
        cfuy       =   FUNCTION_NAME_CFUY
        cufx       =   FUNCTION_NAME_CUFX
        cufy       =   FUNCTION_NAME_CUFY
      PREINIT:
        typedef float (*ncar_function)( float* );
      INPUT:
        float RX;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &RX );
      OUTPUT:
        RETVAL


float
curvi( XL, XR, N, X, Y, YP, SIGMA )
      PREINIT:
      INPUT:
        float XL;
        float XR;
        int N;
        pdl* X;
        pdl* Y;
        pdl* YP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        RETVAL = curvi_( &XL, &XR, &N, ( float* )X->data, ( float* )Y->data, ( float* )YP->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( YP );
      OUTPUT:
        RETVAL


float
curvpi( XL, XR, N, X, Y, P, YP, SIGMA )
      PREINIT:
      INPUT:
        float XL;
        float XR;
        int N;
        pdl* X;
        pdl* Y;
        float P;
        pdl* YP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        RETVAL = curvpi_( &XL, &XR, &N, ( float* )X->data, ( float* )Y->data, &P, ( float* )YP->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( YP );
      OUTPUT:
        RETVAL


float
mssrf2( XX, YY, M, N, X, Y, Z, IZ, ZP, SIGMA )
      PREINIT:
      INPUT:
        float XX;
        float YY;
        int M;
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int IZ;
        pdl* ZP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 4, PDL_F, 1, M );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 6, PDL_F, 2, IZ, N );
        ncar_pdl_check_in( ZP, GvNAME(CvGV(cv)), 8, PDL_F, 3, M, N, 3 );
        RETVAL = mssrf2_( &XX, &YY, &M, &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &IZ, ( float* )ZP->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( ZP );
      OUTPUT:
        RETVAL


float
surf2( XX, YY, M, N, X, Y, Z, IZ, ZP, SIGMA )
      PREINIT:
      INPUT:
        float XX;
        float YY;
        int M;
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int IZ;
        pdl* ZP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 4, PDL_F, 1, M );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 6, PDL_F, 2, IZ, N );
        ncar_pdl_check_in( ZP, GvNAME(CvGV(cv)), 8, PDL_F, 3, M, N, 3 );
        RETVAL = surf2_( &XX, &YY, &M, &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &IZ, ( float* )ZP->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( ZP );
      OUTPUT:
        RETVAL


float
NCAR_FUNCTION_0003( T, N, X, Y, YP, SIGMA )
      ALIAS:
        curv2      =  FUNCTION_NAME_CURV2
        curvd      =  FUNCTION_NAME_CURVD
      PREINIT:
        typedef float (*ncar_function)( float*, int*, float*, float*, float*, float* );
      INPUT:
        float T;
        int N;
        pdl* X;
        pdl* Y;
        pdl* YP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &T, &N, ( float* )X->data, ( float* )Y->data, ( float* )YP->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( YP );
      OUTPUT:
        RETVAL


float
curvp2( T, N, X, Y, P, YP, SIGMA )
      PREINIT:
      INPUT:
        float T;
        int N;
        pdl* X;
        pdl* Y;
        float P;
        pdl* YP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        RETVAL = curvp2_( &T, &N, ( float* )X->data, ( float* )Y->data, &P, ( float* )YP->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( YP );
      OUTPUT:
        RETVAL


float
NCAR_FUNCTION_0004( IX )
      ALIAS:
        cmfx       =   FUNCTION_NAME_CMFX
        cmfy       =   FUNCTION_NAME_CMFY
        cmux       =   FUNCTION_NAME_CMUX
        cmuy       =   FUNCTION_NAME_CMUY
        cpfx       =   FUNCTION_NAME_CPFX
        cpfy       =   FUNCTION_NAME_CPFY
        cpux       =   FUNCTION_NAME_CPUX
        cpuy       =   FUNCTION_NAME_CPUY
      PREINIT:
        typedef float (*ncar_function)( int* );
      INPUT:
        int IX;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &IX );
      OUTPUT:
        RETVAL


int
NCAR_FUNCTION_0005( RX )
      ALIAS:
        kfmx       =   FUNCTION_NAME_KFMX
        kfmy       =   FUNCTION_NAME_KFMY
        kfpx       =   FUNCTION_NAME_KFPX
        kfpy       =   FUNCTION_NAME_KFPY
        kupx       =   FUNCTION_NAME_KUPX
        kupy       =   FUNCTION_NAME_KUPY
        kumx       =   FUNCTION_NAME_KUMX
        kumy       =   FUNCTION_NAME_KUMY
      PREINIT:
        typedef int (*ncar_function)( float* );
      INPUT:
        float RX;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &RX );
      OUTPUT:
        RETVAL


int
NCAR_FUNCTION_0006( IAI )
      ALIAS:
        mapaci     = FUNCTION_NAME_MAPACI
        mdiaty     = FUNCTION_NAME_MDIATY
        mdipar     = FUNCTION_NAME_MDIPAR
        mdisci     = FUNCTION_NAME_MDISCI
        mdpaci     = FUNCTION_NAME_MDPACI
        mpiaty     = FUNCTION_NAME_MPIATY
        mpipar     = FUNCTION_NAME_MPIPAR
        mpisci     = FUNCTION_NAME_MPISCI
        ngckop     = FUNCTION_NAME_NGCKOP
        kmpx       =   FUNCTION_NAME_KMPX
        kmpy       =   FUNCTION_NAME_KMPY
        kpmx       =   FUNCTION_NAME_KPMX
        kpmy       =   FUNCTION_NAME_KPMY
      PREINIT:
        typedef int (*ncar_function)( int* );
      INPUT:
        int IAI;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &IAI );
      OUTPUT:
        RETVAL


int
msntvl( N, T, X )
      PREINIT:
      INPUT:
        int N;
        float T;
        pdl* X;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        RETVAL = msntvl_( &N, &T, ( float* )X->data );
        ncar_pdl_check_out( X );
      OUTPUT:
        RETVAL


int
NCAR_FUNCTION_0007( IAID, ILVL )
      ALIAS:
        mdiola     = FUNCTION_NAME_MDIOLA
        mdiosa     = FUNCTION_NAME_MDIOSA
        mdipai     = FUNCTION_NAME_MDIPAI
        mpiola     = FUNCTION_NAME_MPIOLA
        mpiosa     = FUNCTION_NAME_MPIOSA
        mpipai     = FUNCTION_NAME_MPIPAI
      PREINIT:
        typedef int (*ncar_function)( int*, int* );
      INPUT:
        int IAID;
        int ILVL;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &IAID, &ILVL );
      OUTPUT:
        RETVAL


int
NCAR_FUNCTION_0008( IAIN, ANME )
      ALIAS:
        mdipan     = FUNCTION_NAME_MDIPAN
        mpipan     = FUNCTION_NAME_MPIPAN
      PREINIT:
        typedef int (*ncar_function)( int*, char*, long );
      INPUT:
        int IAIN;
        char* ANME;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( &IAIN, ANME, (long)strlen( ANME ) );
      OUTPUT:
        RETVAL


int
nerro( NERR )
      PREINIT:
      INPUT:
        int &NERR;
      CODE:
        RETVAL = nerro_( &NERR );
      OUTPUT:
        RETVAL
        NERR


int
NCAR_FUNCTION_0009( CHRS )
      ALIAS:
        mdifnb     = FUNCTION_NAME_MDIFNB
        mdilnb     = FUNCTION_NAME_MDILNB
        mpifnb     = FUNCTION_NAME_MPIFNB
        mpilnb     = FUNCTION_NAME_MPILNB
        icloem     = FUNCTION_NAME_ICLOEM
      PREINIT:
        typedef int (*ncar_function)( char*, long );
      INPUT:
        char* CHRS;
      CODE:
        RETVAL = (*((ncar_function)ncar_functions[ix]))( CHRS, (long)strlen( CHRS ) );
      OUTPUT:
        RETVAL


int
icfell( MESSG, NERRF )
      PREINIT:
      INPUT:
        char* MESSG;
        int NERRF;
      CODE:
        RETVAL = icfell_( MESSG, &NERRF, (long)strlen( MESSG ) );
      OUTPUT:
        RETVAL


int
wmgtln( LAB, LABLEN, ILR )
      PREINIT:
      INPUT:
        char* LAB;
        int LABLEN;
        int ILR;
      CODE:
        RETVAL = wmgtln_( LAB, &LABLEN, &ILR, (long)strlen( LAB ) );
      OUTPUT:
        RETVAL


int
ngpswk( PSTYPE, ORIENT, COLOR )
      PREINIT:
      INPUT:
        char* PSTYPE;
        char* ORIENT;
        char* COLOR;
      CODE:
        RETVAL = ngpswk_( PSTYPE, ORIENT, COLOR, (long)strlen( PSTYPE ), (long)strlen( ORIENT ), (long)strlen( COLOR ) );
      OUTPUT:
        RETVAL


void
NCAR_FUNCTION_0010(  )
      ALIAS:
        agback     = FUNCTION_NAME_AGBACK
        cprset     = FUNCTION_NAME_CPRSET
        lastd      =  FUNCTION_NAME_LASTD
        dplast     = FUNCTION_NAME_DPLAST
        mapdrw     = FUNCTION_NAME_MAPDRW
        mapgrd     = FUNCTION_NAME_MAPGRD
        mapint     = FUNCTION_NAME_MAPINT
        mapiq      =  FUNCTION_NAME_MAPIQ
        mapiqd     = FUNCTION_NAME_MAPIQD
        maplbl     = FUNCTION_NAME_MAPLBL
        maplmb     = FUNCTION_NAME_MAPLMB
        maplot     = FUNCTION_NAME_MAPLOT
        maprs      =  FUNCTION_NAME_MAPRS
        mdpdrw     = FUNCTION_NAME_MDPDRW
        mdpgrd     = FUNCTION_NAME_MDPGRD
        mdpint     = FUNCTION_NAME_MDPINT
        mdpiq      =  FUNCTION_NAME_MDPIQ
        mdpiqd     = FUNCTION_NAME_MDPIQD
        mdplbl     = FUNCTION_NAME_MDPLBL
        mdplmb     = FUNCTION_NAME_MDPLMB
        mdplot     = FUNCTION_NAME_MDPLOT
        mdprs      =  FUNCTION_NAME_MDPRS
        mdrset     = FUNCTION_NAME_MDRSET
        mprset     = FUNCTION_NAME_MPRSET
        gflas2     = FUNCTION_NAME_GFLAS2
        ngezlogo   = FUNCTION_NAME_NGEZLOGO
        clsgks     = FUNCTION_NAME_CLSGKS
        wmdflt     = FUNCTION_NAME_WMDFLT
        frame      =  FUNCTION_NAME_FRAME
        opngks     = FUNCTION_NAME_OPNGKS
        sflush     = FUNCTION_NAME_SFLUSH
        strset     = FUNCTION_NAME_STRSET
        eprin      =  FUNCTION_NAME_EPRIN
        errof      =  FUNCTION_NAME_ERROF
        vvrset     = FUNCTION_NAME_VVRSET
        slrset     = FUNCTION_NAME_SLRSET
        isoscr     = FUNCTION_NAME_ISOSCR
        gclks      =  FUNCTION_NAME_GCLKS
        gclsg      =  FUNCTION_NAME_GCLSG
        nnpntend   = FUNCTION_NAME_NNPNTEND
        nnpntendd  = FUNCTION_NAME_NNPNTENDD
      PREINIT:
        typedef void (*ncar_function)(  );
      INPUT:
      CODE:
        (*((ncar_function)ncar_functions[ix]))(  );


void
NCAR_FUNCTION_0011( XLAT, XLON )
      ALIAS:
        mdpfst     = FUNCTION_NAME_MDPFST
        mdpvec     = FUNCTION_NAME_MDPVEC
      PREINIT:
        typedef void (*ncar_function)( double*, double* );
      INPUT:
        double XLAT;
        double XLON;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &XLAT, &XLON );


void
mdppos( ARG1, ARG2, ARG3, ARG4 )
      PREINIT:
      INPUT:
        double ARG1;
        double ARG2;
        double ARG3;
        double ARG4;
      CODE:
        mdppos_( &ARG1, &ARG2, &ARG3, &ARG4 );


void
mdpgci( ALAT, ALON, BLAT, BLON, NOPI, RLTI, RLNI )
      PREINIT:
      INPUT:
        double ALAT;
        double ALON;
        double BLAT;
        double BLON;
        int NOPI;
        double &RLTI;
        double &RLNI;
      CODE:
        mdpgci_( &ALAT, &ALON, &BLAT, &BLON, &NOPI, &RLTI, &RLNI );
      OUTPUT:
        RLTI
        RLNI


void
mdgcog( CLAT, CLON, CRAD, ALAT, ALON, NPTS )
      PREINIT:
      INPUT:
        double CLAT;
        double CLON;
        double CRAD;
        double &ALAT;
        double &ALON;
        int NPTS;
      CODE:
        mdgcog_( &CLAT, &CLON, &CRAD, &ALAT, &ALON, &NPTS );
      OUTPUT:
        ALAT
        ALON


void
nnpntd( X, Y, Z )
      PREINIT:
      INPUT:
        double X;
        double Y;
        double &Z;
      CODE:
        nnpntd_( &X, &Y, &Z );
      OUTPUT:
        Z


void
NCAR_FUNCTION_0012( RLAT, RLON, UVAL, VVAL )
      ALIAS:
        mdptra     = FUNCTION_NAME_MDPTRA
        mdptri     = FUNCTION_NAME_MDPTRI
        mdptrn     = FUNCTION_NAME_MDPTRN
        mdutfd     = FUNCTION_NAME_MDUTFD
        mdutid     = FUNCTION_NAME_MDUTID
        mputfd     = FUNCTION_NAME_MPUTFD
        mputid     = FUNCTION_NAME_MPUTID
      PREINIT:
        typedef void (*ncar_function)( double*, double*, double*, double* );
      INPUT:
        double RLAT;
        double RLON;
        double &UVAL;
        double &VVAL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &RLAT, &RLON, &UVAL, &VVAL );
      OUTPUT:
        UVAL
        VVAL


void
NCAR_FUNCTION_0013( XLAT, XLON, IFST )
      ALIAS:
        mdpit      =  FUNCTION_NAME_MDPIT
        mdpitd     = FUNCTION_NAME_MDPITD
      PREINIT:
        typedef void (*ncar_function)( double*, double*, int* );
      INPUT:
        double XLAT;
        double XLON;
        int IFST;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &XLAT, &XLON, &IFST );


void
mdpitm( XLAT, XLON, IFST, IAM, XCS, YCS, MCS, IAI, IAG, MAI, LPR_ )
      PREINIT:
      INPUT:
        double XLAT;
        double XLON;
        int IFST;
        pdl* IAM;
        pdl* XCS;
        pdl* YCS;
        int MCS;
        pdl* IAI;
        pdl* IAG;
        int MAI;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        ncar_pdl_check_in( XCS, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( YCS, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 7, PDL_L, 0 );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 8, PDL_L, 0 );
        perl_ncar_callback = LPR_;
        mdpitm_( &XLAT, &XLON, &IFST, ( int* )IAM->data, ( float* )XCS->data, ( float* )YCS->data, &MCS, ( int* )IAI->data, ( int* )IAG->data, &MAI, &c_ncar_callback_LPR );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( XCS );
        ncar_pdl_check_out( YCS );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );
        perl_ncar_callback = ( SV* )0;


void
mdpita( XLAT, XLON, IFST, IAMP, IGRP, IDLT, IDRT )
      PREINIT:
      INPUT:
        double XLAT;
        double XLON;
        int IFST;
        pdl* IAMP;
        int IGRP;
        int IDLT;
        int IDRT;
      CODE:
        ncar_pdl_check_in( IAMP, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        mdpita_( &XLAT, &XLON, &IFST, ( int* )IAMP->data, &IGRP, &IDLT, &IDRT );
        ncar_pdl_check_out( IAMP );


void
NCAR_FUNCTION_0014( RLAT, CHRS, CLEN, NCHR )
      ALIAS:
        mdlach     = FUNCTION_NAME_MDLACH
        mdloch     = FUNCTION_NAME_MDLOCH
      PREINIT:
        typedef void (*ncar_function)( double*, char*, int*, int*, long );
      INPUT:
        double RLAT;
        char* CHRS;
        int CLEN;
        int &NCHR;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &RLAT, CHRS, &CLEN, &NCHR, (long)strlen( CHRS ) );
      OUTPUT:
        NCHR


void
NCAR_FUNCTION_0015( CHH )
      ALIAS:
        gschh      =  FUNCTION_NAME_GSCHH
        gschsp     = FUNCTION_NAME_GSCHSP
        gschxp     = FUNCTION_NAME_GSCHXP
        gslwsc     = FUNCTION_NAME_GSLWSC
        gsmksc     = FUNCTION_NAME_GSMKSC
      PREINIT:
        typedef void (*ncar_function)( float* );
      INPUT:
        float CHH;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &CHH );


void
tdotri( RTRI, MTRI, NTRI, RTWK, ITWK, IORD )
      PREINIT:
      INPUT:
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        pdl* RTWK;
        pdl* ITWK;
        int IORD;
      CODE:
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 0, PDL_F, 2, 10, MTRI );
        ncar_pdl_check_in( RTWK, GvNAME(CvGV(cv)), 3, PDL_F, 2, MTRI, 2 );
        ncar_pdl_check_in( ITWK, GvNAME(CvGV(cv)), 4, PDL_L, 1, MTRI );
        tdotri_( ( float* )RTRI->data, &MTRI, &NTRI, ( float* )RTWK->data, ( int* )ITWK->data, &IORD );
        ncar_pdl_check_out( RTRI );
        ncar_pdl_check_out( RTWK );
        ncar_pdl_check_out( ITWK );
      OUTPUT:
        NTRI


void
tddtri( RTRI, MTRI, NTRI, ITWK )
      PREINIT:
      INPUT:
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        pdl* ITWK;
      CODE:
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 0, PDL_F, 2, 10, MTRI );
        ncar_pdl_check_in( ITWK, GvNAME(CvGV(cv)), 3, PDL_L, 1, NTRI );
        tddtri_( ( float* )RTRI->data, &MTRI, &NTRI, ( int* )ITWK->data );
        ncar_pdl_check_out( RTRI );
        ncar_pdl_check_out( ITWK );
      OUTPUT:
        NTRI


void
tdctri( RTRI, MTRI, NTRI, IAXS, RCUT )
      PREINIT:
      INPUT:
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        int IAXS;
        float RCUT;
      CODE:
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 0, PDL_F, 2, 10, MTRI );
        tdctri_( ( float* )RTRI->data, &MTRI, &NTRI, &IAXS, &RCUT );
        ncar_pdl_check_out( RTRI );
      OUTPUT:
        NTRI


void
gactm( MINP, X0, Y0, DX, DY, PHI, SX, SY, SW, MOUT )
      PREINIT:
      INPUT:
        pdl* MINP;
        float X0;
        float Y0;
        float DX;
        float DY;
        float PHI;
        float SX;
        float SY;
        int SW;
        pdl* MOUT;
      CODE:
        ncar_pdl_check_in( MINP, GvNAME(CvGV(cv)), 0, PDL_F, 2, 2, 3 );
        ncar_pdl_check_in( MOUT, GvNAME(CvGV(cv)), 9, PDL_F, 2, 2, 3 );
        gactm_( ( float* )MINP->data, &X0, &Y0, &DX, &DY, &PHI, &SX, &SY, &SW, ( float* )MOUT->data );
        ncar_pdl_check_out( MINP );
        ncar_pdl_check_out( MOUT );


void
init3d( EYE, NU, NV, NW, ST1, LX, NY, IS2, IU, S )
      PREINIT:
      INPUT:
        pdl* EYE;
        int NU;
        int NV;
        int NW;
        pdl* ST1;
        int LX;
        int NY;
        pdl* IS2;
        int IU;
        pdl* S;
      CODE:
        ncar_pdl_check_in( EYE, GvNAME(CvGV(cv)), 0, PDL_F, 1, 3 );
        ncar_pdl_check_in( ST1, GvNAME(CvGV(cv)), 4, PDL_F, 3, NV, NW, 2 );
        ncar_pdl_check_in( IS2, GvNAME(CvGV(cv)), 7, PDL_L, 2, LX, NY );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 9, PDL_F, 1, 4 );
        init3d_( ( float* )EYE->data, &NU, &NV, &NW, ( float* )ST1->data, &LX, &NY, ( int* )IS2->data, &IU, ( float* )S->data );
        ncar_pdl_check_out( EYE );
        ncar_pdl_check_out( ST1 );
        ncar_pdl_check_out( IS2 );
        ncar_pdl_check_out( S );


void
tditri( U, NU, V, NV, W, NW, F, LF1D, LF2D, FISO, RTRI, MTRI, NTRI, IRST )
      PREINIT:
      INPUT:
        pdl* U;
        int NU;
        pdl* V;
        int NV;
        pdl* W;
        int NW;
        pdl* F;
        int LF1D;
        int LF2D;
        float FISO;
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        int IRST;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 1, NU );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 2, PDL_F, 1, NV );
        ncar_pdl_check_in( W, GvNAME(CvGV(cv)), 4, PDL_F, 1, NW );
        ncar_pdl_check_in( F, GvNAME(CvGV(cv)), 6, PDL_F, 0 );
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 10, PDL_F, 2, 10, MTRI );
        tditri_( ( float* )U->data, &NU, ( float* )V->data, &NV, ( float* )W->data, &NW, ( float* )F->data, &LF1D, &LF2D, &FISO, ( float* )RTRI->data, &MTRI, &NTRI, &IRST );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( W );
        ncar_pdl_check_out( F );
        ncar_pdl_check_out( RTRI );
      OUTPUT:
        NTRI


void
tdstri( U, NU, V, NV, W, LW1D, RTRI, MTRI, NTRI, IRST )
      PREINIT:
      INPUT:
        pdl* U;
        int NU;
        pdl* V;
        int NV;
        pdl* W;
        int LW1D;
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        int IRST;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 1, NU );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 2, PDL_F, 1, NV );
        ncar_pdl_check_in( W, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 6, PDL_F, 2, 10, MTRI );
        tdstri_( ( float* )U->data, &NU, ( float* )V->data, &NV, ( float* )W->data, &LW1D, ( float* )RTRI->data, &MTRI, &NTRI, &IRST );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( W );
        ncar_pdl_check_out( RTRI );
      OUTPUT:
        NTRI


void
histgr( DAT1, NDIM, NPTS, IFLAG, CLASS, NCLASS, WRK, NWRK )
      PREINIT:
      INPUT:
        pdl* DAT1;
        int NDIM;
        int NPTS;
        int IFLAG;
        pdl* CLASS;
        int NCLASS;
        pdl* WRK;
        int NWRK;
      CODE:
        ncar_pdl_check_in( DAT1, GvNAME(CvGV(cv)), 0, PDL_F, 2, NDIM, 2 );
        ncar_pdl_check_in( CLASS, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( WRK, GvNAME(CvGV(cv)), 6, PDL_F, 1, NWRK );
        histgr_( ( float* )DAT1->data, &NDIM, &NPTS, &IFLAG, ( float* )CLASS->data, &NCLASS, ( float* )WRK->data, &NWRK );
        ncar_pdl_check_out( DAT1 );
        ncar_pdl_check_out( CLASS );
        ncar_pdl_check_out( WRK );


void
NCAR_FUNCTION_0016( ZDAT, MZDT, NZDT )
      ALIAS:
        cpezct     = FUNCTION_NAME_CPEZCT
        ezhftn     = FUNCTION_NAME_EZHFTN
        ezcntr     = FUNCTION_NAME_EZCNTR
      PREINIT:
        typedef void (*ncar_function)( float*, int*, int* );
      INPUT:
        pdl* ZDAT;
        int MZDT;
        int NZDT;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 2, MZDT, NZDT );
        (*((ncar_function)ncar_functions[ix]))( ( float* )ZDAT->data, &MZDT, &NZDT );
        ncar_pdl_check_out( ZDAT );


void
ezsrfc( Z, M, N, ANGH, ANGV, WORK )
      PREINIT:
      INPUT:
        pdl* Z;
        int M;
        int N;
        float ANGH;
        float ANGV;
        pdl* WORK;
      CODE:
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 0, PDL_F, 2, M, N );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ezsrfc_( ( float* )Z->data, &M, &N, &ANGH, &ANGV, ( float* )WORK->data );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( WORK );


void
hafton( Z, L, M, N, FLO, HI, NLEV, NOPT, NPRM, ISPV, SPVAL )
      PREINIT:
      INPUT:
        pdl* Z;
        int L;
        int M;
        int N;
        float FLO;
        float HI;
        int NLEV;
        int NOPT;
        int NPRM;
        int ISPV;
        float SPVAL;
      CODE:
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 0, PDL_F, 2, L, M );
        hafton_( ( float* )Z->data, &L, &M, &N, &FLO, &HI, &NLEV, &NOPT, &NPRM, &ISPV, &SPVAL );
        ncar_pdl_check_out( Z );


void
ezisos( T, MU, MV, MW, EYE, SLAB, TISO )
      PREINIT:
      INPUT:
        pdl* T;
        int MU;
        int MV;
        int MW;
        pdl* EYE;
        pdl* SLAB;
        float TISO;
      CODE:
        ncar_pdl_check_in( T, GvNAME(CvGV(cv)), 0, PDL_F, 3, MU, MV, MW );
        ncar_pdl_check_in( EYE, GvNAME(CvGV(cv)), 4, PDL_F, 1, 3 );
        ncar_pdl_check_in( SLAB, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ezisos_( ( float* )T->data, &MU, &MV, &MW, ( float* )EYE->data, ( float* )SLAB->data, &TISO );
        ncar_pdl_check_out( T );
        ncar_pdl_check_out( EYE );
        ncar_pdl_check_out( SLAB );


void
conrec( Z, L, M, N, FLO, HI, FINC, NSET, NHI, NDOT )
      PREINIT:
      INPUT:
        pdl* Z;
        int L;
        int M;
        int N;
        float FLO;
        float HI;
        float FINC;
        int NSET;
        int NHI;
        int NDOT;
      CODE:
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 0, PDL_F, 2, L, N );
        conrec_( ( float* )Z->data, &L, &M, &N, &FLO, &HI, &FINC, &NSET, &NHI, &NDOT );
        ncar_pdl_check_out( Z );


void
isosrf( T, LU, MU, LV, MV, MW, EYE, MUVWP2, SLAB, TISO, IFLAG )
      PREINIT:
      INPUT:
        pdl* T;
        int LU;
        int MU;
        int LV;
        int MV;
        int MW;
        pdl* EYE;
        int MUVWP2;
        pdl* SLAB;
        float TISO;
        int IFLAG;
      CODE:
        ncar_pdl_check_in( T, GvNAME(CvGV(cv)), 0, PDL_F, 3, LU, LV, MW );
        ncar_pdl_check_in( EYE, GvNAME(CvGV(cv)), 6, PDL_F, 1, 3 );
        ncar_pdl_check_in( SLAB, GvNAME(CvGV(cv)), 8, PDL_F, 2, MUVWP2, MUVWP2 );
        isosrf_( ( float* )T->data, &LU, &MU, &LV, &MV, &MW, ( float* )EYE->data, &MUVWP2, ( float* )SLAB->data, &TISO, &IFLAG );
        ncar_pdl_check_out( T );
        ncar_pdl_check_out( EYE );
        ncar_pdl_check_out( SLAB );


void
velvec( U, LU, V, LV, M, N, FLO, HI, NSET, ISPV, SPV )
      PREINIT:
      INPUT:
        pdl* U;
        int LU;
        pdl* V;
        int LV;
        int M;
        int N;
        float FLO;
        float HI;
        int NSET;
        int ISPV;
        pdl* SPV;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 2, LU, N );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 2, PDL_F, 1, 2 );
        ncar_pdl_check_in( SPV, GvNAME(CvGV(cv)), 10, PDL_F, 1, 2 );
        velvec_( ( float* )U->data, &LU, ( float* )V->data, &LV, &M, &N, &FLO, &HI, &NSET, &ISPV, ( float* )SPV->data );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( SPV );


void
velvct( U, LU, V, LV, M, N, FLO, HI, NSET, LENGTH, ISPV, SPV )
      PREINIT:
      INPUT:
        pdl* U;
        int LU;
        pdl* V;
        int LV;
        int M;
        int N;
        float FLO;
        float HI;
        int NSET;
        int LENGTH;
        int ISPV;
        pdl* SPV;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 2, LU, N );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 2, PDL_F, 2, LV, N );
        ncar_pdl_check_in( SPV, GvNAME(CvGV(cv)), 11, PDL_F, 1, 2 );
        velvct_( ( float* )U->data, &LU, ( float* )V->data, &LV, &M, &N, &FLO, &HI, &NSET, &LENGTH, &ISPV, ( float* )SPV->data );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( SPV );


void
NCAR_FUNCTION_0017( U, LU, V, LV, P, LP, M, N, WRK, LW )
      ALIAS:
        stinit     = FUNCTION_NAME_STINIT
        vvinit     = FUNCTION_NAME_VVINIT
      PREINIT:
        typedef void (*ncar_function)( float*, int*, float*, int*, float*, int*, int*, int*, float*, int* );
      INPUT:
        pdl* U;
        int LU;
        pdl* V;
        int LV;
        pdl* P;
        int LP;
        int M;
        int N;
        pdl* WRK;
        int LW;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 2, LU, N );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 2, PDL_F, 2, LV, N );
        ncar_pdl_check_in( P, GvNAME(CvGV(cv)), 4, PDL_F, 2, LP, N );
        ncar_pdl_check_in( WRK, GvNAME(CvGV(cv)), 8, PDL_F, 1, LW );
        (*((ncar_function)ncar_functions[ix]))( ( float* )U->data, &LU, ( float* )V->data, &LV, ( float* )P->data, &LP, &M, &N, ( float* )WRK->data, &LW );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( P );
        ncar_pdl_check_out( WRK );


void
NCAR_FUNCTION_0018( ZSPS, KSPS, MSPS, NSPS, RWRK, KRWK, IWRK, KIWK, ZDAT, KZDT )
      ALIAS:
        cpsprs     = FUNCTION_NAME_CPSPRS
        cpsps1     = FUNCTION_NAME_CPSPS1
      PREINIT:
        typedef void (*ncar_function)( float*, int*, int*, int*, float*, int*, int*, int*, float*, int* );
      INPUT:
        pdl* ZSPS;
        int KSPS;
        int MSPS;
        int NSPS;
        pdl* RWRK;
        int KRWK;
        pdl* IWRK;
        int KIWK;
        pdl* ZDAT;
        int KZDT;
      CODE:
        ncar_pdl_check_in( ZSPS, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 6, PDL_L, 0 );
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 8, PDL_F, 0 );
        (*((ncar_function)ncar_functions[ix]))( ( float* )ZSPS->data, &KSPS, &MSPS, &NSPS, ( float* )RWRK->data, &KRWK, ( int* )IWRK->data, &KIWK, ( float* )ZDAT->data, &KZDT );
        ncar_pdl_check_out( ZSPS );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );
        ncar_pdl_check_out( ZDAT );


void
cpcnrc( ZDAT, KZDT, MZDT, NZDT, FLOW, FHGH, FINC, KSET, NHGH, NDSH )
      PREINIT:
      INPUT:
        pdl* ZDAT;
        int KZDT;
        int MZDT;
        int NZDT;
        float FLOW;
        float FHGH;
        float FINC;
        int KSET;
        int NHGH;
        int NDSH;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        cpcnrc_( ( float* )ZDAT->data, &KZDT, &MZDT, &NZDT, &FLOW, &FHGH, &FINC, &KSET, &NHGH, &NDSH );
        ncar_pdl_check_out( ZDAT );


void
NCAR_FUNCTION_0019( X, Y, N )
      ALIAS:
        curved     = FUNCTION_NAME_CURVED
        dpcurv     = FUNCTION_NAME_DPCURV
        curve      =  FUNCTION_NAME_CURVE
      PREINIT:
        typedef void (*ncar_function)( float*, float*, int* );
      INPUT:
        pdl* X;
        pdl* Y;
        int N;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 0, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        (*((ncar_function)ncar_functions[ix]))( ( float* )X->data, ( float* )Y->data, &N );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );


void
NCAR_FUNCTION_0020( XRA, YRA, NRA, DST, NST, IND, NND )
      ALIAS:
        sfnorm     = FUNCTION_NAME_SFNORM
        sfwrld     = FUNCTION_NAME_SFWRLD
      PREINIT:
        typedef void (*ncar_function)( float*, float*, int*, float*, int*, int*, int* );
      INPUT:
        pdl* XRA;
        pdl* YRA;
        int NRA;
        pdl* DST;
        int NST;
        pdl* IND;
        int NND;
      CODE:
        ncar_pdl_check_in( XRA, GvNAME(CvGV(cv)), 0, PDL_F, 1, NRA );
        ncar_pdl_check_in( YRA, GvNAME(CvGV(cv)), 1, PDL_F, 1, NRA );
        ncar_pdl_check_in( DST, GvNAME(CvGV(cv)), 3, PDL_F, 1, NST );
        ncar_pdl_check_in( IND, GvNAME(CvGV(cv)), 5, PDL_L, 1, NND );
        (*((ncar_function)ncar_functions[ix]))( ( float* )XRA->data, ( float* )YRA->data, &NRA, ( float* )DST->data, &NST, ( int* )IND->data, &NND );
        ncar_pdl_check_out( XRA );
        ncar_pdl_check_out( YRA );
        ncar_pdl_check_out( DST );
        ncar_pdl_check_out( IND );


void
sfsgfa( XRA, YRA, NRA, DST, NST, IND, NND, ICI )
      PREINIT:
      INPUT:
        pdl* XRA;
        pdl* YRA;
        int NRA;
        pdl* DST;
        int NST;
        pdl* IND;
        int NND;
        int ICI;
      CODE:
        ncar_pdl_check_in( XRA, GvNAME(CvGV(cv)), 0, PDL_F, 1, NRA );
        ncar_pdl_check_in( YRA, GvNAME(CvGV(cv)), 1, PDL_F, 1, NRA );
        ncar_pdl_check_in( DST, GvNAME(CvGV(cv)), 3, PDL_F, 1, NST );
        ncar_pdl_check_in( IND, GvNAME(CvGV(cv)), 5, PDL_L, 1, NND );
        sfsgfa_( ( float* )XRA->data, ( float* )YRA->data, &NRA, ( float* )DST->data, &NST, ( int* )IND->data, &NND, &ICI );
        ncar_pdl_check_out( XRA );
        ncar_pdl_check_out( YRA );
        ncar_pdl_check_out( DST );
        ncar_pdl_check_out( IND );


void
ngdots( X, Y, NUM, SIZE, ICOLOR )
      PREINIT:
      INPUT:
        pdl* X;
        pdl* Y;
        int NUM;
        float SIZE;
        int ICOLOR;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 0, PDL_F, 1, NUM );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 1, PDL_F, 1, NUM );
        ngdots_( ( float* )X->data, ( float* )Y->data, &NUM, &SIZE, &ICOLOR );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );


void
points( PX, PY, NP, IC, IL )
      PREINIT:
      INPUT:
        pdl* PX;
        pdl* PY;
        int NP;
        int IC;
        int IL;
      CODE:
        ncar_pdl_check_in( PX, GvNAME(CvGV(cv)), 0, PDL_F, 1, NP );
        ncar_pdl_check_in( PY, GvNAME(CvGV(cv)), 1, PDL_F, 1, NP );
        points_( ( float* )PX->data, ( float* )PY->data, &NP, &IC, &IL );
        ncar_pdl_check_out( PX );
        ncar_pdl_check_out( PY );


void
ppppap( XCOP, YCOP, NCOP, NBTS )
      PREINIT:
      INPUT:
        pdl* XCOP;
        pdl* YCOP;
        int &NCOP;
        int NBTS;
      CODE:
        ncar_pdl_check_in( XCOP, GvNAME(CvGV(cv)), 0, PDL_F, 1, NCOP );
        ncar_pdl_check_in( YCOP, GvNAME(CvGV(cv)), 1, PDL_F, 1, NCOP );
        ppppap_( ( float* )XCOP->data, ( float* )YCOP->data, &NCOP, &NBTS );
        ncar_pdl_check_out( XCOP );
        ncar_pdl_check_out( YCOP );
      OUTPUT:
        NCOP


void
ezvec( U, V, M, N )
      PREINIT:
      INPUT:
        pdl* U;
        pdl* V;
        int M;
        int N;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 2, M, N );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 1, PDL_F, 2, M, N );
        ezvec_( ( float* )U->data, ( float* )V->data, &M, &N );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );


void
curve3( U, V, W, N )
      PREINIT:
      INPUT:
        pdl* U;
        pdl* V;
        pdl* W;
        int N;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 1, N );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( W, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        curve3_( ( float* )U->data, ( float* )V->data, ( float* )W->data, &N );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( W );


void
conran( XD, YD, ZD, NDP, WK, IWK, SCRARR )
      PREINIT:
      INPUT:
        pdl* XD;
        pdl* YD;
        pdl* ZD;
        int NDP;
        pdl* WK;
        pdl* IWK;
        pdl* SCRARR;
      CODE:
        ncar_pdl_check_in( XD, GvNAME(CvGV(cv)), 0, PDL_F, 1, NDP );
        ncar_pdl_check_in( YD, GvNAME(CvGV(cv)), 1, PDL_F, 1, NDP );
        ncar_pdl_check_in( ZD, GvNAME(CvGV(cv)), 2, PDL_F, 1, NDP );
        ncar_pdl_check_in( WK, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        ncar_pdl_check_in( SCRARR, GvNAME(CvGV(cv)), 6, PDL_F, 0 );
        conran_( ( float* )XD->data, ( float* )YD->data, ( float* )ZD->data, &NDP, ( float* )WK->data, ( int* )IWK->data, ( float* )SCRARR->data );
        ncar_pdl_check_out( XD );
        ncar_pdl_check_out( YD );
        ncar_pdl_check_out( ZD );
        ncar_pdl_check_out( WK );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( SCRARR );


void
fence3( U, V, W, N, IOR, BOT )
      PREINIT:
      INPUT:
        pdl* U;
        pdl* V;
        pdl* W;
        int N;
        int IOR;
        float BOT;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 1, N );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( W, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        fence3_( ( float* )U->data, ( float* )V->data, ( float* )W->data, &N, &IOR, &BOT );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( W );


void
tdttri( UCRA, VCRA, WCRA, NCRA, IMRK, RMRK, SMRK, RTRI, MTRI, NTRI, IRST, UMIN, VMIN, WMIN, UMAX, VMAX, WMAX )
      PREINIT:
      INPUT:
        pdl* UCRA;
        pdl* VCRA;
        pdl* WCRA;
        int NCRA;
        int IMRK;
        float RMRK;
        float SMRK;
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        int IRST;
        float UMIN;
        float VMIN;
        float WMIN;
        float UMAX;
        float VMAX;
        float WMAX;
      CODE:
        ncar_pdl_check_in( UCRA, GvNAME(CvGV(cv)), 0, PDL_F, 1, NCRA );
        ncar_pdl_check_in( VCRA, GvNAME(CvGV(cv)), 1, PDL_F, 1, NCRA );
        ncar_pdl_check_in( WCRA, GvNAME(CvGV(cv)), 2, PDL_F, 1, NCRA );
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 7, PDL_F, 0 );
        tdttri_( ( float* )UCRA->data, ( float* )VCRA->data, ( float* )WCRA->data, &NCRA, &IMRK, &RMRK, &SMRK, ( float* )RTRI->data, &MTRI, &NTRI, &IRST, &UMIN, &VMIN, &WMIN, &UMAX, &VMAX, &WMAX );
        ncar_pdl_check_out( UCRA );
        ncar_pdl_check_out( VCRA );
        ncar_pdl_check_out( WCRA );
        ncar_pdl_check_out( RTRI );
      OUTPUT:
        NTRI


void
ezstrm( U, V, WORK, IMAX, JMAX )
      PREINIT:
      INPUT:
        pdl* U;
        pdl* V;
        pdl* WORK;
        int IMAX;
        int JMAX;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 2, IMAX, JMAX );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 1, PDL_F, 2, IMAX, JMAX );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        ezstrm_( ( float* )U->data, ( float* )V->data, ( float* )WORK->data, &IMAX, &JMAX );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( WORK );


void
strmln( U, V, WORK, IMAX, IPTSX, JPTSY, NSET, IER )
      PREINIT:
      INPUT:
        pdl* U;
        pdl* V;
        pdl* WORK;
        int IMAX;
        int IPTSX;
        int JPTSY;
        int NSET;
        int &IER;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 2, IMAX, JPTSY );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 1, PDL_F, 2, IMAX, JPTSY );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        strmln_( ( float* )U->data, ( float* )V->data, ( float* )WORK->data, &IMAX, &IPTSX, &JPTSY, &NSET, &IER );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
srface( X, Y, Z, M, MX, NX, NY, S, STEREO )
      PREINIT:
      INPUT:
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* M;
        int MX;
        int NX;
        int NY;
        pdl* S;
        float STEREO;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 0, PDL_F, 1, NX );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 1, PDL_F, 1, NY );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 2, PDL_F, 2, MX, NY );
        ncar_pdl_check_in( M, GvNAME(CvGV(cv)), 3, PDL_L, 3, 2, NX, NY );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 7, PDL_F, 1, 6 );
        srface_( ( float* )X->data, ( float* )Y->data, ( float* )Z->data, ( int* )M->data, &MX, &NX, &NY, ( float* )S->data, &STEREO );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( M );
        ncar_pdl_check_out( S );


void
cpsps2( XSPS, YSPS, ZSPS, KSPS, MSPS, NSPS, RWRK, KRWK, IWRK, KIWK, ZDAT, KZDT )
      PREINIT:
      INPUT:
        pdl* XSPS;
        pdl* YSPS;
        pdl* ZSPS;
        int KSPS;
        int MSPS;
        int NSPS;
        pdl* RWRK;
        int KRWK;
        pdl* IWRK;
        int KIWK;
        pdl* ZDAT;
        int KZDT;
      CODE:
        ncar_pdl_check_in( XSPS, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( YSPS, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( ZSPS, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 6, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 8, PDL_L, 0 );
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 10, PDL_F, 0 );
        cpsps2_( ( float* )XSPS->data, ( float* )YSPS->data, ( float* )ZSPS->data, &KSPS, &MSPS, &NSPS, ( float* )RWRK->data, &KRWK, ( int* )IWRK->data, &KIWK, ( float* )ZDAT->data, &KZDT );
        ncar_pdl_check_out( XSPS );
        ncar_pdl_check_out( YSPS );
        ncar_pdl_check_out( ZSPS );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );
        ncar_pdl_check_out( ZDAT );


void
cpdrpl( XCS, YCS, NCS, IAI, IAG, NAI )
      PREINIT:
      INPUT:
        pdl* XCS;
        pdl* YCS;
        int NCS;
        pdl* IAI;
        pdl* IAG;
        int NAI;
      CODE:
        ncar_pdl_check_in( XCS, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( YCS, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 4, PDL_L, 0 );
        cpdrpl_( ( float* )XCS->data, ( float* )YCS->data, &NCS, ( int* )IAI->data, ( int* )IAG->data, &NAI );
        ncar_pdl_check_out( XCS );
        ncar_pdl_check_out( YCS );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );


void
ezmxy( XDRA, YDRA, IDXY, MANY, NPTS, LABG )
      PREINIT:
      INPUT:
        pdl* XDRA;
        pdl* YDRA;
        int IDXY;
        int MANY;
        int NPTS;
        char* LABG;
      CODE:
        ncar_pdl_check_in( XDRA, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( YDRA, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ezmxy_( ( float* )XDRA->data, ( float* )YDRA->data, &IDXY, &MANY, &NPTS, LABG, (long)strlen( LABG ) );
        ncar_pdl_check_out( XDRA );
        ncar_pdl_check_out( YDRA );


void
ezxy( XDRA, YDRA, NPTS, LABG )
      PREINIT:
      INPUT:
        pdl* XDRA;
        pdl* YDRA;
        int NPTS;
        char* LABG;
      CODE:
        ncar_pdl_check_in( XDRA, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( YDRA, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ezxy_( ( float* )XDRA->data, ( float* )YDRA->data, &NPTS, LABG, (long)strlen( LABG ) );
        ncar_pdl_check_out( XDRA );
        ncar_pdl_check_out( YDRA );


void
agcurv( XVEC, IIEX, YVEC, IIEY, NEXY, KDSH )
      PREINIT:
      INPUT:
        pdl* XVEC;
        int IIEX;
        pdl* YVEC;
        int IIEY;
        int NEXY;
        int KDSH;
      CODE:
        ncar_pdl_check_in( XVEC, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( YVEC, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        agcurv_( ( float* )XVEC->data, &IIEX, ( float* )YVEC->data, &IIEY, &NEXY, &KDSH );
        ncar_pdl_check_out( XVEC );
        ncar_pdl_check_out( YVEC );


void
agstup( XDRA, NVIX, IIVX, NEVX, IIEX, YDRA, NVIY, IIVY, NEVY, IIEY )
      PREINIT:
      INPUT:
        pdl* XDRA;
        int NVIX;
        int IIVX;
        int NEVX;
        int IIEX;
        pdl* YDRA;
        int NVIY;
        int IIVY;
        int NEVY;
        int IIEY;
      CODE:
        ncar_pdl_check_in( XDRA, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( YDRA, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        agstup_( ( float* )XDRA->data, &NVIX, &IIVX, &NEVX, &IIEX, ( float* )YDRA->data, &NVIY, &IIVY, &NEVY, &IIEY );
        ncar_pdl_check_out( XDRA );
        ncar_pdl_check_out( YDRA );


void
ezmy( YDRA, IDXY, MANY, NPTS, LABG )
      PREINIT:
      INPUT:
        pdl* YDRA;
        int IDXY;
        int MANY;
        int NPTS;
        char* LABG;
      CODE:
        ncar_pdl_check_in( YDRA, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ezmy_( ( float* )YDRA->data, &IDXY, &MANY, &NPTS, LABG, (long)strlen( LABG ) );
        ncar_pdl_check_out( YDRA );


void
ezy( YDRA, NPTS, LABG )
      PREINIT:
      INPUT:
        pdl* YDRA;
        int NPTS;
        char* LABG;
      CODE:
        ncar_pdl_check_in( YDRA, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ezy_( ( float* )YDRA->data, &NPTS, LABG, (long)strlen( LABG ) );
        ncar_pdl_check_out( YDRA );


void
NCAR_FUNCTION_0021( ZDAT, RWRK, IWRK )
      ALIAS:
        cpback     = FUNCTION_NAME_CPBACK
        cpcldr     = FUNCTION_NAME_CPCLDR
        cplbdr     = FUNCTION_NAME_CPLBDR
        cppkcl     = FUNCTION_NAME_CPPKCL
        cppklb     = FUNCTION_NAME_CPPKLB
      PREINIT:
        typedef void (*ncar_function)( float*, float*, int* );
      INPUT:
        pdl* ZDAT;
        pdl* RWRK;
        pdl* IWRK;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        (*((ncar_function)ncar_functions[ix]))( ( float* )ZDAT->data, ( float* )RWRK->data, ( int* )IWRK->data );
        ncar_pdl_check_out( ZDAT );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );


void
cpcltr( ZDAT, RWRK, IWRK, CLVL, IJMP, IRW1, IRW2, NRWK )
      PREINIT:
      INPUT:
        pdl* ZDAT;
        pdl* RWRK;
        pdl* IWRK;
        float CLVL;
        int &IJMP;
        int &IRW1;
        int &IRW2;
        int &NRWK;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        cpcltr_( ( float* )ZDAT->data, ( float* )RWRK->data, ( int* )IWRK->data, &CLVL, &IJMP, &IRW1, &IRW2, &NRWK );
        ncar_pdl_check_out( ZDAT );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );
      OUTPUT:
        IJMP
        IRW1
        IRW2
        NRWK


void
cpcica( ZDAT, RWRK, IWRK, ICRA, ICA1, ICAM, ICAN, XCPF, YCPF, XCQF, YCQF )
      PREINIT:
      INPUT:
        pdl* ZDAT;
        pdl* RWRK;
        pdl* IWRK;
        pdl* ICRA;
        int ICA1;
        int ICAM;
        int ICAN;
        float XCPF;
        float YCPF;
        float XCQF;
        float YCQF;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        ncar_pdl_check_in( ICRA, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        cpcica_( ( float* )ZDAT->data, ( float* )RWRK->data, ( int* )IWRK->data, ( int* )ICRA->data, &ICA1, &ICAM, &ICAN, &XCPF, &YCPF, &XCQF, &YCQF );
        ncar_pdl_check_out( ZDAT );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );
        ncar_pdl_check_out( ICRA );


void
NCAR_FUNCTION_0022( ZDAT, RWRK, IWRK, IAMA )
      ALIAS:
        cpclam     = FUNCTION_NAME_CPCLAM
        cplbam     = FUNCTION_NAME_CPLBAM
      PREINIT:
        typedef void (*ncar_function)( float*, float*, int*, int* );
      INPUT:
        pdl* ZDAT;
        pdl* RWRK;
        pdl* IWRK;
        pdl* IAMA;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        ncar_pdl_check_in( IAMA, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        (*((ncar_function)ncar_functions[ix]))( ( float* )ZDAT->data, ( float* )RWRK->data, ( int* )IWRK->data, ( int* )IAMA->data );
        ncar_pdl_check_out( ZDAT );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );
        ncar_pdl_check_out( IAMA );


void
cpcldm( ZDAT, RWRK, IWRK, IAMA, LPR_ )
      PREINIT:
      INPUT:
        pdl* ZDAT;
        pdl* RWRK;
        pdl* IWRK;
        pdl* IAMA;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        ncar_pdl_check_in( IAMA, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        perl_ncar_callback = LPR_;
        cpcldm_( ( float* )ZDAT->data, ( float* )RWRK->data, ( int* )IWRK->data, ( int* )IAMA->data, &c_ncar_callback_LPR );
        ncar_pdl_check_out( ZDAT );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );
        ncar_pdl_check_out( IAMA );
        perl_ncar_callback = ( SV* )0;


void
NCAR_FUNCTION_0023( U, V, P, IAM, LPR_, WRK )
      ALIAS:
        stream     = FUNCTION_NAME_STREAM
        vvectr     = FUNCTION_NAME_VVECTR
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, int*, void*, float* );
      INPUT:
        pdl* U;
        pdl* V;
        pdl* P;
        pdl* IAM;
        SV* LPR_;
        pdl* WRK;
      CODE:
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( V, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( P, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        ncar_pdl_check_in( WRK, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        perl_ncar_callback = LPR_;
        (*((ncar_function)ncar_functions[ix]))( ( float* )U->data, ( float* )V->data, ( float* )P->data, ( int* )IAM->data, &c_ncar_callback_LPR, ( float* )WRK->data );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( V );
        ncar_pdl_check_out( P );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( WRK );
        perl_ncar_callback = ( SV* )0;


void
cprect( ZDAT, KZDT, MZDT, NZDT, RWRK, KRWK, IWRK, KIWK )
      PREINIT:
      INPUT:
        pdl* ZDAT;
        int KZDT;
        int MZDT;
        int NZDT;
        pdl* RWRK;
        int KRWK;
        pdl* IWRK;
        int KIWK;
      CODE:
        ncar_pdl_check_in( ZDAT, GvNAME(CvGV(cv)), 0, PDL_F, 0 );
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( IWRK, GvNAME(CvGV(cv)), 6, PDL_L, 0 );
        cprect_( ( float* )ZDAT->data, &KZDT, &MZDT, &NZDT, ( float* )RWRK->data, &KRWK, ( int* )IWRK->data, &KIWK );
        ncar_pdl_check_out( ZDAT );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IWRK );


void
NCAR_FUNCTION_0024( X, Y )
      ALIAS:
        frstd      =  FUNCTION_NAME_FRSTD
        vectd      =  FUNCTION_NAME_VECTD
        dpfrst     = FUNCTION_NAME_DPFRST
        dpvect     = FUNCTION_NAME_DPVECT
        mapfst     = FUNCTION_NAME_MAPFST
        mapvec     = FUNCTION_NAME_MAPVEC
        frstpt     = FUNCTION_NAME_FRSTPT
        point      =  FUNCTION_NAME_POINT
        vector     = FUNCTION_NAME_VECTOR
        gschup     = FUNCTION_NAME_GSCHUP
      PREINIT:
        typedef void (*ncar_function)( float*, float* );
      INPUT:
        float X;
        float Y;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &X, &Y );


void
NCAR_FUNCTION_0025( U, V, W )
      ALIAS:
        frst3      =  FUNCTION_NAME_FRST3
        point3     = FUNCTION_NAME_POINT3
        vect3      =  FUNCTION_NAME_VECT3
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float* );
      INPUT:
        float U;
        float V;
        float W;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &U, &V, &W );


void
NCAR_FUNCTION_0026( XA, YA, XB, YB )
      ALIAS:
        lined      =  FUNCTION_NAME_LINED
        dpline     = FUNCTION_NAME_DPLINE
        mappos     = FUNCTION_NAME_MAPPOS
        wmbarb     = FUNCTION_NAME_WMBARB
        line       =   FUNCTION_NAME_LINE
        tdlnpa     = FUNCTION_NAME_TDLNPA
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float* );
      INPUT:
        float XA;
        float YA;
        float XB;
        float YB;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &XA, &YA, &XB, &YB );


void
nggsog( SLAT, SLON, SRAD, ALAT, ALON )
      PREINIT:
      INPUT:
        float SLAT;
        float SLON;
        float SRAD;
        pdl* ALAT;
        pdl* ALON;
      CODE:
        ncar_pdl_check_in( ALAT, GvNAME(CvGV(cv)), 3, PDL_F, 1, 6 );
        ncar_pdl_check_in( ALON, GvNAME(CvGV(cv)), 4, PDL_F, 1, 6 );
        nggsog_( &SLAT, &SLON, &SRAD, ( float* )ALAT->data, ( float* )ALON->data );
        ncar_pdl_check_out( ALAT );
        ncar_pdl_check_out( ALON );


void
nggcog( CLAT, CLON, CRAD, ALAT, ALON, NPTS )
      PREINIT:
      INPUT:
        float CLAT;
        float CLON;
        float CRAD;
        pdl* ALAT;
        pdl* ALON;
        int NPTS;
      CODE:
        ncar_pdl_check_in( ALAT, GvNAME(CvGV(cv)), 3, PDL_F, 0 );
        ncar_pdl_check_in( ALON, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        nggcog_( &CLAT, &CLON, &CRAD, ( float* )ALAT->data, ( float* )ALON->data, &NPTS );
        ncar_pdl_check_out( ALAT );
        ncar_pdl_check_out( ALON );


void
NCAR_FUNCTION_0027( UA, VA, WA, UB, VB, WB )
      ALIAS:
        line3      =  FUNCTION_NAME_LINE3
        tdline     = FUNCTION_NAME_TDLINE
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float*, float*, float* );
      INPUT:
        float UA;
        float VA;
        float WA;
        float UB;
        float VB;
        float WB;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &UA, &VA, &WA, &UB, &VB, &WB );


void
setr( XMIN, XMAX, YMIN, YMAX, ZMIN, ZMAX, R0 )
      PREINIT:
      INPUT:
        float XMIN;
        float XMAX;
        float YMIN;
        float YMAX;
        float ZMIN;
        float ZMAX;
        float R0;
      CODE:
        setr_( &XMIN, &XMAX, &YMIN, &YMAX, &ZMIN, &ZMAX, &R0 );


void
NCAR_FUNCTION_0028( XCOP, YCOP, XCOQ, YCOQ, OFFX, OFFY, SIZE, ANGL, CENT )
      ALIAS:
        mdlbln     = FUNCTION_NAME_MDLBLN
        mdlblt     = FUNCTION_NAME_MDLBLT
        tdpara     = FUNCTION_NAME_TDPARA
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float*, float*, float*, float*, float*, float* );
      INPUT:
        float XCOP;
        float YCOP;
        float XCOQ;
        float YCOQ;
        float OFFX;
        float OFFY;
        float SIZE;
        float ANGL;
        float CENT;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &XCOP, &YCOP, &XCOQ, &YCOQ, &OFFX, &OFFY, &SIZE, &ANGL, &CENT );


void
tdinit( UMID, VMID, WMID, UORI, VORI, WORI, UTHI, VTHI, WTHI, OTEP )
      PREINIT:
      INPUT:
        float UMID;
        float VMID;
        float WMID;
        float UORI;
        float VORI;
        float WORI;
        float UTHI;
        float VTHI;
        float WTHI;
        float OTEP;
      CODE:
        tdinit_( &UMID, &VMID, &WMID, &UORI, &VORI, &WORI, &UTHI, &VTHI, &WTHI, &OTEP );


void
set3( XA, XB, YA, YB, ULO, UHI, VLO, VHI, WLO, WHI, EYE )
      PREINIT:
      INPUT:
        float XA;
        float XB;
        float YA;
        float YB;
        float ULO;
        float UHI;
        float VLO;
        float VHI;
        float WLO;
        float WHI;
        pdl* EYE;
      CODE:
        ncar_pdl_check_in( EYE, GvNAME(CvGV(cv)), 10, PDL_F, 1, 3 );
        set3_( &XA, &XB, &YA, &YB, &ULO, &UHI, &VLO, &VHI, &WLO, &WHI, ( float* )EYE->data );
        ncar_pdl_check_out( EYE );


void
tdgrds( UMIN, VMIN, WMIN, UMAX, VMAX, WMAX, USTP, VSTP, WSTP, IGRT, IHID )
      PREINIT:
      INPUT:
        float UMIN;
        float VMIN;
        float WMIN;
        float UMAX;
        float VMAX;
        float WMAX;
        float USTP;
        float VSTP;
        float WSTP;
        int IGRT;
        int IHID;
      CODE:
        tdgrds_( &UMIN, &VMIN, &WMIN, &UMAX, &VMAX, &WMAX, &USTP, &VSTP, &WSTP, &IGRT, &IHID );


void
set( VL, VR, VB, VT, WL, WR, WB, WT, LF )
      PREINIT:
      INPUT:
        float VL;
        float VR;
        float VB;
        float VT;
        float WL;
        float WR;
        float WB;
        float WT;
        int LF;
      CODE:
        set_( &VL, &VR, &VB, &VT, &WL, &WR, &WB, &WT, &LF );


void
gevtm( X0, Y0, DX, DY, PHI, SX, SY, SW, MOUT )
      PREINIT:
      INPUT:
        float X0;
        float Y0;
        float DX;
        float DY;
        float PHI;
        float SX;
        float SY;
        int SW;
        pdl* MOUT;
      CODE:
        ncar_pdl_check_in( MOUT, GvNAME(CvGV(cv)), 8, PDL_F, 2, 2, 3 );
        gevtm_( &X0, &Y0, &DX, &DY, &PHI, &SX, &SY, &SW, ( float* )MOUT->data );
        ncar_pdl_check_out( MOUT );


void
NCAR_FUNCTION_0029( UT, VT, WT, XT, YT, ZT, IENT )
      ALIAS:
        istr32     = FUNCTION_NAME_ISTR32
        trn32i     = FUNCTION_NAME_TRN32I
        trn32s     = FUNCTION_NAME_TRN32S
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float*, float*, float*, int* );
      INPUT:
        float UT;
        float VT;
        float WT;
        float XT;
        float YT;
        float ZT;
        int IENT;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &UT, &VT, &WT, &XT, &YT, &ZT, &IENT );


void
tdlbls( UMIN, VMIN, WMIN, UMAX, VMAX, WMAX, UNLB, VNLB, WNLB, UILB, VILB, WILB, IPCK )
      PREINIT:
      INPUT:
        float UMIN;
        float VMIN;
        float WMIN;
        float UMAX;
        float VMAX;
        float WMAX;
        char* UNLB;
        char* VNLB;
        char* WNLB;
        char* UILB;
        char* VILB;
        char* WILB;
        int IPCK;
      CODE:
        tdlbls_( &UMIN, &VMIN, &WMIN, &UMAX, &VMAX, &WMAX, UNLB, VNLB, WNLB, UILB, VILB, WILB, &IPCK, (long)strlen( UNLB ), (long)strlen( VNLB ), (long)strlen( WNLB ), (long)strlen( UILB ), (long)strlen( VILB ), (long)strlen( WILB ) );


void
mapgci( ALAT, ALON, BLAT, BLON, NOPI, RLTI, RLNI )
      PREINIT:
      INPUT:
        float ALAT;
        float ALON;
        float BLAT;
        float BLON;
        int NOPI;
        pdl* RLTI;
        pdl* RLNI;
      CODE:
        ncar_pdl_check_in( RLTI, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ncar_pdl_check_in( RLNI, GvNAME(CvGV(cv)), 6, PDL_F, 0 );
        mapgci_( &ALAT, &ALON, &BLAT, &BLON, &NOPI, ( float* )RLTI->data, ( float* )RLNI->data );
        ncar_pdl_check_out( RLTI );
        ncar_pdl_check_out( RLNI );


void
ardbda( X1, X2, Y1, Y2, IL, IR, IF, IG )
      PREINIT:
      INPUT:
        float X1;
        float X2;
        float Y1;
        float Y2;
        int IL;
        int IR;
        int IF;
        int IG;
      CODE:
        ardbda_( &X1, &X2, &Y1, &Y2, &IL, &IR, &IF, &IG );


void
gca( PX, PY, QX, QY, DIMX, DIMY, NCS, NRS, DX, DY, COLIA )
      PREINIT:
      INPUT:
        float PX;
        float PY;
        float QX;
        float QY;
        int DIMX;
        int DIMY;
        int NCS;
        int NRS;
        int DX;
        int DY;
        pdl* COLIA;
      CODE:
        ncar_pdl_check_in( COLIA, GvNAME(CvGV(cv)), 10, PDL_L, 0 );
        gca_( &PX, &PY, &QX, &QY, &DIMX, &DIMY, &NCS, &NRS, &DX, &DY, ( int* )COLIA->data );
        ncar_pdl_check_out( COLIA );


void
tdprpt( UI3D, VI3D, WI3D, XI2D, YI2D )
      PREINIT:
      INPUT:
        float UI3D;
        float VI3D;
        float WI3D;
        float &XI2D;
        float &YI2D;
      CODE:
        tdprpt_( &UI3D, &VI3D, &WI3D, &XI2D, &YI2D );
      OUTPUT:
        XI2D
        YI2D


void
NCAR_FUNCTION_0030( H, L, S, R, G, B )
      ALIAS:
        hlsrgb     = FUNCTION_NAME_HLSRGB
        hsvrgb     = FUNCTION_NAME_HSVRGB
        rgbhls     = FUNCTION_NAME_RGBHLS
        rgbhsv     = FUNCTION_NAME_RGBHSV
        rgbyiq     = FUNCTION_NAME_RGBYIQ
        yiqrgb     = FUNCTION_NAME_YIQRGB
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float*, float*, float* );
      INPUT:
        float H;
        float L;
        float S;
        float &R;
        float &G;
        float &B;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &H, &L, &S, &R, &G, &B );
      OUTPUT:
        R
        G
        B


void
msceez( DEL1, DEL2, SIGMA, C1, C2, C3, N )
      PREINIT:
      INPUT:
        float DEL1;
        float DEL2;
        float SIGMA;
        float &C1;
        float &C2;
        float &C3;
        int N;
      CODE:
        msceez_( &DEL1, &DEL2, &SIGMA, &C1, &C2, &C3, &N );
      OUTPUT:
        C1
        C2
        C3


void
shgetnp( PX, PY, PZ, N, X, Y, Z, IFLAG, IRK, RWK, NP, IER )
      PREINIT:
      INPUT:
        float PX;
        float PY;
        float PZ;
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int IFLAG;
        pdl* IRK;
        pdl* RWK;
        int &NP;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( IRK, GvNAME(CvGV(cv)), 8, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 9, PDL_F, 0 );
        shgetnp_( &PX, &PY, &PZ, &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &IFLAG, ( int* )IRK->data, ( float* )RWK->data, &NP, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( IRK );
        ncar_pdl_check_out( RWK );
      OUTPUT:
        NP
        IER


void
NCAR_FUNCTION_0031( X, Y, Z, ID, N, ISIZE, LIN3, ITOP, ICNT )
      ALIAS:
        pwrzi      =  FUNCTION_NAME_PWRZI
        pwrzs      =  FUNCTION_NAME_PWRZS
        pwrzt      =  FUNCTION_NAME_PWRZT
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, char*, int*, int*, int*, int*, int*, long );
      INPUT:
        float X;
        float Y;
        float Z;
        char* ID;
        int N;
        int ISIZE;
        int LIN3;
        int ITOP;
        int ICNT;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &X, &Y, &Z, ID, &N, &ISIZE, &LIN3, &ITOP, &ICNT, (long)strlen( ID ) );


void
nnpnts( X, Y, Z )
      PREINIT:
      INPUT:
        float X;
        float Y;
        float &Z;
      CODE:
        nnpnts_( &X, &Y, &Z );
      OUTPUT:
        Z


void
NCAR_FUNCTION_0032( RLAT, RLON, UVAL, VVAL )
      ALIAS:
        maptra     = FUNCTION_NAME_MAPTRA
        maptri     = FUNCTION_NAME_MAPTRI
        maptrn     = FUNCTION_NAME_MAPTRN
        mdutfs     = FUNCTION_NAME_MDUTFS
        mdutis     = FUNCTION_NAME_MDUTIS
        mputfs     = FUNCTION_NAME_MPUTFS
        mputis     = FUNCTION_NAME_MPUTIS
        supcon     = FUNCTION_NAME_SUPCON
        tdprpa     = FUNCTION_NAME_TDPRPA
        tdprpi     = FUNCTION_NAME_TDPRPI
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float* );
      INPUT:
        float RLAT;
        float RLON;
        float &UVAL;
        float &VVAL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &RLAT, &RLON, &UVAL, &VVAL );
      OUTPUT:
        UVAL
        VVAL


void
NCAR_FUNCTION_0033( XCPF, YCPF, IFVL )
      ALIAS:
        dpdraw     = FUNCTION_NAME_DPDRAW
        dpsmth     = FUNCTION_NAME_DPSMTH
        mapit      =  FUNCTION_NAME_MAPIT
        mapitd     = FUNCTION_NAME_MAPITD
        ispltf     = FUNCTION_NAME_ISPLTF
        plotif     = FUNCTION_NAME_PLOTIF
      PREINIT:
        typedef void (*ncar_function)( float*, float*, int* );
      INPUT:
        float XCPF;
        float YCPF;
        int IFVL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &XCPF, &YCPF, &IFVL );


void
msbsf2( DXMIN, DXMAX, MD, DYMIN, DYMAX, ND, DZ, IDZ, M, N, XMIN, XMAX, YMIN, YMAX, Z, IZ, ZP, WORK, SIGMA )
      PREINIT:
      INPUT:
        float DXMIN;
        float DXMAX;
        int MD;
        float DYMIN;
        float DYMAX;
        int ND;
        pdl* DZ;
        int IDZ;
        int M;
        int N;
        float XMIN;
        float XMAX;
        float YMIN;
        float YMAX;
        pdl* Z;
        int IZ;
        pdl* ZP;
        pdl* WORK;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( DZ, GvNAME(CvGV(cv)), 6, PDL_F, 2, IDZ, ND );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 14, PDL_F, 2, IZ, N );
        ncar_pdl_check_in( ZP, GvNAME(CvGV(cv)), 16, PDL_F, 3, M, N, 3 );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 17, PDL_F, 2, 4, MD );
        msbsf2_( &DXMIN, &DXMAX, &MD, &DYMIN, &DYMAX, &ND, ( float* )DZ->data, &IDZ, &M, &N, &XMIN, &XMAX, &YMIN, &YMAX, ( float* )Z->data, &IZ, ( float* )ZP->data, ( float* )WORK->data, &SIGMA );
        ncar_pdl_check_out( DZ );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( ZP );
        ncar_pdl_check_out( WORK );


void
tdgrid( XBEG, XSTP, NOXS, YBEG, YSTP, NOYS, IGRD )
      PREINIT:
      INPUT:
        float XBEG;
        float XSTP;
        int NOXS;
        float YBEG;
        float YSTP;
        int NOYS;
        int IGRD;
      CODE:
        tdgrid_( &XBEG, &XSTP, &NOXS, &YBEG, &YSTP, &NOYS, &IGRD );


void
mapitm( XLAT, XLON, IFST, IAM, XCS, YCS, MCS, IAI, IAG, MAI, LPR_ )
      PREINIT:
      INPUT:
        float XLAT;
        float XLON;
        int IFST;
        pdl* IAM;
        pdl* XCS;
        pdl* YCS;
        int MCS;
        pdl* IAI;
        pdl* IAG;
        int MAI;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        ncar_pdl_check_in( XCS, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( YCS, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 7, PDL_L, 0 );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 8, PDL_L, 0 );
        perl_ncar_callback = LPR_;
        mapitm_( &XLAT, &XLON, &IFST, ( int* )IAM->data, ( float* )XCS->data, ( float* )YCS->data, &MCS, ( int* )IAI->data, ( int* )IAG->data, &MAI, &c_ncar_callback_LPR );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( XCS );
        ncar_pdl_check_out( YCS );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );
        perl_ncar_callback = ( SV* )0;


void
mapita( XLAT, XLON, IFST, IAMP, IGRP, IDLT, IDRT )
      PREINIT:
      INPUT:
        float XLAT;
        float XLON;
        int IFST;
        pdl* IAMP;
        int IGRP;
        int IDLT;
        int IDRT;
      CODE:
        ncar_pdl_check_in( IAMP, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        mapita_( &XLAT, &XLON, &IFST, ( int* )IAMP->data, &IGRP, &IDLT, &IDRT );
        ncar_pdl_check_out( IAMP );


void
wmlgnd( X, Y, NTYPE, IROWS, ICOLS )
      PREINIT:
      INPUT:
        float X;
        float Y;
        int NTYPE;
        int IROWS;
        int ICOLS;
      CODE:
        wmlgnd_( &X, &Y, &NTYPE, &IROWS, &ICOLS );


void
fl2int( PX, PY, IX, IY )
      PREINIT:
      INPUT:
        float PX;
        float PY;
        int &IX;
        int &IY;
      CODE:
        fl2int_( &PX, &PY, &IX, &IY );
      OUTPUT:
        IX
        IY


void
wmstnm( X, Y, IMDAT )
      PREINIT:
        long IMDAT_len;
      INPUT:
        float X;
        float Y;
        string1D* IMDAT;
      CODE:
        wmstnm_( &X, &Y, IMDAT, IMDAT_len );


void
NCAR_FUNCTION_0034( X, Y, SYMTYP )
      ALIAS:
        wmlabs     = FUNCTION_NAME_WMLABS
        wmlabw     = FUNCTION_NAME_WMLABW
        gtx        =    FUNCTION_NAME_GTX
      PREINIT:
        typedef void (*ncar_function)( float*, float*, char*, long );
      INPUT:
        float X;
        float Y;
        char* SYMTYP;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &X, &Y, SYMTYP, (long)strlen( SYMTYP ) );


void
NCAR_FUNCTION_0035( XPOS, YPOS, CHRS, SIZE, ANGD, CNTR )
      ALIAS:
        pchiqu     = FUNCTION_NAME_PCHIQU
        plchhq     = FUNCTION_NAME_PLCHHQ
        pcloqu     = FUNCTION_NAME_PCLOQU
        plchlq     = FUNCTION_NAME_PLCHLQ
        pcmequ     = FUNCTION_NAME_PCMEQU
        plchmq     = FUNCTION_NAME_PLCHMQ
        tdplch     = FUNCTION_NAME_TDPLCH
      PREINIT:
        typedef void (*ncar_function)( float*, float*, char*, float*, float*, float*, long );
      INPUT:
        float XPOS;
        float YPOS;
        char* CHRS;
        float SIZE;
        float ANGD;
        float CNTR;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &XPOS, &YPOS, CHRS, &SIZE, &ANGD, &CNTR, (long)strlen( CHRS ) );


void
wmlabt( X, Y, LABEL, IFLG )
      PREINIT:
      INPUT:
        float X;
        float Y;
        char* LABEL;
        int IFLG;
      CODE:
        wmlabt_( &X, &Y, LABEL, &IFLG, (long)strlen( LABEL ) );


void
wtstr( PX, PY, CH, IS, IO, IC )
      PREINIT:
      INPUT:
        float PX;
        float PY;
        char* CH;
        int IS;
        int IO;
        int IC;
      CODE:
        wtstr_( &PX, &PY, CH, &IS, &IO, &IC, (long)strlen( CH ) );


void
NCAR_FUNCTION_0036( PX, PY, CH, NC, IS, IO, IC )
      ALIAS:
        pwrit      =  FUNCTION_NAME_PWRIT
        pwritx     = FUNCTION_NAME_PWRITX
      PREINIT:
        typedef void (*ncar_function)( float*, float*, char*, int*, int*, int*, int*, long );
      INPUT:
        float PX;
        float PY;
        char* CH;
        int NC;
        int IS;
        int IO;
        int IC;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &PX, &PY, CH, &NC, &IS, &IO, &IC, (long)strlen( CH ) );


void
encd( VALU, ASH, IOUT, NC, IOFFD )
      PREINIT:
      INPUT:
        float VALU;
        float ASH;
        char* IOUT;
        int &NC;
        int IOFFD;
      CODE:
        encd_( &VALU, &ASH, IOUT, &NC, &IOFFD, (long)strlen( IOUT ) );
      OUTPUT:
        NC


void
wmlabc( X, Y, CITY, TEMPS )
      PREINIT:
      INPUT:
        float X;
        float Y;
        char* CITY;
        char* TEMPS;
      CODE:
        wmlabc_( &X, &Y, CITY, TEMPS, (long)strlen( CITY ), (long)strlen( TEMPS ) );


void
NCAR_FUNCTION_0037( T, XS, YS, XST, YST, XSTT, YSTT, N, X, Y, XP, YP, S, SIGMA )
      ALIAS:
        kurvd      =  FUNCTION_NAME_KURVD
        kurvpd     = FUNCTION_NAME_KURVPD
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, float*, float*, float*, float*, int*, float*, float*, float*, float*, float*, float* );
      INPUT:
        float T;
        float &XS;
        float &YS;
        float &XST;
        float &YST;
        float &XSTT;
        float &YSTT;
        int N;
        pdl* X;
        pdl* Y;
        pdl* XP;
        pdl* YP;
        pdl* S;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 9, PDL_F, 1, N );
        ncar_pdl_check_in( XP, GvNAME(CvGV(cv)), 10, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 11, PDL_F, 1, N );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 12, PDL_F, 1, N );
        (*((ncar_function)ncar_functions[ix]))( &T, &XS, &YS, &XST, &YST, &XSTT, &YSTT, &N, ( float* )X->data, ( float* )Y->data, ( float* )XP->data, ( float* )YP->data, ( float* )S->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XP );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( S );
      OUTPUT:
        XS
        YS
        XST
        YST
        XSTT
        YSTT


void
mskrv2( T, XS, YS, N, X, Y, XP, YP, S, SIGMA, ICS, SLP )
      PREINIT:
      INPUT:
        float T;
        float &XS;
        float &YS;
        int N;
        pdl* X;
        pdl* Y;
        pdl* XP;
        pdl* YP;
        pdl* S;
        float SIGMA;
        int ICS;
        float &SLP;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        ncar_pdl_check_in( XP, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        mskrv2_( &T, &XS, &YS, &N, ( float* )X->data, ( float* )Y->data, ( float* )XP->data, ( float* )YP->data, ( float* )S->data, &SIGMA, &ICS, &SLP );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XP );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( S );
      OUTPUT:
        XS
        YS
        SLP


void
NCAR_FUNCTION_0038( T, XS, YS, N, X, Y, XP, YP, S, SIGMA )
      ALIAS:
        kurv2      =  FUNCTION_NAME_KURV2
        kurvp2     = FUNCTION_NAME_KURVP2
      PREINIT:
        typedef void (*ncar_function)( float*, float*, float*, int*, float*, float*, float*, float*, float*, float* );
      INPUT:
        float T;
        float &XS;
        float &YS;
        int N;
        pdl* X;
        pdl* Y;
        pdl* XP;
        pdl* YP;
        pdl* S;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        ncar_pdl_check_in( XP, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        (*((ncar_function)ncar_functions[ix]))( &T, &XS, &YS, &N, ( float* )X->data, ( float* )Y->data, ( float* )XP->data, ( float* )YP->data, ( float* )S->data, &SIGMA );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XP );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( S );
      OUTPUT:
        XS
        YS


void
slogap( TIME, MTST )
      PREINIT:
      INPUT:
        float TIME;
        int MTST;
      CODE:
        slogap_( &TIME, &MTST );


void
mstrms( DIAG, SDIAG, SIGMA, DEL )
      PREINIT:
      INPUT:
        float &DIAG;
        float &SDIAG;
        float SIGMA;
        float DEL;
      CODE:
        mstrms_( &DIAG, &SDIAG, &SIGMA, &DEL );
      OUTPUT:
        DIAG
        SDIAG


void
msshch( SINHM, COSHM, X, ISW )
      PREINIT:
      INPUT:
        float &SINHM;
        float &COSHM;
        float X;
        int ISW;
      CODE:
        msshch_( &SINHM, &COSHM, &X, &ISW );
      OUTPUT:
        SINHM
        COSHM


void
getset( VL, VR, VB, VT, WL, WR, WB, WT, LF )
      PREINIT:
      INPUT:
        float &VL;
        float &VR;
        float &VB;
        float &VT;
        float &WL;
        float &WR;
        float &WB;
        float &WT;
        int &LF;
      CODE:
        getset_( &VL, &VR, &VB, &VT, &WL, &WR, &WB, &WT, &LF );
      OUTPUT:
        VL
        VR
        VB
        VT
        WL
        WR
        WB
        WT
        LF


void
NCAR_FUNCTION_0039( IFNO )
      ALIAS:
        agrstr     = FUNCTION_NAME_AGRSTR
        agsave     = FUNCTION_NAME_AGSAVE
        dashdb     = FUNCTION_NAME_DASHDB
        maprst     = FUNCTION_NAME_MAPRST
        mapsav     = FUNCTION_NAME_MAPSAV
        mdprst     = FUNCTION_NAME_MDPRST
        mdpsav     = FUNCTION_NAME_MDPSAV
        gflas1     = FUNCTION_NAME_GFLAS1
        gflas3     = FUNCTION_NAME_GFLAS3
        ngmftc     = FUNCTION_NAME_NGMFTC
        pcdlsc     = FUNCTION_NAME_PCDLSC
        ftitle     = FUNCTION_NAME_FTITLE
        retsr      =  FUNCTION_NAME_RETSR
        gacwk      =  FUNCTION_NAME_GACWK
        gclwk      =  FUNCTION_NAME_GCLWK
        gcrsg      =  FUNCTION_NAME_GCRSG
        gdawk      =  FUNCTION_NAME_GDAWK
        gdsg       =   FUNCTION_NAME_GDSG
        gsclip     = FUNCTION_NAME_GSCLIP
        gselnt     = FUNCTION_NAME_GSELNT
        gsfaci     = FUNCTION_NAME_GSFACI
        gsfais     = FUNCTION_NAME_GSFAIS
        gsfasi     = FUNCTION_NAME_GSFASI
        gsln       =   FUNCTION_NAME_GSLN
        gsmk       =   FUNCTION_NAME_GSMK
        gsplci     = FUNCTION_NAME_GSPLCI
        gspmci     = FUNCTION_NAME_GSPMCI
        gstxci     = FUNCTION_NAME_GSTXCI
        gstxp      =  FUNCTION_NAME_GSTXP
      PREINIT:
        typedef void (*ncar_function)( int* );
      INPUT:
        int IFNO;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &IFNO );


void
gsasf( LASF )
      PREINIT:
      INPUT:
        pdl* LASF;
      CODE:
        ncar_pdl_check_in( LASF, GvNAME(CvGV(cv)), 0, PDL_L, 1, 13 );
        gsasf_( ( int* )LASF->data );
        ncar_pdl_check_out( LASF );


void
NCAR_FUNCTION_0040( IDP )
      ALIAS:
        sfgetp     = FUNCTION_NAME_SFGETP
        sfsetp     = FUNCTION_NAME_SFSETP
      PREINIT:
        typedef void (*ncar_function)( int* );
      INPUT:
        pdl* IDP;
      CODE:
        ncar_pdl_check_in( IDP, GvNAME(CvGV(cv)), 0, PDL_L, 2, 8, 8 );
        (*((ncar_function)ncar_functions[ix]))( ( int* )IDP->data );
        ncar_pdl_check_out( IDP );


void
arinam( IAM, LAM )
      PREINIT:
      INPUT:
        pdl* IAM;
        int LAM;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 1, LAM );
        arinam_( ( int* )IAM->data, &LAM );
        ncar_pdl_check_out( IAM );


void
cpscae( ICRA, ICA1, ICAM, ICAN, XCPF, YCPF, XCQF, YCQF, IND1, IND2, ICAF, IAID )
      PREINIT:
      INPUT:
        pdl* ICRA;
        int ICA1;
        int ICAM;
        int ICAN;
        float XCPF;
        float YCPF;
        float XCQF;
        float YCQF;
        int IND1;
        int IND2;
        int ICAF;
        int IAID;
      CODE:
        ncar_pdl_check_in( ICRA, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        cpscae_( ( int* )ICRA->data, &ICA1, &ICAM, &ICAN, &XCPF, &YCPF, &XCQF, &YCQF, &IND1, &IND2, &ICAF, &IAID );
        ncar_pdl_check_out( ICRA );


void
NCAR_FUNCTION_0041( IAMP )
      ALIAS:
        mapbla     = FUNCTION_NAME_MAPBLA
        mdpbla     = FUNCTION_NAME_MDPBLA
      PREINIT:
        typedef void (*ncar_function)( int* );
      INPUT:
        pdl* IAMP;
      CODE:
        ncar_pdl_check_in( IAMP, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        (*((ncar_function)ncar_functions[ix]))( ( int* )IAMP->data );
        ncar_pdl_check_out( IAMP );


void
arscam( IAM, XCS, YCS, MCS, IAI, IAG, MAI, LPR_ )
      PREINIT:
      INPUT:
        pdl* IAM;
        pdl* XCS;
        pdl* YCS;
        int MCS;
        pdl* IAI;
        pdl* IAG;
        int MAI;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ncar_pdl_check_in( XCS, GvNAME(CvGV(cv)), 1, PDL_F, 1, MCS );
        ncar_pdl_check_in( YCS, GvNAME(CvGV(cv)), 2, PDL_F, 1, MCS );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 4, PDL_L, 1, MAI );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 5, PDL_L, 1, MAI );
        perl_ncar_callback = LPR_;
        arscam_( ( int* )IAM->data, ( float* )XCS->data, ( float* )YCS->data, &MCS, ( int* )IAI->data, ( int* )IAG->data, &MAI, &c_ncar_callback_LPR );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( XCS );
        ncar_pdl_check_out( YCS );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );
        perl_ncar_callback = ( SV* )0;


void
ardrln( IAM, XCD, YCD, NCD, XCS, YCS, MCS, IAI, IAG, MAI, LPR_ )
      PREINIT:
      INPUT:
        pdl* IAM;
        pdl* XCD;
        pdl* YCD;
        int NCD;
        pdl* XCS;
        pdl* YCS;
        int MCS;
        pdl* IAI;
        pdl* IAG;
        int MAI;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ncar_pdl_check_in( XCD, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( YCD, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        ncar_pdl_check_in( XCS, GvNAME(CvGV(cv)), 4, PDL_F, 0 );
        ncar_pdl_check_in( YCS, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 7, PDL_L, 0 );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 8, PDL_L, 0 );
        perl_ncar_callback = LPR_;
        ardrln_( ( int* )IAM->data, ( float* )XCD->data, ( float* )YCD->data, &NCD, ( float* )XCS->data, ( float* )YCS->data, &MCS, ( int* )IAI->data, ( int* )IAG->data, &MAI, &c_ncar_callback_LPR );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( XCD );
        ncar_pdl_check_out( YCD );
        ncar_pdl_check_out( XCS );
        ncar_pdl_check_out( YCS );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );
        perl_ncar_callback = ( SV* )0;


void
NCAR_FUNCTION_0042( IAM, XCS, YCS, MCS, IAI, IAG, MAI, LPR_ )
      ALIAS:
        mapblm     = FUNCTION_NAME_MAPBLM
        mapgrm     = FUNCTION_NAME_MAPGRM
        mapiqm     = FUNCTION_NAME_MAPIQM
        mdpblm     = FUNCTION_NAME_MDPBLM
        mdpgrm     = FUNCTION_NAME_MDPGRM
        mdpiqm     = FUNCTION_NAME_MDPIQM
      PREINIT:
        typedef void (*ncar_function)( int*, float*, float*, int*, int*, int*, int*, void* );
      INPUT:
        pdl* IAM;
        pdl* XCS;
        pdl* YCS;
        int MCS;
        pdl* IAI;
        pdl* IAG;
        int MAI;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ncar_pdl_check_in( XCS, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( YCS, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 4, PDL_L, 0 );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        perl_ncar_callback = LPR_;
        (*((ncar_function)ncar_functions[ix]))( ( int* )IAM->data, ( float* )XCS->data, ( float* )YCS->data, &MCS, ( int* )IAI->data, ( int* )IAG->data, &MAI, &c_ncar_callback_LPR );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( XCS );
        ncar_pdl_check_out( YCS );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );
        perl_ncar_callback = ( SV* )0;


void
aredam( IAM, XCA, YCA, LCA, IGI, IDL, IDR )
      PREINIT:
      INPUT:
        pdl* IAM;
        pdl* XCA;
        pdl* YCA;
        int LCA;
        int IGI;
        int IDL;
        int IDR;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ncar_pdl_check_in( XCA, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( YCA, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        aredam_( ( int* )IAM->data, ( float* )XCA->data, ( float* )YCA->data, &LCA, &IGI, &IDL, &IDR );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( XCA );
        ncar_pdl_check_out( YCA );


void
argtai( IAM, XCD, YCD, IAI, IAG, MAI, NAI, ICF )
      PREINIT:
      INPUT:
        pdl* IAM;
        float XCD;
        float YCD;
        pdl* IAI;
        pdl* IAG;
        int MAI;
        int &NAI;
        int ICF;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ncar_pdl_check_in( IAI, GvNAME(CvGV(cv)), 3, PDL_L, 0 );
        ncar_pdl_check_in( IAG, GvNAME(CvGV(cv)), 4, PDL_L, 0 );
        argtai_( ( int* )IAM->data, &XCD, &YCD, ( int* )IAI->data, ( int* )IAG->data, &MAI, &NAI, &ICF );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( IAI );
        ncar_pdl_check_out( IAG );
      OUTPUT:
        NAI


void
armvam( IAM, IAN, LAN )
      PREINIT:
      INPUT:
        pdl* IAM;
        pdl* IAN;
        int LAN;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ncar_pdl_check_in( IAN, GvNAME(CvGV(cv)), 1, PDL_L, 0 );
        armvam_( ( int* )IAM->data, ( int* )IAN->data, &LAN );
        ncar_pdl_check_out( IAM );
        ncar_pdl_check_out( IAN );


void
NCAR_FUNCTION_0043( IAM, IF1, IF2, IF3 )
      ALIAS:
        arpram     = FUNCTION_NAME_ARPRAM
        mapiqa     = FUNCTION_NAME_MAPIQA
        mdpiqa     = FUNCTION_NAME_MDPIQA
      PREINIT:
        typedef void (*ncar_function)( int*, int*, int*, int* );
      INPUT:
        pdl* IAM;
        int IF1;
        int IF2;
        int IF3;
      CODE:
        ncar_pdl_check_in( IAM, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        (*((ncar_function)ncar_functions[ix]))( ( int* )IAM->data, &IF1, &IF2, &IF3 );
        ncar_pdl_check_out( IAM );


void
ardbpa( IAMA, IGIP, LABL )
      PREINIT:
      INPUT:
        pdl* IAMA;
        int IGIP;
        char* LABL;
      CODE:
        ncar_pdl_check_in( IAMA, GvNAME(CvGV(cv)), 0, PDL_L, 0 );
        ardbpa_( ( int* )IAMA->data, &IGIP, LABL, (long)strlen( LABL ) );
        ncar_pdl_check_out( IAMA );


void
nnpntinitd( NPNTS, X, Y, Z )
      PREINIT:
      INPUT:
        int NPNTS;
        pdl* X;
        pdl* Y;
        pdl* Z;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_D, 1, NPNTS );
        nnpntinitd_( &NPNTS, ( double* )X->data, ( double* )Y->data, ( double* )Z->data );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );


void
NCAR_FUNCTION_0044( N, X, Y, Z, RLAT, RLON )
      ALIAS:
        csc2sd     = FUNCTION_NAME_CSC2SD
        css2cd     = FUNCTION_NAME_CSS2CD
      PREINIT:
        typedef void (*ncar_function)( int*, double*, double*, double*, double*, double* );
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* RLAT;
        pdl* RLON;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_D, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_D, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_D, 1, N );
        ncar_pdl_check_in( RLAT, GvNAME(CvGV(cv)), 4, PDL_D, 1, N );
        ncar_pdl_check_in( RLON, GvNAME(CvGV(cv)), 5, PDL_D, 1, N );
        (*((ncar_function)ncar_functions[ix]))( &N, ( double* )X->data, ( double* )Y->data, ( double* )Z->data, ( double* )RLAT->data, ( double* )RLON->data );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( RLAT );
        ncar_pdl_check_out( RLON );


void
dspnt3d( N, X, Y, Z, U, M, XO, YO, ZO, UO, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* U;
        int M;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_D, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_D, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_D, 1, N );
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 4, PDL_D, 1, N );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 6, PDL_D, 1, M );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 7, PDL_D, 1, M );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 8, PDL_D, 1, M );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 9, PDL_D, 1, M );
        dspnt3d_( &N, ( double* )X->data, ( double* )Y->data, ( double* )Z->data, ( double* )U->data, &M, ( double* )XO->data, ( double* )YO->data, ( double* )ZO->data, ( double* )UO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
      OUTPUT:
        IER


void
dsgrid3d( NPNTS, X, Y, Z, U, NUMXOUT, NUMYOUT, NUMZOUT, XO, YO, ZO, UO, IER )
      PREINIT:
      INPUT:
        int NPNTS;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* U;
        int NUMXOUT;
        int NUMYOUT;
        int NUMZOUT;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 4, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 8, PDL_D, 1, NUMXOUT );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 9, PDL_D, 1, NUMYOUT );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 10, PDL_D, 1, NUMZOUT );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 11, PDL_D, 3, NUMXOUT, NUMYOUT, NUMZOUT );
        dsgrid3d_( &NPNTS, ( double* )X->data, ( double* )Y->data, ( double* )Z->data, ( double* )U->data, &NUMXOUT, &NUMYOUT, &NUMZOUT, ( double* )XO->data, ( double* )YO->data, ( double* )ZO->data, ( double* )UO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
      OUTPUT:
        IER


void
dspnt2d( N, X, Y, Z, M, XO, YO, ZO, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int M;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_D, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_D, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_D, 1, N );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 5, PDL_D, 1, M );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 6, PDL_D, 1, M );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 7, PDL_D, 1, M );
        dspnt2d_( &N, ( double* )X->data, ( double* )Y->data, ( double* )Z->data, &M, ( double* )XO->data, ( double* )YO->data, ( double* )ZO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
      OUTPUT:
        IER


void
cssgridd( N, RLAT, RLON, F, NI, NJ, PLAT, PLON, FF, IWK, RWK, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* RLAT;
        pdl* RLON;
        pdl* F;
        int NI;
        int NJ;
        pdl* PLAT;
        pdl* PLON;
        pdl* FF;
        pdl* IWK;
        pdl* RWK;
        int &IER;
      CODE:
        ncar_pdl_check_in( RLAT, GvNAME(CvGV(cv)), 1, PDL_D, 1, N );
        ncar_pdl_check_in( RLON, GvNAME(CvGV(cv)), 2, PDL_D, 1, N );
        ncar_pdl_check_in( F, GvNAME(CvGV(cv)), 3, PDL_D, 1, N );
        ncar_pdl_check_in( PLAT, GvNAME(CvGV(cv)), 6, PDL_D, 1, NI );
        ncar_pdl_check_in( PLON, GvNAME(CvGV(cv)), 7, PDL_D, 1, NJ );
        ncar_pdl_check_in( FF, GvNAME(CvGV(cv)), 8, PDL_D, 2, NI, NJ );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 9, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 10, PDL_D, 0 );
        cssgridd_( &N, ( double* )RLAT->data, ( double* )RLON->data, ( double* )F->data, &NI, &NJ, ( double* )PLAT->data, ( double* )PLON->data, ( double* )FF->data, ( int* )IWK->data, ( double* )RWK->data, &IER );
        ncar_pdl_check_out( RLAT );
        ncar_pdl_check_out( RLON );
        ncar_pdl_check_out( F );
        ncar_pdl_check_out( PLAT );
        ncar_pdl_check_out( PLON );
        ncar_pdl_check_out( FF );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( RWK );
      OUTPUT:
        IER


void
NCAR_FUNCTION_0045( NPNTS, X, Y, Z, NUMXOUT, NUMYOUT, XO, YO, ZO, IER )
      ALIAS:
        dsgrid2d   = FUNCTION_NAME_DSGRID2D
        natgridd   = FUNCTION_NAME_NATGRIDD
      PREINIT:
        typedef void (*ncar_function)( int*, double*, double*, double*, int*, int*, double*, double*, double*, int* );
      INPUT:
        int NPNTS;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int NUMXOUT;
        int NUMYOUT;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_D, 1, NPNTS );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 6, PDL_D, 1, NUMXOUT );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 7, PDL_D, 1, NUMYOUT );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 8, PDL_D, 2, NUMXOUT, NUMYOUT );
        (*((ncar_function)ncar_functions[ix]))( &NPNTS, ( double* )X->data, ( double* )Y->data, ( double* )Z->data, &NUMXOUT, &NUMYOUT, ( double* )XO->data, ( double* )YO->data, ( double* )ZO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
      OUTPUT:
        IER


void
csvorod( NPTS, RLATI, RLONI, NI, NF, IWK, RWK, NC, RLATO, RLONO, RC, NCA, NUMV, NV, IER )
      PREINIT:
      INPUT:
        int NPTS;
        pdl* RLATI;
        pdl* RLONI;
        int NI;
        int NF;
        pdl* IWK;
        pdl* RWK;
        int NC;
        pdl* RLATO;
        pdl* RLONO;
        pdl* RC;
        int &NCA;
        int &NUMV;
        pdl* NV;
        int &IER;
      CODE:
        ncar_pdl_check_in( RLATI, GvNAME(CvGV(cv)), 1, PDL_D, 1, NPTS );
        ncar_pdl_check_in( RLONI, GvNAME(CvGV(cv)), 2, PDL_D, 1, NPTS );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 6, PDL_D, 0 );
        ncar_pdl_check_in( RLATO, GvNAME(CvGV(cv)), 8, PDL_D, 1, NC );
        ncar_pdl_check_in( RLONO, GvNAME(CvGV(cv)), 9, PDL_D, 1, NC );
        ncar_pdl_check_in( RC, GvNAME(CvGV(cv)), 10, PDL_D, 1, NC );
        ncar_pdl_check_in( NV, GvNAME(CvGV(cv)), 13, PDL_L, 1, NPTS );
        csvorod_( &NPTS, ( double* )RLATI->data, ( double* )RLONI->data, &NI, &NF, ( int* )IWK->data, ( double* )RWK->data, &NC, ( double* )RLATO->data, ( double* )RLONO->data, ( double* )RC->data, &NCA, &NUMV, ( int* )NV->data, &IER );
        ncar_pdl_check_out( RLATI );
        ncar_pdl_check_out( RLONI );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( RWK );
        ncar_pdl_check_out( RLATO );
        ncar_pdl_check_out( RLONO );
        ncar_pdl_check_out( RC );
        ncar_pdl_check_out( NV );
      OUTPUT:
        NCA
        NUMV
        IER


void
csstrid( N, RLAT, RLON, NT, NTRI, IWK, RWK, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* RLAT;
        pdl* RLON;
        int &NT;
        pdl* NTRI;
        pdl* IWK;
        pdl* RWK;
        int &IER;
      CODE:
        ncar_pdl_check_in( RLAT, GvNAME(CvGV(cv)), 1, PDL_D, 1, N );
        ncar_pdl_check_in( RLON, GvNAME(CvGV(cv)), 2, PDL_D, 1, N );
        ncar_pdl_check_in( NTRI, GvNAME(CvGV(cv)), 4, PDL_L, 0 );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 6, PDL_D, 0 );
        csstrid_( &N, ( double* )RLAT->data, ( double* )RLON->data, &NT, ( int* )NTRI->data, ( int* )IWK->data, ( double* )RWK->data, &IER );
        ncar_pdl_check_out( RLAT );
        ncar_pdl_check_out( RLON );
        ncar_pdl_check_out( NTRI );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( RWK );
      OUTPUT:
        NT
        IER


void
mdritd( IAXS, ANGL, UCRD, VCRD, WCRD )
      PREINIT:
      INPUT:
        int IAXS;
        double ANGL;
        double &UCRD;
        double &VCRD;
        double &WCRD;
      CODE:
        mdritd_( &IAXS, &ANGL, &UCRD, &VCRD, &WCRD );
      OUTPUT:
        UCRD
        VCRD
        WCRD


void
gssgt( SGNA, M )
      PREINIT:
      INPUT:
        int SGNA;
        pdl* M;
      CODE:
        ncar_pdl_check_in( M, GvNAME(CvGV(cv)), 1, PDL_F, 2, 2, 3 );
        gssgt_( &SGNA, ( float* )M->data );
        ncar_pdl_check_out( M );


void
csa2xs( NI, XI, UI, WTS, KNOTS, SMTH, NDERIV, NXO, NYO, XO, YO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* WTS;
        pdl* KNOTS;
        float SMTH;
        pdl* NDERIV;
        int NXO;
        int NYO;
        pdl* XO;
        pdl* YO;
        pdl* UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 2, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( WTS, GvNAME(CvGV(cv)), 3, PDL_F, 1, NI );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 4, PDL_L, 1, 2 );
        ncar_pdl_check_in( NDERIV, GvNAME(CvGV(cv)), 6, PDL_L, 1, 2 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NXO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 10, PDL_F, 1, NYO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 11, PDL_F, 2, NXO, NYO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 13, PDL_F, 1, NWRK );
        csa2xs_( &NI, ( float* )XI->data, ( float* )UI->data, ( float* )WTS->data, ( int* )KNOTS->data, &SMTH, ( int* )NDERIV->data, &NXO, &NYO, ( float* )XO->data, ( float* )YO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( WTS );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( NDERIV );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
csa2lxs( NI, XI, UI, WTS, KNOTS, SMTH, NDERIV, NO, XO, YO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* WTS;
        pdl* KNOTS;
        float SMTH;
        pdl* NDERIV;
        int NO;
        pdl* XO;
        pdl* YO;
        float &UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 2, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( WTS, GvNAME(CvGV(cv)), 3, PDL_F, 0 );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 4, PDL_L, 1, 2 );
        ncar_pdl_check_in( NDERIV, GvNAME(CvGV(cv)), 6, PDL_L, 1, 2 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 12, PDL_F, 0 );
        csa2lxs_( &NI, ( float* )XI->data, ( float* )UI->data, ( float* )WTS->data, ( int* )KNOTS->data, &SMTH, ( int* )NDERIV->data, &NO, ( float* )XO->data, ( float* )YO->data, &UO, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( WTS );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( NDERIV );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        UO
        IER


void
csa2ls( NI, XI, UI, KNOTS, NO, XO, YO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* KNOTS;
        int NO;
        pdl* XO;
        pdl* YO;
        pdl* UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 2, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 3, PDL_L, 1, 2 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 5, PDL_F, 1, NO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 6, PDL_F, 1, NO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 7, PDL_F, 1, NO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 9, PDL_F, 1, NWRK );
        csa2ls_( &NI, ( float* )XI->data, ( float* )UI->data, ( int* )KNOTS->data, &NO, ( float* )XO->data, ( float* )YO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
csa2s( NI, XI, UI, KNOTS, NXO, NYO, XO, YO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* KNOTS;
        int NXO;
        int NYO;
        pdl* XO;
        pdl* YO;
        pdl* UO;
        int &NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 2, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 3, PDL_L, 1, 2 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 6, PDL_F, 1, NXO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 7, PDL_F, 1, NYO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 8, PDL_F, 2, NXO, NYO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 10, PDL_F, 1, NWRK );
        csa2s_( &NI, ( float* )XI->data, ( float* )UI->data, ( int* )KNOTS->data, &NXO, &NYO, ( float* )XO->data, ( float* )YO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        NWRK
        IER


void
csa3lxs( NI, XI, UI, WTS, KNOTS, SMTH, NDERIV, NO, XO, YO, ZO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* WTS;
        pdl* KNOTS;
        float SMTH;
        pdl* NDERIV;
        int NO;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 3, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( WTS, GvNAME(CvGV(cv)), 3, PDL_F, 0 );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 4, PDL_L, 1, 3 );
        ncar_pdl_check_in( NDERIV, GvNAME(CvGV(cv)), 6, PDL_L, 1, 3 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NO );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 10, PDL_F, 1, NO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 11, PDL_F, 1, NO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 13, PDL_F, 1, NWRK );
        csa3lxs_( &NI, ( float* )XI->data, ( float* )UI->data, ( float* )WTS->data, ( int* )KNOTS->data, &SMTH, ( int* )NDERIV->data, &NO, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( WTS );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( NDERIV );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
csa3xs( NI, XI, UI, WTS, KNOTS, SMTH, NDERIV, NXO, NYO, NZO, XO, YO, ZO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* WTS;
        pdl* KNOTS;
        float SMTH;
        pdl* NDERIV;
        int NXO;
        int NYO;
        int NZO;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 3, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( WTS, GvNAME(CvGV(cv)), 3, PDL_F, 0 );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 4, PDL_L, 1, 3 );
        ncar_pdl_check_in( NDERIV, GvNAME(CvGV(cv)), 6, PDL_L, 1, 3 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 10, PDL_F, 1, NXO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 11, PDL_F, 1, NYO );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 12, PDL_F, 1, NZO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 13, PDL_F, 3, NXO, NYO, NZO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 15, PDL_F, 0 );
        csa3xs_( &NI, ( float* )XI->data, ( float* )UI->data, ( float* )WTS->data, ( int* )KNOTS->data, &SMTH, ( int* )NDERIV->data, &NXO, &NYO, &NZO, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( WTS );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( NDERIV );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
csa3ls( NI, XI, UI, KNOTS, NO, XO, YO, ZO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* KNOTS;
        int NO;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 3, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 3, PDL_L, 1, 3 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 5, PDL_F, 1, NO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 6, PDL_F, 1, NO );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 7, PDL_F, 1, NO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 10, PDL_F, 0 );
        csa3ls_( &NI, ( float* )XI->data, ( float* )UI->data, ( int* )KNOTS->data, &NO, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
csa3s( NI, XI, UI, KNOTS, NXO, NYO, NZO, XO, YO, ZO, UO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* UI;
        pdl* KNOTS;
        int NXO;
        int NYO;
        int NZO;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 2, 3, NI );
        ncar_pdl_check_in( UI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( KNOTS, GvNAME(CvGV(cv)), 3, PDL_L, 1, 3 );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 7, PDL_F, 1, NXO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NYO );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NZO );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 10, PDL_F, 3, NXO, NYO, NZO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 12, PDL_F, 1, NWRK );
        csa3s_( &NI, ( float* )XI->data, ( float* )UI->data, ( int* )KNOTS->data, &NXO, &NYO, &NZO, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )UO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( UI );
        ncar_pdl_check_out( KNOTS );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
NCAR_FUNCTION_0046( N, X, Y )
      ALIAS:
        wmdrft     = FUNCTION_NAME_WMDRFT
        wmw2nx     = FUNCTION_NAME_WMW2NX
        wmw2ny     = FUNCTION_NAME_WMW2NY
        gfa        =    FUNCTION_NAME_GFA
        gpl        =    FUNCTION_NAME_GPL
        gpm        =    FUNCTION_NAME_GPM
      PREINIT:
        typedef void (*ncar_function)( int*, float*, float* );
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        (*((ncar_function)ncar_functions[ix]))( &N, ( float* )X->data, ( float* )Y->data );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );


void
NCAR_FUNCTION_0047( N, X, Y, Z, RLAT, RLON )
      ALIAS:
        csc2s      =  FUNCTION_NAME_CSC2S
        css2c      =  FUNCTION_NAME_CSS2C
      PREINIT:
        typedef void (*ncar_function)( int*, float*, float*, float*, float*, float* );
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* RLAT;
        pdl* RLON;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( RLAT, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( RLON, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        (*((ncar_function)ncar_functions[ix]))( &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, ( float* )RLAT->data, ( float* )RLON->data );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( RLAT );
        ncar_pdl_check_out( RLON );


void
shgrid( N, X, Y, Z, F, NXO, NYO, NZO, XO, YO, ZO, FF, IRK, RWK, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* F;
        int NXO;
        int NYO;
        int NZO;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* FF;
        pdl* IRK;
        pdl* RWK;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( F, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NXO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NYO );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 10, PDL_F, 1, NZO );
        ncar_pdl_check_in( FF, GvNAME(CvGV(cv)), 11, PDL_F, 0 );
        ncar_pdl_check_in( IRK, GvNAME(CvGV(cv)), 12, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 13, PDL_F, 0 );
        shgrid_( &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, ( float* )F->data, &NXO, &NYO, &NZO, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )FF->data, ( int* )IRK->data, ( float* )RWK->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( F );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( FF );
        ncar_pdl_check_out( IRK );
        ncar_pdl_check_out( RWK );
      OUTPUT:
        IER


void
csa1xs( NI, XI, YI, WTS, KNOTS, SMTH, NDERIV, NO, XO, YO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* YI;
        pdl* WTS;
        int KNOTS;
        float SMTH;
        int NDERIV;
        int NO;
        pdl* XO;
        pdl* YO;
        int &NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 1, NI );
        ncar_pdl_check_in( YI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( WTS, GvNAME(CvGV(cv)), 3, PDL_F, 1, NI );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 11, PDL_F, 1, NWRK );
        csa1xs_( &NI, ( float* )XI->data, ( float* )YI->data, ( float* )WTS->data, &KNOTS, &SMTH, &NDERIV, &NO, ( float* )XO->data, ( float* )YO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( YI );
        ncar_pdl_check_out( WTS );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        NWRK
        IER


void
cssgrid( N, RLAT, RLON, F, NI, NJ, PLAT, PLON, FF, IWK, RWK, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* RLAT;
        pdl* RLON;
        pdl* F;
        int NI;
        int NJ;
        pdl* PLAT;
        pdl* PLON;
        pdl* FF;
        pdl* IWK;
        pdl* RWK;
        int &IER;
      CODE:
        ncar_pdl_check_in( RLAT, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( RLON, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( F, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( PLAT, GvNAME(CvGV(cv)), 6, PDL_F, 1, NI );
        ncar_pdl_check_in( PLON, GvNAME(CvGV(cv)), 7, PDL_F, 1, NJ );
        ncar_pdl_check_in( FF, GvNAME(CvGV(cv)), 8, PDL_F, 2, NI, NJ );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 9, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 10, PDL_D, 0 );
        cssgrid_( &N, ( float* )RLAT->data, ( float* )RLON->data, ( float* )F->data, &NI, &NJ, ( float* )PLAT->data, ( float* )PLON->data, ( float* )FF->data, ( int* )IWK->data, ( double* )RWK->data, &IER );
        ncar_pdl_check_out( RLAT );
        ncar_pdl_check_out( RLON );
        ncar_pdl_check_out( F );
        ncar_pdl_check_out( PLAT );
        ncar_pdl_check_out( PLON );
        ncar_pdl_check_out( FF );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( RWK );
      OUTPUT:
        IER


void
mskrv1( N, X, Y, SLP1, SLPN, XP, YP, TEMP, S, SIGMA, ISLPSW )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        float SLP1;
        float SLPN;
        pdl* XP;
        pdl* YP;
        pdl* TEMP;
        pdl* S;
        float SIGMA;
        int ISLPSW;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( XP, GvNAME(CvGV(cv)), 5, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        mskrv1_( &N, ( float* )X->data, ( float* )Y->data, &SLP1, &SLPN, ( float* )XP->data, ( float* )YP->data, ( float* )TEMP->data, ( float* )S->data, &SIGMA, &ISLPSW );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XP );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( TEMP );
        ncar_pdl_check_out( S );


void
wmrgwt( N, X, Y, IFNT, NASC )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        int IFNT;
        int NASC;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        wmrgwt_( &N, ( float* )X->data, ( float* )Y->data, &IFNT, &NASC );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );


void
csa1s( NI, XI, YI, KNOTS, NO, XO, YO, NWRK, WORK, IER )
      PREINIT:
      INPUT:
        int NI;
        pdl* XI;
        pdl* YI;
        int KNOTS;
        int NO;
        pdl* XO;
        pdl* YO;
        int NWRK;
        pdl* WORK;
        int &IER;
      CODE:
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 1, PDL_F, 1, NI );
        ncar_pdl_check_in( YI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NI );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 5, PDL_F, 1, NO );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 6, PDL_F, 1, NO );
        ncar_pdl_check_in( WORK, GvNAME(CvGV(cv)), 8, PDL_F, 1, NWRK );
        csa1s_( &NI, ( float* )XI->data, ( float* )YI->data, &KNOTS, &NO, ( float* )XO->data, ( float* )YO->data, &NWRK, ( float* )WORK->data, &IER );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( YI );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( WORK );
      OUTPUT:
        IER


void
csvoro( NPTS, RLATI, RLONI, NI, NF, IWK, RWK, NC, RLATO, RLONO, RC, NCA, NUMV, NV, IER )
      PREINIT:
      INPUT:
        int NPTS;
        pdl* RLATI;
        pdl* RLONI;
        int NI;
        int NF;
        pdl* IWK;
        pdl* RWK;
        int NC;
        pdl* RLATO;
        pdl* RLONO;
        pdl* RC;
        int &NCA;
        int &NUMV;
        pdl* NV;
        int &IER;
      CODE:
        ncar_pdl_check_in( RLATI, GvNAME(CvGV(cv)), 1, PDL_F, 1, NPTS );
        ncar_pdl_check_in( RLONI, GvNAME(CvGV(cv)), 2, PDL_F, 1, NPTS );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 6, PDL_D, 0 );
        ncar_pdl_check_in( RLATO, GvNAME(CvGV(cv)), 8, PDL_F, 1, NC );
        ncar_pdl_check_in( RLONO, GvNAME(CvGV(cv)), 9, PDL_F, 1, NC );
        ncar_pdl_check_in( RC, GvNAME(CvGV(cv)), 10, PDL_F, 1, NC );
        ncar_pdl_check_in( NV, GvNAME(CvGV(cv)), 13, PDL_L, 1, NPTS );
        csvoro_( &NPTS, ( float* )RLATI->data, ( float* )RLONI->data, &NI, &NF, ( int* )IWK->data, ( double* )RWK->data, &NC, ( float* )RLATO->data, ( float* )RLONO->data, ( float* )RC->data, &NCA, &NUMV, ( int* )NV->data, &IER );
        ncar_pdl_check_out( RLATI );
        ncar_pdl_check_out( RLONI );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( RWK );
        ncar_pdl_check_out( RLATO );
        ncar_pdl_check_out( RLONO );
        ncar_pdl_check_out( RC );
        ncar_pdl_check_out( NV );
      OUTPUT:
        NCA
        NUMV
        IER


void
wmdrrg( N, X, Y, ITYPE, NC, XC, YC )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        char* ITYPE;
        int NC;
        pdl* XC;
        pdl* YC;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( XC, GvNAME(CvGV(cv)), 5, PDL_F, 1, NC );
        ncar_pdl_check_in( YC, GvNAME(CvGV(cv)), 6, PDL_F, 1, NC );
        wmdrrg_( &N, ( float* )X->data, ( float* )Y->data, ITYPE, &NC, ( float* )XC->data, ( float* )YC->data, (long)strlen( ITYPE ) );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XC );
        ncar_pdl_check_out( YC );


void
mdrgol( IRGL, RWRK, LRWK )
      PREINIT:
      INPUT:
        int IRGL;
        pdl* RWRK;
        int LRWK;
      CODE:
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 1, LRWK );
        mdrgol_( &IRGL, ( float* )RWRK->data, &LRWK );
        ncar_pdl_check_out( RWRK );


void
mdrgsf( IRGL, RWRK, LRWK, IAMA, LAMA )
      PREINIT:
      INPUT:
        int IRGL;
        pdl* RWRK;
        int LRWK;
        pdl* IAMA;
        int LAMA;
      CODE:
        ncar_pdl_check_in( RWRK, GvNAME(CvGV(cv)), 1, PDL_F, 1, LRWK );
        ncar_pdl_check_in( IAMA, GvNAME(CvGV(cv)), 3, PDL_L, 1, LAMA );
        mdrgsf_( &IRGL, ( float* )RWRK->data, &LRWK, ( int* )IAMA->data, &LAMA );
        ncar_pdl_check_out( RWRK );
        ncar_pdl_check_out( IAMA );


void
nnpntinits( NPNTS, X, Y, Z )
      PREINIT:
      INPUT:
        int NPNTS;
        pdl* X;
        pdl* Y;
        pdl* Z;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1,  NPNTS  );
        nnpntinits_( &NPNTS, ( float* )X->data, ( float* )Y->data, ( float* )Z->data );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );


void
kurvp1( N, X, Y, XP, YP, TEMP, S, SIGMA, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* XP;
        pdl* YP;
        pdl* TEMP;
        pdl* S;
        float SIGMA;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( XP, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        kurvp1_( &N, ( float* )X->data, ( float* )Y->data, ( float* )XP->data, ( float* )YP->data, ( float* )TEMP->data, ( float* )S->data, &SIGMA, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XP );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( TEMP );
        ncar_pdl_check_out( S );
      OUTPUT:
        IER


void
dspnt3s( N, X, Y, Z, U, M, XO, YO, ZO, UO, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* U;
        int M;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1,  N  );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1,  N  );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1,  N  );
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 4, PDL_F, 1,  N  );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 6, PDL_F, 1,  M  );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 7, PDL_F, 1,  M  );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 8, PDL_F, 1,  M  );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 9, PDL_F, 1,  M  );
        dspnt3s_( &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, ( float* )U->data, &M, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )UO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
      OUTPUT:
        IER


void
dsgrid3s( NPNTS, X, Y, Z, U, NUMXOUT, NUMYOUT, NUMZOUT, XO, YO, ZO, UO, IER )
      PREINIT:
      INPUT:
        int NPNTS;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* U;
        int NUMXOUT;
        int NUMYOUT;
        int NUMZOUT;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        pdl* UO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 4, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 8, PDL_F, 1,  NUMXOUT  );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 9, PDL_F, 1,  NUMYOUT  );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 10, PDL_F, 1,  NUMZOUT  );
        ncar_pdl_check_in( UO, GvNAME(CvGV(cv)), 11, PDL_F, 3,  NUMXOUT,  NUMYOUT,  NUMZOUT  );
        dsgrid3s_( &NPNTS, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, ( float* )U->data, &NUMXOUT, &NUMYOUT, &NUMZOUT, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, ( float* )UO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( U );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
        ncar_pdl_check_out( UO );
      OUTPUT:
        IER


void
dspnt2s( N, X, Y, Z, M, XO, YO, ZO, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int M;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1,  N  );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1,  N  );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1,  N  );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 5, PDL_F, 1,  M  );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 6, PDL_F, 1,  M  );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 7, PDL_F, 1,  M  );
        dspnt2s_( &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &M, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
      OUTPUT:
        IER


void
curvs( N, X, Y, D, ISW, S, EPS, YS, YSP, SIGMA, TEMP, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        pdl* D;
        int ISW;
        float S;
        float EPS;
        pdl* YS;
        pdl* YSP;
        float SIGMA;
        pdl* TEMP;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( D, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( YS, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( YSP, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 10, PDL_F, 2, N, 9 );
        curvs_( &N, ( float* )X->data, ( float* )Y->data, ( float* )D->data, &ISW, &S, &EPS, ( float* )YS->data, ( float* )YSP->data, &SIGMA, ( float* )TEMP->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( D );
        ncar_pdl_check_out( YS );
        ncar_pdl_check_out( YSP );
        ncar_pdl_check_out( TEMP );
      OUTPUT:
        IER


void
NCAR_FUNCTION_0048( NPNTS, X, Y, Z, NUMXOUT, NUMYOUT, XO, YO, ZO, IER )
      ALIAS:
        dsgrid2s   = FUNCTION_NAME_DSGRID2S
        natgrids   = FUNCTION_NAME_NATGRIDS
      PREINIT:
        typedef void (*ncar_function)( int*, float*, float*, float*, int*, int*, float*, float*, float*, int* );
      INPUT:
        int NPNTS;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int NUMXOUT;
        int NUMYOUT;
        pdl* XO;
        pdl* YO;
        pdl* ZO;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 3, PDL_F, 1,  NPNTS  );
        ncar_pdl_check_in( XO, GvNAME(CvGV(cv)), 6, PDL_F, 1,  NUMXOUT  );
        ncar_pdl_check_in( YO, GvNAME(CvGV(cv)), 7, PDL_F, 1,  NUMYOUT  );
        ncar_pdl_check_in( ZO, GvNAME(CvGV(cv)), 8, PDL_F, 2,  NUMXOUT,  NUMYOUT  );
        (*((ncar_function)ncar_functions[ix]))( &NPNTS, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &NUMXOUT, &NUMYOUT, ( float* )XO->data, ( float* )YO->data, ( float* )ZO->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( XO );
        ncar_pdl_check_out( YO );
        ncar_pdl_check_out( ZO );
      OUTPUT:
        IER


void
curvp1( N, X, Y, P, YP, TEMP, SIGMA, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        float P;
        pdl* YP;
        pdl* TEMP;
        float SIGMA;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 5, PDL_F, 0 );
        curvp1_( &N, ( float* )X->data, ( float* )Y->data, &P, ( float* )YP->data, ( float* )TEMP->data, &SIGMA, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( TEMP );
      OUTPUT:
        IER


void
curvps( N, X, Y, P, D, ISW, S, EPS, YS, YSP, SIGMA, TEMP, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        float P;
        pdl* D;
        int ISW;
        float S;
        float EPS;
        pdl* YS;
        pdl* YSP;
        float SIGMA;
        pdl* TEMP;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( D, GvNAME(CvGV(cv)), 4, PDL_F, 1, N );
        ncar_pdl_check_in( YS, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        ncar_pdl_check_in( YSP, GvNAME(CvGV(cv)), 9, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 11, PDL_F, 2, N, 11 );
        curvps_( &N, ( float* )X->data, ( float* )Y->data, &P, ( float* )D->data, &ISW, &S, &EPS, ( float* )YS->data, ( float* )YSP->data, &SIGMA, ( float* )TEMP->data, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( D );
        ncar_pdl_check_out( YS );
        ncar_pdl_check_out( YSP );
        ncar_pdl_check_out( TEMP );
      OUTPUT:
        IER


void
kurv1( N, X, Y, SLP1, SLPN, ISLPSW, XP, YP, TEMP, S, SIGMA, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        float SLP1;
        float SLPN;
        int ISLPSW;
        pdl* XP;
        pdl* YP;
        pdl* TEMP;
        pdl* S;
        float SIGMA;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( XP, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 8, PDL_F, 1, N );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 9, PDL_F, 1, N );
        kurv1_( &N, ( float* )X->data, ( float* )Y->data, &SLP1, &SLPN, &ISLPSW, ( float* )XP->data, ( float* )YP->data, ( float* )TEMP->data, ( float* )S->data, &SIGMA, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( XP );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( TEMP );
        ncar_pdl_check_out( S );
      OUTPUT:
        IER


void
curv1( N, X, Y, SLP1, SLPN, ISLPSW, YP, TEMP, SIGMA, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* X;
        pdl* Y;
        float SLP1;
        float SLPN;
        int ISLPSW;
        pdl* YP;
        pdl* TEMP;
        float SIGMA;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 1, PDL_F, 1, N );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 2, PDL_F, 1, N );
        ncar_pdl_check_in( YP, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        curv1_( &N, ( float* )X->data, ( float* )Y->data, &SLP1, &SLPN, &ISLPSW, ( float* )YP->data, ( float* )TEMP->data, &SIGMA, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( YP );
        ncar_pdl_check_out( TEMP );
      OUTPUT:
        IER


void
csstri( N, RLAT, RLON, NT, NTRI, IWK, RWK, IER )
      PREINIT:
      INPUT:
        int N;
        pdl* RLAT;
        pdl* RLON;
        int &NT;
        pdl* NTRI;
        pdl* IWK;
        pdl* RWK;
        int &IER;
      CODE:
        ncar_pdl_check_in( RLAT, GvNAME(CvGV(cv)), 1, PDL_F, 0 );
        ncar_pdl_check_in( RLON, GvNAME(CvGV(cv)), 2, PDL_F, 0 );
        ncar_pdl_check_in( NTRI, GvNAME(CvGV(cv)), 4, PDL_L, 0 );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        ncar_pdl_check_in( RWK, GvNAME(CvGV(cv)), 6, PDL_D, 0 );
        csstri_( &N, ( float* )RLAT->data, ( float* )RLON->data, &NT, ( int* )NTRI->data, ( int* )IWK->data, ( double* )RWK->data, &IER );
        ncar_pdl_check_out( RLAT );
        ncar_pdl_check_out( RLON );
        ncar_pdl_check_out( NTRI );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( RWK );
      OUTPUT:
        NT
        IER


void
NCAR_FUNCTION_0049( TNR, XMIN, XMAX, YMIN, YMAX )
      ALIAS:
        gsvp       =   FUNCTION_NAME_GSVP
        gswn       =   FUNCTION_NAME_GSWN
      PREINIT:
        typedef void (*ncar_function)( int*, float*, float*, float*, float* );
      INPUT:
        int TNR;
        float XMIN;
        float XMAX;
        float YMIN;
        float YMAX;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &TNR, &XMIN, &XMAX, &YMIN, &YMAX );


void
supmap( JPRJ, PLAT, PLON, ROTA, PLM1, PLM2, PLM3, PLM4, JLTS, JGRD, IOUT, IDOT, IERR )
      PREINIT:
      INPUT:
        int JPRJ;
        float PLAT;
        float PLON;
        float ROTA;
        pdl* PLM1;
        pdl* PLM2;
        pdl* PLM3;
        pdl* PLM4;
        int JLTS;
        int JGRD;
        int IOUT;
        int IDOT;
        int &IERR;
      CODE:
        ncar_pdl_check_in( PLM1, GvNAME(CvGV(cv)), 4, PDL_F, 1, 2 );
        ncar_pdl_check_in( PLM2, GvNAME(CvGV(cv)), 5, PDL_F, 1, 2 );
        ncar_pdl_check_in( PLM3, GvNAME(CvGV(cv)), 6, PDL_F, 1, 2 );
        ncar_pdl_check_in( PLM4, GvNAME(CvGV(cv)), 7, PDL_F, 1, 2 );
        supmap_( &JPRJ, &PLAT, &PLON, &ROTA, ( float* )PLM1->data, ( float* )PLM2->data, ( float* )PLM3->data, ( float* )PLM4->data, &JLTS, &JGRD, &IOUT, &IDOT, &IERR );
        ncar_pdl_check_out( PLM1 );
        ncar_pdl_check_out( PLM2 );
        ncar_pdl_check_out( PLM3 );
        ncar_pdl_check_out( PLM4 );
      OUTPUT:
        IERR


void
tdmtri( IMRK, UMRK, VMRK, WMRK, SMRK, RTRI, MTRI, NTRI, IRST, UMIN, VMIN, WMIN, UMAX, VMAX, WMAX )
      PREINIT:
      INPUT:
        int IMRK;
        float UMRK;
        float VMRK;
        float WMRK;
        float SMRK;
        pdl* RTRI;
        int MTRI;
        int &NTRI;
        int IRST;
        float UMIN;
        float VMIN;
        float WMIN;
        float UMAX;
        float VMAX;
        float WMAX;
      CODE:
        ncar_pdl_check_in( RTRI, GvNAME(CvGV(cv)), 5, PDL_F, 2, 10, MTRI );
        tdmtri_( &IMRK, &UMRK, &VMRK, &WMRK, &SMRK, ( float* )RTRI->data, &MTRI, &NTRI, &IRST, &UMIN, &VMIN, &WMIN, &UMAX, &VMAX, &WMAX );
        ncar_pdl_check_out( RTRI );
      OUTPUT:
        NTRI


void
lblbar( IHOV, XLEB, XREB, YBEB, YTEB, NBOX, WSFB, HSFB, LFIN, IFTP, LLBS, NLBS, LBAB )
      PREINIT:
        long LLBS_len;
      INPUT:
        int IHOV;
        float XLEB;
        float XREB;
        float YBEB;
        float YTEB;
        int NBOX;
        float WSFB;
        float HSFB;
        pdl* LFIN;
        int IFTP;
        string1D* LLBS;
        int NLBS;
        int LBAB;
      CODE:
        ncar_pdl_check_in( LFIN, GvNAME(CvGV(cv)), 8, PDL_L, 0 );
        lblbar_( &IHOV, &XLEB, &XREB, &YBEB, &YTEB, &NBOX, &WSFB, &HSFB, ( int* )LFIN->data, &IFTP, LLBS, &NLBS, &LBAB, LLBS_len );
        ncar_pdl_check_out( LFIN );


void
nglogo( IWK, X, Y, SIZE, ITYPE, ICOL1, ICOL2 )
      PREINIT:
      INPUT:
        int IWK;
        float X;
        float Y;
        float SIZE;
        int ITYPE;
        int ICOL1;
        int ICOL2;
      CODE:
        nglogo_( &IWK, &X, &Y, &SIZE, &ITYPE, &ICOL1, &ICOL2 );


void
gqtxx( WKID, PX, PY, STRX, ERRIND, CPX, CPY, TXEXPX, TXEXPY )
      PREINIT:
      INPUT:
        int WKID;
        float PX;
        float PY;
        char* STRX;
        int &ERRIND;
        float &CPX;
        float &CPY;
        pdl* TXEXPX;
        pdl* TXEXPY;
      CODE:
        ncar_pdl_check_in( TXEXPX, GvNAME(CvGV(cv)), 7, PDL_F, 1, 4 );
        ncar_pdl_check_in( TXEXPY, GvNAME(CvGV(cv)), 8, PDL_F, 1, 4 );
        gqtxx_( &WKID, &PX, &PY, STRX, &ERRIND, &CPX, &CPY, ( float* )TXEXPX->data, ( float* )TXEXPY->data, (long)strlen( STRX ) );
        ncar_pdl_check_out( TXEXPX );
        ncar_pdl_check_out( TXEXPY );
      OUTPUT:
        ERRIND
        CPX
        CPY


void
ngritd( IAXS, ANGL, UCRD, VCRD, WCRD )
      PREINIT:
      INPUT:
        int IAXS;
        float ANGL;
        float &UCRD;
        float &VCRD;
        float &WCRD;
      CODE:
        ngritd_( &IAXS, &ANGL, &UCRD, &VCRD, &WCRD );
      OUTPUT:
        UCRD
        VCRD
        WCRD


void
NCAR_FUNCTION_0050( LCOL, LCSF )
      ALIAS:
        mdrggc     = FUNCTION_NAME_MDRGGC
        mdrgsc     = FUNCTION_NAME_MDRGSC
        ticks      =  FUNCTION_NAME_TICKS
        ngpict     = FUNCTION_NAME_NGPICT
        gclrwk     = FUNCTION_NAME_GCLRWK
        gcsgwk     = FUNCTION_NAME_GCSGWK
        gopks      =  FUNCTION_NAME_GOPKS
        gstxal     = FUNCTION_NAME_GSTXAL
        gstxfp     = FUNCTION_NAME_GSTXFP
        guwk       =   FUNCTION_NAME_GUWK
      PREINIT:
        typedef void (*ncar_function)( int*, int* );
      INPUT:
        int LCOL;
        int LCSF;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &LCOL, &LCSF );


void
ngsrat( IOPT, IAT, RAT )
      PREINIT:
      INPUT:
        int IOPT;
        pdl* IAT;
        pdl* RAT;
      CODE:
        ncar_pdl_check_in( IAT, GvNAME(CvGV(cv)), 1, PDL_L, 1, 14 );
        ncar_pdl_check_in( RAT, GvNAME(CvGV(cv)), 2, PDL_F, 1, 7 );
        ngsrat_( &IOPT, ( int* )IAT->data, ( float* )RAT->data );
        ncar_pdl_check_out( IAT );
        ncar_pdl_check_out( RAT );


void
NCAR_FUNCTION_0051( I, J, ASPECT, IER )
      ALIAS:
        nngetaspectd = FUNCTION_NAME_NNGETASPECTD
        nngetsloped = FUNCTION_NAME_NNGETSLOPED
      PREINIT:
        typedef void (*ncar_function)( int*, int*, double*, int* );
      INPUT:
        int I;
        int J;
        double &ASPECT;
        int &IER;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &I, &J, &ASPECT, &IER );
      OUTPUT:
        ASPECT
        IER


void
tdez2d( NX, NY, X, Y, Z, RMULT, THETA, PHI, IST )
      PREINIT:
      INPUT:
        int NX;
        int NY;
        pdl* X;
        pdl* Y;
        pdl* Z;
        float RMULT;
        float THETA;
        float PHI;
        int IST;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 2, PDL_F, 1, NX );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 3, PDL_F, 1, NY );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 4, PDL_F, 2, NX, NY );
        tdez2d_( &NX, &NY, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &RMULT, &THETA, &PHI, &IST );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );


void
mssrf1( M, N, X, Y, Z, IZ, ZX1, ZXM, ZY1, ZYN, ZXY11, ZXYM1, ZXY1N, ZXYMN, ISLPSW, ZP, TEMP, SIGMA, IERR )
      PREINIT:
      INPUT:
        int M;
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int IZ;
        pdl* ZX1;
        pdl* ZXM;
        pdl* ZY1;
        pdl* ZYN;
        float ZXY11;
        float ZXYM1;
        float ZXY1N;
        float ZXYMN;
        int ISLPSW;
        float &ZP;
        float &TEMP;
        float SIGMA;
        int &IERR;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 2, PDL_F, 1, M );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 4, PDL_F, 2, IZ, N );
        ncar_pdl_check_in( ZX1, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( ZXM, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( ZY1, GvNAME(CvGV(cv)), 8, PDL_F, 1, M );
        ncar_pdl_check_in( ZYN, GvNAME(CvGV(cv)), 9, PDL_F, 1, M );
        mssrf1_( &M, &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &IZ, ( float* )ZX1->data, ( float* )ZXM->data, ( float* )ZY1->data, ( float* )ZYN->data, &ZXY11, &ZXYM1, &ZXY1N, &ZXYMN, &ISLPSW, &ZP, &TEMP, &SIGMA, &IERR );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( ZX1 );
        ncar_pdl_check_out( ZXM );
        ncar_pdl_check_out( ZY1 );
        ncar_pdl_check_out( ZYN );
      OUTPUT:
        ZP
        TEMP
        IERR


void
dandr( NV, NW, ST1, LX, NX, NY, IS2, IU, S, IOBJS, MV )
      PREINIT:
      INPUT:
        int NV;
        int NW;
        pdl* ST1;
        int LX;
        int NX;
        int NY;
        pdl* IS2;
        int IU;
        pdl* S;
        pdl* IOBJS;
        int MV;
      CODE:
        ncar_pdl_check_in( ST1, GvNAME(CvGV(cv)), 2, PDL_F, 3, NV, NW, 2 );
        ncar_pdl_check_in( IS2, GvNAME(CvGV(cv)), 6, PDL_L, 2, LX, NY );
        ncar_pdl_check_in( S, GvNAME(CvGV(cv)), 8, PDL_F, 1, 4 );
        ncar_pdl_check_in( IOBJS, GvNAME(CvGV(cv)), 9, PDL_L, 0 );
        dandr_( &NV, &NW, ( float* )ST1->data, &LX, &NX, &NY, ( int* )IS2->data, &IU, ( float* )S->data, ( int* )IOBJS->data, &MV );
        ncar_pdl_check_out( ST1 );
        ncar_pdl_check_out( IS2 );
        ncar_pdl_check_out( S );
        ncar_pdl_check_out( IOBJS );


void
idbvip( MD, NDP, XD, YD, ZD, NIP, XI, YI, ZI, IWK, WK )
      PREINIT:
      INPUT:
        int MD;
        int NDP;
        pdl* XD;
        pdl* YD;
        pdl* ZD;
        int NIP;
        pdl* XI;
        pdl* YI;
        pdl* ZI;
        pdl* IWK;
        pdl* WK;
      CODE:
        ncar_pdl_check_in( XD, GvNAME(CvGV(cv)), 2, PDL_F, 1, NDP );
        ncar_pdl_check_in( YD, GvNAME(CvGV(cv)), 3, PDL_F, 1, NDP );
        ncar_pdl_check_in( ZD, GvNAME(CvGV(cv)), 4, PDL_F, 1, NDP );
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 6, PDL_F, 1, NIP );
        ncar_pdl_check_in( YI, GvNAME(CvGV(cv)), 7, PDL_F, 1, NIP );
        ncar_pdl_check_in( ZI, GvNAME(CvGV(cv)), 8, PDL_F, 1, NIP );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 9, PDL_L, 0 );
        ncar_pdl_check_in( WK, GvNAME(CvGV(cv)), 10, PDL_F, 0 );
        idbvip_( &MD, &NDP, ( float* )XD->data, ( float* )YD->data, ( float* )ZD->data, &NIP, ( float* )XI->data, ( float* )YI->data, ( float* )ZI->data, ( int* )IWK->data, ( float* )WK->data );
        ncar_pdl_check_out( XD );
        ncar_pdl_check_out( YD );
        ncar_pdl_check_out( ZD );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( YI );
        ncar_pdl_check_out( ZI );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( WK );


void
idsfft( MD, NDP, XD, YD, ZD, NXI, NYI, NZI, XI, YI, ZI, IWK, WK )
      PREINIT:
      INPUT:
        int MD;
        int NDP;
        pdl* XD;
        pdl* YD;
        pdl* ZD;
        int NXI;
        int NYI;
        int NZI;
        pdl* XI;
        pdl* YI;
        pdl* ZI;
        pdl* IWK;
        pdl* WK;
      CODE:
        ncar_pdl_check_in( XD, GvNAME(CvGV(cv)), 2, PDL_F, 1, NDP );
        ncar_pdl_check_in( YD, GvNAME(CvGV(cv)), 3, PDL_F, 1, NDP );
        ncar_pdl_check_in( ZD, GvNAME(CvGV(cv)), 4, PDL_F, 1, NDP );
        ncar_pdl_check_in( XI, GvNAME(CvGV(cv)), 8, PDL_F, 1, NXI );
        ncar_pdl_check_in( YI, GvNAME(CvGV(cv)), 9, PDL_F, 1, NYI );
        ncar_pdl_check_in( ZI, GvNAME(CvGV(cv)), 10, PDL_F, 2, NZI, NYI );
        ncar_pdl_check_in( IWK, GvNAME(CvGV(cv)), 11, PDL_L, 0 );
        ncar_pdl_check_in( WK, GvNAME(CvGV(cv)), 12, PDL_F, 0 );
        idsfft_( &MD, &NDP, ( float* )XD->data, ( float* )YD->data, ( float* )ZD->data, &NXI, &NYI, &NZI, ( float* )XI->data, ( float* )YI->data, ( float* )ZI->data, ( int* )IWK->data, ( float* )WK->data );
        ncar_pdl_check_out( XD );
        ncar_pdl_check_out( YD );
        ncar_pdl_check_out( ZD );
        ncar_pdl_check_out( XI );
        ncar_pdl_check_out( YI );
        ncar_pdl_check_out( ZI );
        ncar_pdl_check_out( IWK );
        ncar_pdl_check_out( WK );


void
surf1( M, N, X, Y, Z, IZ, ZX1, ZXM, ZY1, ZYN, ZXY11, ZXYM1, ZXY1N, ZXYMN, ISLPSW, ZP, TEMP, SIGMA, IER )
      PREINIT:
      INPUT:
        int M;
        int N;
        pdl* X;
        pdl* Y;
        pdl* Z;
        int IZ;
        pdl* ZX1;
        pdl* ZXM;
        pdl* ZY1;
        pdl* ZYN;
        float ZXY11;
        float ZXYM1;
        float ZXY1N;
        float ZXYMN;
        int ISLPSW;
        pdl* ZP;
        pdl* TEMP;
        float SIGMA;
        int &IER;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 2, PDL_F, 1, M );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 3, PDL_F, 1, N );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 4, PDL_F, 2, IZ, N );
        ncar_pdl_check_in( ZX1, GvNAME(CvGV(cv)), 6, PDL_F, 1, N );
        ncar_pdl_check_in( ZXM, GvNAME(CvGV(cv)), 7, PDL_F, 1, N );
        ncar_pdl_check_in( ZY1, GvNAME(CvGV(cv)), 8, PDL_F, 1, M );
        ncar_pdl_check_in( ZYN, GvNAME(CvGV(cv)), 9, PDL_F, 1, M );
        ncar_pdl_check_in( ZP, GvNAME(CvGV(cv)), 15, PDL_F, 3, M, N, 3 );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 16, PDL_F, 0 );
        surf1_( &M, &N, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, &IZ, ( float* )ZX1->data, ( float* )ZXM->data, ( float* )ZY1->data, ( float* )ZYN->data, &ZXY11, &ZXYM1, &ZXY1N, &ZXYMN, &ISLPSW, ( float* )ZP->data, ( float* )TEMP->data, &SIGMA, &IER );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( ZX1 );
        ncar_pdl_check_out( ZXM );
        ncar_pdl_check_out( ZY1 );
        ncar_pdl_check_out( ZYN );
        ncar_pdl_check_out( ZP );
        ncar_pdl_check_out( TEMP );
      OUTPUT:
        IER


void
gscr( WKID, CI, CR, CG, CB )
      PREINIT:
      INPUT:
        int WKID;
        int CI;
        float CR;
        float CG;
        float CB;
      CODE:
        gscr_( &WKID, &CI, &CR, &CG, &CB );


void
msbsf1( M, N, XMIN, XMAX, YMIN, YMAX, Z, IZ, ZP, TEMP, SIGMA )
      PREINIT:
      INPUT:
        int M;
        int N;
        float XMIN;
        float XMAX;
        float YMIN;
        float YMAX;
        pdl* Z;
        int IZ;
        pdl* ZP;
        pdl* TEMP;
        float SIGMA;
      CODE:
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 6, PDL_F, 2, IZ, N );
        ncar_pdl_check_in( ZP, GvNAME(CvGV(cv)), 8, PDL_F, 3, M, N, 3 );
        ncar_pdl_check_in( TEMP, GvNAME(CvGV(cv)), 9, PDL_F, 0 );
        msbsf1_( &M, &N, &XMIN, &XMAX, &YMIN, &YMAX, ( float* )Z->data, &IZ, ( float* )ZP->data, ( float* )TEMP->data, &SIGMA );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( ZP );
        ncar_pdl_check_out( TEMP );


void
tdclrs( IWID, IBOW, SHDE, SHDR, IOFC, IOLC, ILMT )
      PREINIT:
      INPUT:
        int IWID;
        int IBOW;
        float SHDE;
        float SHDR;
        int IOFC;
        int IOLC;
        int ILMT;
      CODE:
        tdclrs_( &IWID, &IBOW, &SHDE, &SHDR, &IOFC, &IOLC, &ILMT );


void
NCAR_FUNCTION_0052( I, J, ASPECT, IER )
      ALIAS:
        nngetaspects = FUNCTION_NAME_NNGETASPECTS
        nngetslopes = FUNCTION_NAME_NNGETSLOPES
      PREINIT:
        typedef void (*ncar_function)( int*, int*, float*, int* );
      INPUT:
        int I;
        int J;
        float &ASPECT;
        int &IER;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &I, &J, &ASPECT, &IER );
      OUTPUT:
        ASPECT
        IER


void
NCAR_FUNCTION_0053( LFRA, LROW, LTYP )
      ALIAS:
        displa     = FUNCTION_NAME_DISPLA
        plotit     = FUNCTION_NAME_PLOTIT
        gopwk      =  FUNCTION_NAME_GOPWK
      PREINIT:
        typedef void (*ncar_function)( int*, int*, int* );
      INPUT:
        int LFRA;
        int LROW;
        int LTYP;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &LFRA, &LROW, &LTYP );


void
NCAR_FUNCTION_0054( IPRJ, IZON, ISPH, PARA, UMIN, UMAX, VMIN, VMAX )
      ALIAS:
        mdutin     = FUNCTION_NAME_MDUTIN
        mputin     = FUNCTION_NAME_MPUTIN
      PREINIT:
        typedef void (*ncar_function)( int*, int*, int*, double*, double*, double*, double*, double* );
      INPUT:
        int IPRJ;
        int IZON;
        int ISPH;
        double &PARA;
        double UMIN;
        double UMAX;
        double VMIN;
        double VMAX;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &IPRJ, &IZON, &ISPH, &PARA, &UMIN, &UMAX, &VMIN, &VMAX );
      OUTPUT:
        PARA


void
tdez3d( NX, NY, NZ, X, Y, Z, U, VALUE, RMULT, THETA, PHI, IST )
      PREINIT:
      INPUT:
        int NX;
        int NY;
        int NZ;
        pdl* X;
        pdl* Y;
        pdl* Z;
        pdl* U;
        float VALUE;
        float RMULT;
        float THETA;
        float PHI;
        int IST;
      CODE:
        ncar_pdl_check_in( X, GvNAME(CvGV(cv)), 3, PDL_F, 1, NX );
        ncar_pdl_check_in( Y, GvNAME(CvGV(cv)), 4, PDL_F, 1, NY );
        ncar_pdl_check_in( Z, GvNAME(CvGV(cv)), 5, PDL_F, 1, NZ );
        ncar_pdl_check_in( U, GvNAME(CvGV(cv)), 6, PDL_F, 3, NX, NY, NZ );
        tdez3d_( &NX, &NY, &NZ, ( float* )X->data, ( float* )Y->data, ( float* )Z->data, ( float* )U->data, &VALUE, &RMULT, &THETA, &PHI, &IST );
        ncar_pdl_check_out( X );
        ncar_pdl_check_out( Y );
        ncar_pdl_check_out( Z );
        ncar_pdl_check_out( U );


void
NCAR_FUNCTION_0055( KAXS, KLBL, KMJT, KMNT )
      ALIAS:
        gacolr     = FUNCTION_NAME_GACOLR
        grid       =   FUNCTION_NAME_GRID
        gridl      =  FUNCTION_NAME_GRIDL
        perim      =  FUNCTION_NAME_PERIM
        periml     = FUNCTION_NAME_PERIML
        tick4      =  FUNCTION_NAME_TICK4
      PREINIT:
        typedef void (*ncar_function)( int*, int*, int*, int* );
      INPUT:
        int KAXS;
        int KLBL;
        int KMJT;
        int KMNT;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &KAXS, &KLBL, &KMJT, &KMNT );


void
halfax( MJRX, MNRX, MJRY, MNRY, XINT, YINT, IXLB, IYLB )
      PREINIT:
      INPUT:
        int MJRX;
        int MNRX;
        int MJRY;
        int MNRY;
        float XINT;
        float YINT;
        int IXLB;
        int IYLB;
      CODE:
        halfax_( &MJRX, &MNRX, &MJRY, &MNRY, &XINT, &YINT, &IXLB, &IYLB );


void
perim3( MAGR1, MINI1, MAGR2, MINI2, IWHICH, VAR )
      PREINIT:
      INPUT:
        int MAGR1;
        int MINI1;
        int MAGR2;
        int MINI2;
        int IWHICH;
        float VAR;
      CODE:
        perim3_( &MAGR1, &MINI1, &MAGR2, &MINI2, &IWHICH, &VAR );


void
tick43( MAGU, MINU, MAGV, MINV, MAGW, MINW )
      PREINIT:
      INPUT:
        int MAGU;
        int MINU;
        int MAGV;
        int MINV;
        int MAGW;
        int MINW;
      CODE:
        tick43_( &MAGU, &MINU, &MAGV, &MINV, &MAGW, &MINW );


void
gridal( MJRX, MNRX, MJRY, MNRY, IXLB, IYLB, IGPH, XINT, YINT )
      PREINIT:
      INPUT:
        int MJRX;
        int MNRX;
        int MJRY;
        int MNRY;
        int IXLB;
        int IYLB;
        int IGPH;
        float XINT;
        float YINT;
      CODE:
        gridal_( &MJRX, &MNRX, &MJRY, &MNRY, &IXLB, &IYLB, &IGPH, &XINT, &YINT );


void
tdstrs( IRST, IFC1, IFC2, IFC3, IFC4, ILC1, ILC2, ILTD, USTP, VSTP, WSTP )
      PREINIT:
      INPUT:
        int IRST;
        int IFC1;
        int IFC2;
        int IFC3;
        int IFC4;
        int ILC1;
        int ILC2;
        int ILTD;
        float USTP;
        float VSTP;
        float WSTP;
      CODE:
        tdstrs_( &IRST, &IFC1, &IFC2, &IFC3, &IFC4, &ILC1, &ILC2, &ILTD, &USTP, &VSTP, &WSTP );


void
gqcr( WKID, COLI, TYPE, ERRIND, RED, GREEN, BLUE )
      PREINIT:
      INPUT:
        int WKID;
        int COLI;
        int TYPE;
        int &ERRIND;
        float &RED;
        float &GREEN;
        float &BLUE;
      CODE:
        gqcr_( &WKID, &COLI, &TYPE, &ERRIND, &RED, &GREEN, &BLUE );
      OUTPUT:
        ERRIND
        RED
        GREEN
        BLUE


void
ngreop( WKID, CONID, ITYPE, FNAME, IOPT, IAT, RAT, NCOLRS, NSTART, CTAB )
      PREINIT:
      INPUT:
        int WKID;
        int CONID;
        int ITYPE;
        char* FNAME;
        int IOPT;
        pdl* IAT;
        pdl* RAT;
        int NCOLRS;
        int NSTART;
        pdl* CTAB;
      CODE:
        ncar_pdl_check_in( IAT, GvNAME(CvGV(cv)), 5, PDL_L, 0 );
        ncar_pdl_check_in( RAT, GvNAME(CvGV(cv)), 6, PDL_F, 0 );
        ncar_pdl_check_in( CTAB, GvNAME(CvGV(cv)), 9, PDL_F, 0 );
        ngreop_( &WKID, &CONID, &ITYPE, FNAME, &IOPT, ( int* )IAT->data, ( float* )RAT->data, &NCOLRS, &NSTART, ( float* )CTAB->data, (long)strlen( FNAME ) );
        ncar_pdl_check_out( IAT );
        ncar_pdl_check_out( RAT );
        ncar_pdl_check_out( CTAB );


void
gesc( FCTID, LIDR, IDR, MLODR, LODR, ODR )
      PREINIT:
        long IDR_len;
        long ODR_len;
      INPUT:
        int FCTID;
        int LIDR;
        string1D* IDR;
        int MLODR;
        int LODR;
        string1D* ODR;
      CODE:
        gesc_( &FCTID, &LIDR, IDR, &MLODR, &LODR, ODR, IDR_len, ODR_len );


void
gqnt( NTNR, ERRIND, WINDOW, VIEWPT )
      PREINIT:
      INPUT:
        int NTNR;
        int &ERRIND;
        pdl* WINDOW;
        pdl* VIEWPT;
      CODE:
        ncar_pdl_check_in( WINDOW, GvNAME(CvGV(cv)), 2, PDL_F, 1, 4 );
        ncar_pdl_check_in( VIEWPT, GvNAME(CvGV(cv)), 3, PDL_F, 1, 4 );
        gqnt_( &NTNR, &ERRIND, ( float* )WINDOW->data, ( float* )VIEWPT->data );
        ncar_pdl_check_out( WINDOW );
        ncar_pdl_check_out( VIEWPT );
      OUTPUT:
        ERRIND


void
gqsgus( N, ERRIND, OL, SGNA )
      PREINIT:
      INPUT:
        int N;
        int &ERRIND;
        int &OL;
        int &SGNA;
      CODE:
        gqsgus_( &N, &ERRIND, &OL, &SGNA );
      OUTPUT:
        ERRIND
        OL
        SGNA


void
tdgtrs( IRST, IFC1, IFC2, IFC3, IFC4, ILC1, ILC2, ILTD, USTP, VSTP, WSTP )
      PREINIT:
      INPUT:
        int IRST;
        int &IFC1;
        int &IFC2;
        int &IFC3;
        int &IFC4;
        int &ILC1;
        int &ILC2;
        int &ILTD;
        float &USTP;
        float &VSTP;
        float &WSTP;
      CODE:
        tdgtrs_( &IRST, &IFC1, &IFC2, &IFC3, &IFC4, &ILC1, &ILC2, &ILTD, &USTP, &VSTP, &WSTP );
      OUTPUT:
        IFC1
        IFC2
        IFC3
        IFC4
        ILC1
        ILC2
        ILTD
        USTP
        VSTP
        WSTP


void
gflas4( ID, FNAME )
      PREINIT:
      INPUT:
        int ID;
        char* FNAME;
      CODE:
        gflas4_( &ID, FNAME, (long)strlen( FNAME ) );


void
tdlbla( IAXS, ILBL, NLBL, XAT0, XAT1, YAT0, YAT1, ANGD )
      PREINIT:
      INPUT:
        int IAXS;
        char* ILBL;
        char* NLBL;
        float XAT0;
        float XAT1;
        float YAT0;
        float YAT1;
        float ANGD;
      CODE:
        tdlbla_( &IAXS, ILBL, NLBL, &XAT0, &XAT1, &YAT0, &YAT1, &ANGD, (long)strlen( ILBL ), (long)strlen( NLBL ) );


void
NCAR_FUNCTION_0056( ILTY )
      ALIAS:
        mdglty     = FUNCTION_NAME_MDGLTY
        mdrgdl     = FUNCTION_NAME_MDRGDL
        mpglty     = FUNCTION_NAME_MPGLTY
        gqops      =  FUNCTION_NAME_GQOPS
      PREINIT:
        typedef void (*ncar_function)( int* );
      INPUT:
        int &ILTY;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &ILTY );
      OUTPUT:
        ILTY


void
NCAR_FUNCTION_0057( ERRIND, CHH )
      ALIAS:
        gqchh      =  FUNCTION_NAME_GQCHH
        gqchsp     = FUNCTION_NAME_GQCHSP
        gqchxp     = FUNCTION_NAME_GQCHXP
        gqlwsc     = FUNCTION_NAME_GQLWSC
        gqmksc     = FUNCTION_NAME_GQMKSC
      PREINIT:
        typedef void (*ncar_function)( int*, float* );
      INPUT:
        int &ERRIND;
        float &CHH;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &ERRIND, &CHH );
      OUTPUT:
        ERRIND
        CHH


void
gqchup( ERRIND, CHUX, CHUY )
      PREINIT:
      INPUT:
        int &ERRIND;
        float &CHUX;
        float &CHUY;
      CODE:
        gqchup_( &ERRIND, &CHUX, &CHUY );
      OUTPUT:
        ERRIND
        CHUX
        CHUY


void
entsr( IROLD, IRNEW )
      PREINIT:
      INPUT:
        int &IROLD;
        int IRNEW;
      CODE:
        entsr_( &IROLD, &IRNEW );
      OUTPUT:
        IROLD


void
gqasf( ERRIND, LASF )
      PREINIT:
      INPUT:
        int &ERRIND;
        pdl* LASF;
      CODE:
        ncar_pdl_check_in( LASF, GvNAME(CvGV(cv)), 1, PDL_L, 1, 13 );
        gqasf_( &ERRIND, ( int* )LASF->data );
        ncar_pdl_check_out( LASF );
      OUTPUT:
        ERRIND


void
NCAR_FUNCTION_0058( IX, IY )
      ALIAS:
        getsi      =  FUNCTION_NAME_GETSI
        gqcntn     = FUNCTION_NAME_GQCNTN
        gqfaci     = FUNCTION_NAME_GQFACI
        gqfais     = FUNCTION_NAME_GQFAIS
        gqfasi     = FUNCTION_NAME_GQFASI
        gqln       =   FUNCTION_NAME_GQLN
        gqmk       =   FUNCTION_NAME_GQMK
        gqmntn     = FUNCTION_NAME_GQMNTN
        gqopsg     = FUNCTION_NAME_GQOPSG
        gqplci     = FUNCTION_NAME_GQPLCI
        gqpmci     = FUNCTION_NAME_GQPMCI
        gqtxci     = FUNCTION_NAME_GQTXCI
        gqtxp      =  FUNCTION_NAME_GQTXP
      PREINIT:
        typedef void (*ncar_function)( int*, int* );
      INPUT:
        int &IX;
        int &IY;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &IX, &IY );
      OUTPUT:
        IX
        IY


void
gqclip( ERRIND, CLSW, CLRECT )
      PREINIT:
      INPUT:
        int &ERRIND;
        int &CLSW;
        pdl* CLRECT;
      CODE:
        ncar_pdl_check_in( CLRECT, GvNAME(CvGV(cv)), 2, PDL_F, 1, 4 );
        gqclip_( &ERRIND, &CLSW, ( float* )CLRECT->data );
        ncar_pdl_check_out( CLRECT );
      OUTPUT:
        ERRIND
        CLSW


void
NCAR_FUNCTION_0059( ERRIND, TXALH, TXALV )
      ALIAS:
        gqtxal     = FUNCTION_NAME_GQTXAL
        gqtxfp     = FUNCTION_NAME_GQTXFP
      PREINIT:
        typedef void (*ncar_function)( int*, int*, int* );
      INPUT:
        int &ERRIND;
        int &TXALH;
        int &TXALV;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( &ERRIND, &TXALH, &TXALV );
      OUTPUT:
        ERRIND
        TXALH
        TXALV


void
stitle( CRDS, NCDS, IYST, IYND, TMST, TMMV, TMND, MTST )
      PREINIT:
        long CRDS_len;
      INPUT:
        string1D* CRDS;
        int NCDS;
        int IYST;
        int IYND;
        float TMST;
        float TMMV;
        float TMND;
        int MTST;
      CODE:
        stitle_( CRDS, &NCDS, &IYST, &IYND, &TMST, &TMMV, &TMND, &MTST, CRDS_len );


void
NCAR_FUNCTION_0060( FLNM )
      ALIAS:
        mdlnri     = FUNCTION_NAME_MDLNRI
        mplnri     = FUNCTION_NAME_MPLNRI
        hstopl     = FUNCTION_NAME_HSTOPL
        conop1     = FUNCTION_NAME_CONOP1
      PREINIT:
        typedef void (*ncar_function)( char*, long );
      INPUT:
        char* FLNM;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( FLNM, (long)strlen( FLNM ) );


void
NCAR_FUNCTION_0061( WHCH, DVAL )
      ALIAS:
        mapstd     = FUNCTION_NAME_MAPSTD
        mdsetd     = FUNCTION_NAME_MDSETD
        mpsetd     = FUNCTION_NAME_MPSETD
        cssetd     = FUNCTION_NAME_CSSETD
        dssetrd    = FUNCTION_NAME_DSSETRD
        nnsetrd    = FUNCTION_NAME_NNSETRD
      PREINIT:
        typedef void (*ncar_function)( char*, double*, long );
      INPUT:
        char* WHCH;
        double DVAL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( WHCH, &DVAL, (long)strlen( WHCH ) );


void
mdproj( ARG1, ARG2, ARG3, ARG4 )
      PREINIT:
      INPUT:
        char* ARG1;
        double ARG2;
        double ARG3;
        double ARG4;
      CODE:
        mdproj_( ARG1, &ARG2, &ARG3, &ARG4, (long)strlen( ARG1 ) );


void
NCAR_FUNCTION_0062( WHCH, DVAL )
      ALIAS:
        mapgtd     = FUNCTION_NAME_MAPGTD
        mdgetd     = FUNCTION_NAME_MDGETD
        mpgetd     = FUNCTION_NAME_MPGETD
        csgetd     = FUNCTION_NAME_CSGETD
        dsgetrd    = FUNCTION_NAME_DSGETRD
        nngetrd    = FUNCTION_NAME_NNGETRD
      PREINIT:
        typedef void (*ncar_function)( char*, double*, long );
      INPUT:
        char* WHCH;
        double &DVAL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( WHCH, &DVAL, (long)strlen( WHCH ) );
      OUTPUT:
        DVAL


void
mdpset( ARG1, ARG2, ARG3, ARG4, ARG5 )
      PREINIT:
      INPUT:
        char* ARG1;
        double &ARG2;
        double &ARG3;
        double &ARG4;
        double &ARG5;
      CODE:
        mdpset_( ARG1, &ARG2, &ARG3, &ARG4, &ARG5, (long)strlen( ARG1 ) );
      OUTPUT:
        ARG2
        ARG3
        ARG4
        ARG5


void
NCAR_FUNCTION_0063( IPN, RVL )
      ALIAS:
        arsetr     = FUNCTION_NAME_ARSETR
        agsetf     = FUNCTION_NAME_AGSETF
        agsetr     = FUNCTION_NAME_AGSETR
        cpsetr     = FUNCTION_NAME_CPSETR
        dpsetr     = FUNCTION_NAME_DPSETR
        mapstr     = FUNCTION_NAME_MAPSTR
        mdsetr     = FUNCTION_NAME_MDSETR
        mpsetr     = FUNCTION_NAME_MPSETR
        gasetr     = FUNCTION_NAME_GASETR
        issetr     = FUNCTION_NAME_ISSETR
        lbsetr     = FUNCTION_NAME_LBSETR
        ngsetr     = FUNCTION_NAME_NGSETR
        pcsetr     = FUNCTION_NAME_PCSETR
        sfsetr     = FUNCTION_NAME_SFSETR
        slsetr     = FUNCTION_NAME_SLSETR
        stsetr     = FUNCTION_NAME_STSETR
        tdsetr     = FUNCTION_NAME_TDSETR
        vvsetr     = FUNCTION_NAME_VVSETR
        wmsetr     = FUNCTION_NAME_WMSETR
        cssetr     = FUNCTION_NAME_CSSETR
        dssetr     = FUNCTION_NAME_DSSETR
        nnsetr     = FUNCTION_NAME_NNSETR
      PREINIT:
        typedef void (*ncar_function)( char*, float*, long );
      INPUT:
        char* IPN;
        float RVL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( IPN, &RVL, (long)strlen( IPN ) );


void
mapset( ARG1, ARG2, ARG3, ARG4, ARG5 )
      PREINIT:
      INPUT:
        char* ARG1;
        pdl* ARG2;
        pdl* ARG3;
        pdl* ARG4;
        pdl* ARG5;
      CODE:
        ncar_pdl_check_in( ARG2, GvNAME(CvGV(cv)), 1, PDL_F, 1, 2 );
        ncar_pdl_check_in( ARG3, GvNAME(CvGV(cv)), 2, PDL_F, 1, 2 );
        ncar_pdl_check_in( ARG4, GvNAME(CvGV(cv)), 3, PDL_F, 1, 2 );
        ncar_pdl_check_in( ARG5, GvNAME(CvGV(cv)), 4, PDL_F, 1, 2 );
        mapset_( ARG1, ( float* )ARG2->data, ( float* )ARG3->data, ( float* )ARG4->data, ( float* )ARG5->data, (long)strlen( ARG1 ) );
        ncar_pdl_check_out( ARG2 );
        ncar_pdl_check_out( ARG3 );
        ncar_pdl_check_out( ARG4 );
        ncar_pdl_check_out( ARG5 );


void
NCAR_FUNCTION_0064( TPID, FURA, LURA )
      ALIAS:
        aggetp     = FUNCTION_NAME_AGGETP
        agsetp     = FUNCTION_NAME_AGSETP
        hstopr     = FUNCTION_NAME_HSTOPR
      PREINIT:
        typedef void (*ncar_function)( char*, float*, int*, long );
      INPUT:
        char* TPID;
        pdl* FURA;
        int LURA;
      CODE:
        ncar_pdl_check_in( FURA, GvNAME(CvGV(cv)), 1, PDL_F, 1, LURA );
        (*((ncar_function)ncar_functions[ix]))( TPID, ( float* )FURA->data, &LURA, (long)strlen( TPID ) );
        ncar_pdl_check_out( FURA );


void
maproj( ARG1, ARG2, ARG3, ARG4 )
      PREINIT:
      INPUT:
        char* ARG1;
        float ARG2;
        float ARG3;
        float ARG4;
      CODE:
        maproj_( ARG1, &ARG2, &ARG3, &ARG4, (long)strlen( ARG1 ) );


void
NCAR_FUNCTION_0065( IPN, RVL )
      ALIAS:
        argetr     = FUNCTION_NAME_ARGETR
        aggetf     = FUNCTION_NAME_AGGETF
        aggetr     = FUNCTION_NAME_AGGETR
        cpgetr     = FUNCTION_NAME_CPGETR
        dpgetr     = FUNCTION_NAME_DPGETR
        mapgtr     = FUNCTION_NAME_MAPGTR
        mdgetr     = FUNCTION_NAME_MDGETR
        mpgetr     = FUNCTION_NAME_MPGETR
        gagetr     = FUNCTION_NAME_GAGETR
        isgetr     = FUNCTION_NAME_ISGETR
        lbgetr     = FUNCTION_NAME_LBGETR
        nggetr     = FUNCTION_NAME_NGGETR
        pcgetr     = FUNCTION_NAME_PCGETR
        sfgetr     = FUNCTION_NAME_SFGETR
        slgetr     = FUNCTION_NAME_SLGETR
        stgetr     = FUNCTION_NAME_STGETR
        tdgetr     = FUNCTION_NAME_TDGETR
        vvgetr     = FUNCTION_NAME_VVGETR
        wmgetr     = FUNCTION_NAME_WMGETR
        csgetr     = FUNCTION_NAME_CSGETR
        dsgetr     = FUNCTION_NAME_DSGETR
        nngetr     = FUNCTION_NAME_NNGETR
      PREINIT:
        typedef void (*ncar_function)( char*, float*, long );
      INPUT:
        char* IPN;
        float &RVL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( IPN, &RVL, (long)strlen( IPN ) );
      OUTPUT:
        RVL


void
NCAR_FUNCTION_0066( IPN, IVL )
      ALIAS:
        arseti     = FUNCTION_NAME_ARSETI
        agseti     = FUNCTION_NAME_AGSETI
        cpseti     = FUNCTION_NAME_CPSETI
        dpseti     = FUNCTION_NAME_DPSETI
        mapsti     = FUNCTION_NAME_MAPSTI
        mapstl     = FUNCTION_NAME_MAPSTL
        mdlndr     = FUNCTION_NAME_MDLNDR
        mdseti     = FUNCTION_NAME_MDSETI
        mdsetl     = FUNCTION_NAME_MDSETL
        mplndr     = FUNCTION_NAME_MPLNDR
        mpseti     = FUNCTION_NAME_MPSETI
        mpsetl     = FUNCTION_NAME_MPSETL
        gaseti     = FUNCTION_NAME_GASETI
        isseti     = FUNCTION_NAME_ISSETI
        lbseti     = FUNCTION_NAME_LBSETI
        ngseti     = FUNCTION_NAME_NGSETI
        pcseti     = FUNCTION_NAME_PCSETI
        sfseti     = FUNCTION_NAME_SFSETI
        setusv     = FUNCTION_NAME_SETUSV
        slseti     = FUNCTION_NAME_SLSETI
        stseti     = FUNCTION_NAME_STSETI
        tdseti     = FUNCTION_NAME_TDSETI
        vvseti     = FUNCTION_NAME_VVSETI
        wmseti     = FUNCTION_NAME_WMSETI
        csgeti     = FUNCTION_NAME_CSGETI
        csseti     = FUNCTION_NAME_CSSETI
        dsgeti     = FUNCTION_NAME_DSGETI
        nngeti     = FUNCTION_NAME_NNGETI
        nnseti     = FUNCTION_NAME_NNSETI
      PREINIT:
        typedef void (*ncar_function)( char*, int*, long );
      INPUT:
        char* IPN;
        int IVL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( IPN, &IVL, (long)strlen( IPN ) );


void
ngwsym( FTYPE, NUM, X, Y, SIZE, ICOLOR, IALT )
      PREINIT:
      INPUT:
        char* FTYPE;
        int NUM;
        float X;
        float Y;
        float SIZE;
        int ICOLOR;
        int IALT;
      CODE:
        ngwsym_( FTYPE, &NUM, &X, &Y, &SIZE, &ICOLOR, &IALT, (long)strlen( FTYPE ) );


void
NCAR_FUNCTION_0067( IPAT, JCRT, JSIZE )
      ALIAS:
        dashdc     = FUNCTION_NAME_DASHDC
        seter      =  FUNCTION_NAME_SETER
      PREINIT:
        typedef void (*ncar_function)( char*, int*, int*, long );
      INPUT:
        char* IPAT;
        int JCRT;
        int JSIZE;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( IPAT, &JCRT, &JSIZE, (long)strlen( IPAT ) );


void
NCAR_FUNCTION_0068( FLNM, ILVL, IAMA )
      ALIAS:
        mdlnam     = FUNCTION_NAME_MDLNAM
        mplnam     = FUNCTION_NAME_MPLNAM
      PREINIT:
        typedef void (*ncar_function)( char*, int*, int*, long );
      INPUT:
        char* FLNM;
        int ILVL;
        pdl* IAMA;
      CODE:
        ncar_pdl_check_in( IAMA, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        (*((ncar_function)ncar_functions[ix]))( FLNM, &ILVL, ( int* )IAMA->data, (long)strlen( FLNM ) );
        ncar_pdl_check_out( IAMA );


void
mplndm( FLNM, ILVL, IAMA, XCRA, YCRA, MCRA, IAAI, IAGI, MNOG, LPR_ )
      PREINIT:
      INPUT:
        char* FLNM;
        int ILVL;
        pdl* IAMA;
        pdl* XCRA;
        pdl* YCRA;
        int MCRA;
        pdl* IAAI;
        pdl* IAGI;
        int MNOG;
        SV* LPR_;
      CODE:
        ncar_pdl_check_in( IAMA, GvNAME(CvGV(cv)), 2, PDL_L, 0 );
        ncar_pdl_check_in( XCRA, GvNAME(CvGV(cv)), 3, PDL_F, 1, MCRA );
        ncar_pdl_check_in( YCRA, GvNAME(CvGV(cv)), 4, PDL_F, 1, MCRA );
        ncar_pdl_check_in( IAAI, GvNAME(CvGV(cv)), 6, PDL_L, 1, MNOG );
        ncar_pdl_check_in( IAGI, GvNAME(CvGV(cv)), 7, PDL_L, 1, MNOG );
        perl_ncar_callback = LPR_;
        mplndm_( FLNM, &ILVL, ( int* )IAMA->data, ( float* )XCRA->data, ( float* )YCRA->data, &MCRA, ( int* )IAAI->data, ( int* )IAGI->data, &MNOG, &c_ncar_callback_LPR, (long)strlen( FLNM ) );
        ncar_pdl_check_out( IAMA );
        ncar_pdl_check_out( XCRA );
        ncar_pdl_check_out( YCRA );
        ncar_pdl_check_out( IAAI );
        ncar_pdl_check_out( IAGI );
        perl_ncar_callback = ( SV* )0;


void
hstopi( STRING, PARAM1, PARAM2, ICOL, LCOL )
      PREINIT:
      INPUT:
        char* STRING;
        int PARAM1;
        int PARAM2;
        pdl* ICOL;
        int LCOL;
      CODE:
        ncar_pdl_check_in( ICOL, GvNAME(CvGV(cv)), 3, PDL_L, 1, LCOL );
        hstopi_( STRING, &PARAM1, &PARAM2, ( int* )ICOL->data, &LCOL, (long)strlen( STRING ) );
        ncar_pdl_check_out( ICOL );


void
NCAR_FUNCTION_0069( IPN, IVL )
      ALIAS:
        argeti     = FUNCTION_NAME_ARGETI
        aggeti     = FUNCTION_NAME_AGGETI
        cpgeti     = FUNCTION_NAME_CPGETI
        dpgeti     = FUNCTION_NAME_DPGETI
        mapgti     = FUNCTION_NAME_MAPGTI
        mapgtl     = FUNCTION_NAME_MAPGTL
        mdgeti     = FUNCTION_NAME_MDGETI
        mdgetl     = FUNCTION_NAME_MDGETL
        mpgeti     = FUNCTION_NAME_MPGETI
        mpgetl     = FUNCTION_NAME_MPGETL
        gageti     = FUNCTION_NAME_GAGETI
        isgeti     = FUNCTION_NAME_ISGETI
        lbgeti     = FUNCTION_NAME_LBGETI
        nggeti     = FUNCTION_NAME_NGGETI
        pcgeti     = FUNCTION_NAME_PCGETI
        sfgeti     = FUNCTION_NAME_SFGETI
        getusv     = FUNCTION_NAME_GETUSV
        slgeti     = FUNCTION_NAME_SLGETI
        stgeti     = FUNCTION_NAME_STGETI
        tdgeti     = FUNCTION_NAME_TDGETI
        vvgeti     = FUNCTION_NAME_VVGETI
        wmgeti     = FUNCTION_NAME_WMGETI
      PREINIT:
        typedef void (*ncar_function)( char*, int*, long );
      INPUT:
        char* IPN;
        int &IVL;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( IPN, &IVL, (long)strlen( IPN ) );
      OUTPUT:
        IVL


void
NCAR_FUNCTION_0070( TPID, CUSR )
      ALIAS:
        aggetc     = FUNCTION_NAME_AGGETC
        cpgetc     = FUNCTION_NAME_CPGETC
        dpgetc     = FUNCTION_NAME_DPGETC
        mapgtc     = FUNCTION_NAME_MAPGTC
        mdgetc     = FUNCTION_NAME_MDGETC
        mpgetc     = FUNCTION_NAME_MPGETC
        gagetc     = FUNCTION_NAME_GAGETC
        nggetc     = FUNCTION_NAME_NGGETC
        pcgetc     = FUNCTION_NAME_PCGETC
        sfgetc     = FUNCTION_NAME_SFGETC
        wmgetc     = FUNCTION_NAME_WMGETC
        vvgetc     = FUNCTION_NAME_VVGETC
        dsgetc     = FUNCTION_NAME_DSGETC
        nngetc     = FUNCTION_NAME_NNGETC
      PREINIT:
        typedef void (*ncar_function)( char*, char*, long, long );
        char _CUSR[128];
      INPUT:
        char* TPID;
        char* CUSR;
      CODE:
        memset( _CUSR, ' ', 128 );
        _CUSR[127] = '\0';
        CUSR = (char*)_CUSR;
        (*((ncar_function)ncar_functions[ix]))( TPID, CUSR, (long)strlen( TPID ), (long)strlen( CUSR ) );
      OUTPUT:
        CUSR


void
NCAR_FUNCTION_0071( TPID, CUSR )
      ALIAS:
        agsetc     = FUNCTION_NAME_AGSETC
        cpsetc     = FUNCTION_NAME_CPSETC
        dpsetc     = FUNCTION_NAME_DPSETC
        mapstc     = FUNCTION_NAME_MAPSTC
        mdsetc     = FUNCTION_NAME_MDSETC
        mpsetc     = FUNCTION_NAME_MPSETC
        gasetc     = FUNCTION_NAME_GASETC
        ngsetc     = FUNCTION_NAME_NGSETC
        pcsetc     = FUNCTION_NAME_PCSETC
        sfsetc     = FUNCTION_NAME_SFSETC
        vvsetc     = FUNCTION_NAME_VVSETC
        wmsetc     = FUNCTION_NAME_WMSETC
        dssetc     = FUNCTION_NAME_DSSETC
        dsseti     = FUNCTION_NAME_DSSETI
        nnsetc     = FUNCTION_NAME_NNSETC
      PREINIT:
        typedef void (*ncar_function)( char*, char*, long, long );
      INPUT:
        char* TPID;
        char* CUSR;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( TPID, CUSR, (long)strlen( TPID ), (long)strlen( CUSR ) );


void
NCAR_FUNCTION_0072( IOPT, STRING, NUMBER, ILCH )
      ALIAS:
        hstopc     = FUNCTION_NAME_HSTOPC
        conop4     = FUNCTION_NAME_CONOP4
      PREINIT:
        typedef void (*ncar_function)( char*, char*, int*, int*, long, long );
      INPUT:
        char* IOPT;
        char* STRING;
        int NUMBER;
        int ILCH;
      CODE:
        (*((ncar_function)ncar_functions[ix]))( IOPT, STRING, &NUMBER, &ILCH, (long)strlen( IOPT ), (long)strlen( STRING ) );


void
labmod( FMTX, FMTY, NUMX, NUMY, ISZX, ISZY, IXDC, IYDC, IXOR )
      PREINIT:
      INPUT:
        char* FMTX;
        char* FMTY;
        int NUMX;
        int NUMY;
        int ISZX;
        int ISZY;
        int IXDC;
        int IYDC;
        int IXOR;
      CODE:
        labmod_( FMTX, FMTY, &NUMX, &NUMY, &ISZX, &ISZY, &IXDC, &IYDC, &IXOR, (long)strlen( FMTX ), (long)strlen( FMTY ) );


void
anotat( LABX, LABY, LBAC, LSET, NDSH, DSHL )
      PREINIT:
        long DSHL_len;
      INPUT:
        char* LABX;
        char* LABY;
        int LBAC;
        int LSET;
        int NDSH;
        string1D* DSHL;
      CODE:
        anotat_( LABX, LABY, &LBAC, &LSET, &NDSH, DSHL, (long)strlen( LABX ), (long)strlen( LABY ), DSHL_len );


void
q8qst4( NAME, LBRARY, ENTRY, VRSION )
      PREINIT:
      INPUT:
        char* NAME;
        char* LBRARY;
        char* ENTRY;
        char* VRSION;
      CODE:
        q8qst4_( NAME, LBRARY, ENTRY, VRSION, (long)strlen( NAME ), (long)strlen( LBRARY ), (long)strlen( ENTRY ), (long)strlen( VRSION ) );



INCLUDE: ncar_commons.xsh

INCLUDE: pdl_boot.xsh

