/* $Id$ */

/*******************************************************************************/
/* Модуль работы с границами: закрытие, проведение линии между двумя точками и */
/* т.п.                                                                        */
/*******************************************************************************/

#include "gsclose.h"

/***************************************************************************/
/* Резеpвиpуемые цвета в контуpном image:                                  */
/*       точка-кандидат на пpодление edge.                                 */
#define PIX_EDGE_CANDIDATE              0x0B
/*       точка была кандидатом, но нужда в ней отпала                      */
#define PIX_OLD_CANDIDATE               0x03
/*       изолиpованная точка                                               */
#define PIX_SINGLE                      0x07
/*       возможный новый участок гpаницы                                   */
#define PIX_NEW_EDGE                    0x09
/*       пиксел пpинадлежит участку достаточной длины                      */
#define PIX_IN_LONG_EDGE                0x0C
/*       пиксел pезеpвиpуется и пpовеpятся не должен                       */
#define PIX_RESERVE                     0x01
/* Те кандидаты, которые не дали контуров */
#define PIX_BAD_CANDIDATE               0x0E
/*       нетpонутый пиксел из исходного image                              */
#define PIX_ORIG                        0xFF

/* Ниже - константы для трекинга                                           */
/* Пиксел находится в контуре                                              */
#define PIX_IN_TRACK                    PIX_ORIG
#define PIX_IN_POSSIBLE_TRACK           PIX_RESERVE
#define PIX_PASSED                      0x02
#define PIX_TST                         0x0E
/***************************************************************************/

#define PIX1(x)     ((x)==0 ? 0 : 1)

typedef struct {
    int pos;
    int direction;
} CandidateInfo;

CandidateInfo *candidates;
volatile unsigned ccount,cnum;

static RGBColor pal256_16[] =
{
   {    0,    0,    0},    /* 0 Black */
   { 0x80,    0,    0},    /* 1 Blue */
   {    0, 0x80,    0},    /* 2 Green */
   { 0x80, 0x80,    0},    /* 3 Cyan */
   {    0,    0, 0x80},    /* 4 Red */
   { 0x80,    0, 0x80},    /* 5 Magenta */
   {    0, 0x80, 0x80},    /* 6 Brown */
   { 0x80, 0x80, 0x80},    /* 7 DGray */
   { 0xCC, 0xCC, 0xCC},    /* 8 Pale Gray */
   { 0xFF,    0,    0},    /* 9 LBlue */
   {    0, 0xFF,    0},    /* A LGreen */
   { 0xFF, 0xFF,    0},    /* B LCyan */
   {    0,    0, 0xFF},    /* C LRed */
   { 0xFF,    0, 0xFF},    /* D LMagenta */
   {    0, 0xFF, 0xFF},    /* E Yellow */
   { 0xFF, 0xFF, 0xFF}     /* F White */
};

static void add_candidate(int xpos,int direction)
{
    if (ccount==cnum) {
        cnum+=50;
        candidates=realloc(candidates,cnum*sizeof(CandidateInfo));
    } /* endif */

    candidates[ccount].pos=xpos;
    candidates[ccount].direction=direction;
    ccount++;
}

static Bool valid_direction(PImage img,int direction,int x,int y)
{
    if ((x==0) && ((direction==0) || (direction==6) || (direction==7))) {
        return false;
    } /* endif */
    if ((x==(img->w-1)) && ((direction>=2) && (direction<=4))) {
        return false;
    } /* endif */
    if ((y==0) && ((direction>=4) && (direction<=6))) {
        return false;
    } /* endif */
    if ((y==(img->h-1)) && ((direction>=0) && (direction<=2))) {
        return false;
    } /* endif */
    return true;
}

/*********************************************************************************/
/* Определяет, можно ли считать точку конечной для границы. Можно в тех случаях, */
/* когда точка имеет только одного соседа, или двух, но рядом расположенных.     */
/*********************************************************************************/
static Bool pix_is_end(PImage img,int *shift_table,int xpos,int x,int y)
{
    int i;
    int cnt=0,zerocnt=0;
    int nonzerodir=-1; /* позиция, в которой был найден последний ненулевой сосед для точки */

    for (i=0; i<8; i++) {
        int pval=0; /* если мы "вылазим" за пределы image - считаем, что там у нас 0 */
        if (valid_direction(img,i,x,y)) {
            pval=img->data[xpos+shift_table[i]];
        } /* endif */
        if (pval>0) {
            if (zerocnt>0) {
                if (nonzerodir==0 && i==7) { /* чтобы "замкнуть" направления 0 и 7, которые таки являются соседними
                    поскольку nonzerodir содержит _последнее_ "ненулевое направление", то
                    исключаются случаи, когда ненулевые на 0 и 1. */
                    return true;
                } /* endif */
                return false;
            } /* endif */
            nonzerodir=i;
            cnt++;
            if (cnt>2) {
                return false;
            } /* endif */
        } /* endif */
        else {
            if (cnt>0) { /* У нас уже были ненулевые соседи, значит пора считать нулевых */
                zerocnt++;
            } /* endif */
        } /* endelse */
    } /* endfor */

    return (Bool)(cnt==2 || cnt==1); /* случаи одиночных точек исключаем */
}

Bool check_edge_length(PImage img,int minlen,int *shift_table,int xpos,int fromdirection,int edgelen,Bool islong)
{
    short x,y,i,direction,cnt=5;
    int newxpos;
    Bool longedge=islong || (edgelen>minlen);
    Bool haveNeighbours;
    Bool backup_direction=-1;

    x=xpos%img->lineSize;
    y=xpos/img->lineSize;

    if (fromdirection==-1) {
        direction=0;
        cnt=8;
    } /* endif */
    else {
        direction=(fromdirection+5)%8;
    } /* endelse */

    img->data[xpos]=PIX_RESERVE;
    do {
        haveNeighbours=false;
        for (i=0; i<cnt; i++) {
            direction=(direction+1)%8;
            if (valid_direction(img,direction,x,y)) {
                newxpos=xpos+shift_table[direction];
                if (img->data[newxpos]==PIX_ORIG) {
                    Bool rc;
                    if (fromdirection==-1) {
                        backup_direction=(direction+4)%8;
                    } /* endif */
                    haveNeighbours=true;
                    rc=check_edge_length(img,minlen,shift_table,newxpos,direction,edgelen+1,longedge);
                    longedge=rc || longedge;
                } /* endif */
                else if (img->data[newxpos]==PIX_IN_LONG_EDGE) {
                    longedge=true;
                } /* endelse */
            } /* endif */
        } /* endfor */
    /* Смысл этого while в том, чтобы в случае, когда в данной точке есть       */
    /* ветвление границы, и какая-либо из ветвей достаточно длинная, а вторая - */
    /* нет, (или вторая, третья и т.д.), то делаем еще один проход по второй и  */
    /* и прочим чтобы отметить их как длинные                                   */
    } while (haveNeighbours && longedge && !islong); /* enddo */

    if (longedge) {
        if (!haveNeighbours && pix_is_end(img,shift_table,xpos,x,y)) {
            img->data[xpos]=PIX_EDGE_CANDIDATE;
            add_candidate(xpos,fromdirection==-1 ? backup_direction : fromdirection);
        } /* endif */
        else {
            img->data[xpos]=PIX_IN_LONG_EDGE;
        } /* endelse */
    } /* endif */
    else {
        img->data[xpos]=PIX_ORIG;
    } /* endelse */

    return longedge;
}

/********************************************************************/
/* Определяет, соседи ли точки, определяемые позициями pos1 и pos2. */
/* Точки не являются соседями если они совпадают.                   */
/********************************************************************/
static Bool is_neighbours(int lineSize,int pos1,int pos2)
{
    int sx,sy;
    sx=abs(pos1%lineSize-pos2%lineSize); /* abs(x1-x2) */
    sy=abs(pos1/lineSize-pos2/lineSize); /* abs(y1-y2) */
    if (sx<=1 && sy<=1) {
        return (Bool)(sx!=0 || sy!=0);
    } /* endif */
    return false;
}

/******************************************************************************/
/* Считает количество соседей, исключая тех, которые входят в новосоздаваемую */
/* границу                                                                    */
/******************************************************************************/
static int neighbours(PImage img,int *shift_table,int pos,int *neighbourPos)
{
    int x=(pos%img->lineSize),y=(pos/img->lineSize);
    int i,pixcnt=0;

    for (i=0; i<8; i++) {
        if (valid_direction(img,i,x,y) && img->data[pos+shift_table[i]]>0 && img->data[pos+shift_table[i]]!=PIX_RESERVE) {
            if (neighbourPos!=nil) {
                neighbourPos[i]=pos+shift_table[i];
            } /* endif */
            pixcnt++;
        } /* endif */
        else if (neighbourPos!=nil) {
            neighbourPos[i]=-1;
        } /* endelse */
    } /* endfor */

    return pixcnt;
}

static void trace_edges(PImage img,int minlen,int *shift_table)
{
    int ypos,xpos,x,y;

    for (ypos=0,y=0; ypos<img->dataSize; ypos+=img->lineSize,y++) {
        for (xpos=ypos,x=0; x<img->w; xpos++,x++) {
            if (img->data[xpos]==PIX_ORIG) {
                if (pix_is_end(img,shift_table,xpos,x,y)) {
                    check_edge_length(img,minlen,shift_table,xpos,-1,1,false);
                } /* endif */
                else if (neighbours(img,shift_table,xpos,nil)==0) {
                    img->data[xpos]=PIX_SINGLE;
                } /* endelse */
            } /* endif */
        } /* endfor */
    } /* endfor */
}

Bool make_new_edge(PImage dstimg,
                   PImage gradient,
                   int *shift_table,
                   int maxlen,
                   int mingradient,
                   int start_pos,
                   int xpos,
                   int fromdirection,
                   int edgelen
                  )
{
    int i;
    int direction=(fromdirection==-1 ? 7 : (fromdirection+6)%8),selected_direction;
    int cnt=(fromdirection==-1 ? 8 : 3);
    int gradientval=mingradient-1;
    int x=xpos%dstimg->lineSize,y=xpos/dstimg->lineSize;
    int oldval=dstimg->data[xpos];
    Bool edge_closed;

    if (maxlen>=0 && edgelen>maxlen) {
        return false;
    } /* endif */

    dstimg->data[xpos]=PIX_RESERVE;

    if (xpos!=start_pos) {
        int neighbourPos[8];
        int ncount=neighbours(dstimg,shift_table,xpos,neighbourPos);
        edge_closed=false;
        if (ncount>0) {
            Bool dontClose=false;
            for (i=0; i<8; i++) {
                if (neighbourPos[i]==-1) {
                    continue;
                } /* endif */
                /* Если среди наших соседей есть соседи стартовой точки - замыкаться
                 не будем. Однако если есть сосед не из длинного контура */
                if (dstimg->data[neighbourPos[i]]!=PIX_IN_LONG_EDGE) {
                    dontClose=false;
                    break;
                } /* endif */
                if (is_neighbours(dstimg->lineSize,start_pos,neighbourPos[i])) {
                    dontClose=true;
                } /* endif */
            } /* endfor */
            for (i=0; i<8 && !dontClose; i++) {
                if (neighbourPos[i]<0 || neighbourPos[i]==start_pos) {
                    continue;
                } /* endif */
                /* А вот теперь можно быть уверенным, что нашли точку замыкания. */
                edge_closed=true;
                /* Дальше надо бы проверить, а не наткнулись ли мы на какую-либо
                точку, которая может дать нам продолжение контура. Это может
                быть единичная, или часть короткого контура. */
                switch (dstimg->data[neighbourPos[i]]) {
                    case PIX_SINGLE: /* Единичная точка просто становится новым кандидатом */
                        dstimg->data[neighbourPos[i]]=PIX_EDGE_CANDIDATE;
                        add_candidate(neighbourPos[i],i);
                        break;
                    case PIX_ORIG: /* Угу, нетронутый контур. Надо пошуршать на предмет кандидатов.
                                    Поскольку готовая функция есть - мы просто убеждаем ее, что контур уже длинный */
                        check_edge_length(dstimg,1,shift_table,neighbourPos[i],i,0,true);
                        break;
                    case PIX_EDGE_CANDIDATE:
                        /*?? А вот если попалась точка-кандидат на продление -
                        ?? она должна перестать быть таковой, ибо на нее уже замкнулись */
                        dstimg->data[neighbourPos[i]]=PIX_OLD_CANDIDATE;
                        break;
                    default:
                        break;
                } /* endswitch */
            } /* endfor */
            if (edge_closed) {
                dstimg->data[xpos]=PIX_NEW_EDGE;
                return true;
            } /* endif */
        } /* endif */
    } /* endif */

    selected_direction=-1;
    for (i=0; i<cnt; i++) {
        direction=(direction+1)%8;

        if (valid_direction(dstimg,direction,x,y)) {
            int gval,chkpos=xpos+shift_table[direction];
            if (dstimg->data[chkpos]==0) {
/*          if (dstimg->data[chkpos]>0 && dstimg->data[chkpos]!=PIX_RESERVE) {
//
//              if ((chkpos!=start_pos) && (!is_neighbours(dstimg->lineSize,chkpos,start_pos))) {
//                  // Другими словами: найденная ненулевая точка не является той,
//                  // с которой мы начали, и не является непосредственным соседом
//                  // той точки, с которой мы начали.
//                  if (edgelen>0) { // если edgelen==0, то точка в xpos уже промаркирована и трогать ее не стоит
//                      dstimg->data[xpos]=PIX_NEW_EDGE;
//                  } 
//                  else {
//                      dstimg->data[xpos]=oldval;
//                  } 
//                  if (dstimg->data[chkpos]==PIX_ORIG) {
//                      // Очень интересно: соединямся с короткой границей.
//                      // Поскольку стартовали с длинной границы, то новонайденную
//                      // короткую надо к ней "присоединить".
//                      check_edge_length(dstimg,1,shift_table,chkpos,direction,edgelen+1,true);
//                  } 
//                  else if (dstimg->data[chkpos]==PIX_SINGLE) {
//                      dstimg->data[chkpos]=PIX_EDGE_CANDIDATE;
//                      add_candidate(chkpos,direction);
//                  } 
//                  // Ну и дальнейшие изыскания можно прекращать.
//                  return true;
//              } 
//          } 
//          else { */
                gval=gradient->data[chkpos];
                if (gval>=mingradient && gval>gradientval) {
                    selected_direction=direction;
                    gradientval=gval;
                } /* endif */
            } /* endif */
        } /* endif */
    } /* endfor */

    if (selected_direction==-1) {
        dstimg->data[xpos]=oldval;
        return false;
    } /* endif */

    edge_closed=make_new_edge(dstimg,
                              gradient,
                              shift_table,
                              maxlen,
                              mingradient,
                              start_pos,
                              xpos+shift_table[selected_direction],
                              selected_direction,
                              edgelen+1
                             );
    if (edge_closed && edgelen>0) {
        dstimg->data[xpos]=PIX_NEW_EDGE;
    } /* endif */
    else {
        dstimg->data[xpos]=oldval;
    } /* endelse */

    return edge_closed;
}

PImage gs_close_edges(
                      PImage edges,
                      PImage gradient,
                      int maxlen,      /* максимально допустимая длина вновь созданного участка гpаницы */
                      int minedgelen,  /* минимальная длина "длинной" границы */
                      int mingradient  /* минимальное значение гpадиента, котоpое будет учитываться */
                     )
{
    PImage dstimg;
    int shift_table[8];
    int i;


    dstimg=createImage(edges->w,edges->h,im256);
    memcpy(dstimg->data,edges->data,edges->dataSize);
    memcpy(dstimg->palette,edges->palette,edges->palSize);
    memcpy(dstimg->palette,pal256_16,16*sizeof(RGBColor));

    cnum=50;
    candidates=(CandidateInfo*)malloc(cnum*sizeof(CandidateInfo));
    ccount=0;

    shift_table[0]=edges->lineSize-1;
    shift_table[1]=edges->lineSize;
    shift_table[2]=edges->lineSize+1;
    shift_table[3]=1;
    shift_table[4]=-edges->lineSize+1;
    shift_table[5]=-edges->lineSize;
    shift_table[6]=-edges->lineSize-1;
    shift_table[7]=-1;

    trace_edges(dstimg,minedgelen,shift_table);
    for (i=0; i<ccount; i++) {
        Bool rc;
        if (dstimg->data[candidates[i].pos]==PIX_OLD_CANDIDATE) {
            /* Этот кандидат уже не кандидат. 8) */
            continue;
        } /* endif */
        rc=make_new_edge(
                 dstimg,
                 gradient,
                 shift_table,
                 maxlen,
                 mingradient,
                 candidates[i].pos,
                 candidates[i].pos,
                 candidates[i].direction,
                 0
                );
        if (!rc) {
            dstimg->data[candidates[i].pos]=PIX_BAD_CANDIDATE;
        } /* endif */
    } /* endfor */

    free(candidates);

    return dstimg;
}

/*****************************************************************************/
/*                                                                           */
/* =========================== Алгоритм трекинга =========================== */
/*                                                                           */
/*****************************************************************************/

Bool build_track(
                 PImage img,
                 PImage dstimg,
                 int startpos,
                 int endpos,
                 int treshold,
                 unsigned long flags,
                 int *shift_table,
                 int pos,
                 int fromdirection,
                 long track_len
                )
{
    int direction;
    int i,selected_val,selected_direction;
    Bool rc;

    if (track_len>100000) {
        dstimg->data[pos]=PIX_RESERVE;
        return false;
    } /* endif */

    if ((flags & TRACK_REACH_END_POINT)!=0) {
        if (is_neighbours(img->lineSize,endpos,pos)) {
            dstimg->data[endpos]=PIX_IN_TRACK;
            dstimg->data[pos]=PIX_IN_TRACK;
            return true;
        }
    } /* endif */

    dstimg->data[pos]=PIX_IN_POSSIBLE_TRACK;

    do {
        selected_direction=-1;
        selected_val=((flags & TRACK_USE_MAXIMUM) ? -1 : 256);
        direction=(fromdirection+((flags & TRACK_SLOPPY_DIRECTIONS)==0 ? 6 : 5))%8;

        for (i=0; i<((flags & TRACK_SLOPPY_DIRECTIONS)==0 ? 3 : 5); i++) {
            direction=(direction+1)%8;
            if (valid_direction(img,direction,(pos%img->lineSize)/* x */,(pos/img->lineSize)/* y */)) {
                int chkpos=pos+shift_table[direction];
                if (dstimg->data[chkpos]==0) {
                    if (((flags & TRACK_USE_MAXIMUM)!=0 && img->data[chkpos]>=treshold) ||
                        ((flags & TRACK_USE_MAXIMUM)==0 && img->data[chkpos]<=treshold)
                       ) {
                        if (((flags & TRACK_USE_MAXIMUM)!=0 && selected_val<img->data[chkpos]) ||
                            ((flags & TRACK_USE_MAXIMUM)==0 && selected_val>img->data[chkpos])) {
                            selected_val=img->data[chkpos];
                            selected_direction=direction;
                        } /* endif */
                    } /* endif */
                } /* endif */
                else {
                    if ((flags & TRACK_REACH_END_POINT)==0) {
                        if (dstimg->data[chkpos]==PIX_IN_POSSIBLE_TRACK) {
                            if ((flags & TRACK_CLOSE_ON_FIRST)==0 || chkpos==startpos) {
                                dstimg->data[pos]=PIX_IN_TRACK;
                                return true;
                            } /* endif */
                        } /* endif */
                    } /* endif */
                } /* endelse */
            } /* endif */
        } /* endfor */

        if (selected_direction==-1) {
            dstimg->data[pos]=PIX_RESERVE;
            return false;
        } /* endif */

        rc=build_track(
                       img,
                       dstimg,
                       startpos,
                       endpos,
                       treshold,
                       flags,
                       shift_table,
                       pos+shift_table[selected_direction],
                       selected_direction,
                       track_len+1
                      );
        if (rc) {
            dstimg->data[pos]=PIX_IN_TRACK;
        } /* endif */
    } while (!rc); /* enddo */

    return true;
}

Bool remove_circles(
                    PImage img,
                    PImage dstimg,
                    int startpos,
                    int endpos,
                    int treshold,
                    unsigned long flags,
                    int *shift_table,
                    int prevpos,
                    int pos
                   )
{
    int neighbourPos[8],i,ncount;
    Bool rc=false;

    dstimg->data[pos]=PIX_RESERVE;
    ncount=neighbours(dstimg,shift_table,pos,neighbourPos);
    for (i=0; i<8; i++) {
        if (neighbourPos[i]!=-1 && neighbourPos[i]!=prevpos) {
            rc=remove_circles(
                              img,
                              dstimg,
                              startpos,
                              endpos,
                              treshold,
                              flags,
                              shift_table,
                              pos,
                              neighbourPos[i]
                             );
        } /* endif */
    } /* endfor */

    if (ncount>1) {
        dstimg->data[pos]=PIX_TST;
    } /* endif */

    return rc;
}

PImage gs_track(PImage img,int startpos,int endpos,int treshold,unsigned long flags)
{
    PImage srcimg,dstimg;
    int shift_table[8];
    int xs,ys,xe,ye,dx,dy;
    int startdirection,dirshift=0;
    Bool rc;

    shift_table[0] = img->lineSize-1;
    shift_table[1] = img->lineSize;
    shift_table[2] = img->lineSize+1;
    shift_table[3] = 1;
    shift_table[4] = -img->lineSize-1;
    shift_table[5] = -img->lineSize;
    shift_table[6] = -img->lineSize+1;
    shift_table[7] = -1;

    /* Определим направление, в котором начнем двигаться */
    xs=startpos%img->lineSize;
    ys=startpos/img->lineSize;
    xe=endpos%img->lineSize;
    ye=endpos/img->lineSize;
    dx=xe-xs;
    dy=ye-ys;
    if ((abs(dx)<<2)>dy) {
        dirshift+=dx>0 ? 1 : -1;
    } /* endif */
    if ((abs(dy)<<2)>dx) {
        dirshift+=dy>0 ? img->lineSize : -img->lineSize;
    } /* endif */
    for (startdirection=0; startdirection<8; startdirection++) {
        if (dirshift==shift_table[startdirection]) {
            break;
        } /* endif */
    } /* endfor */
    startdirection=startdirection%8;

    dstimg=createImage(img->w,img->h,im256);
    srcimg=create_compatible_image(img,true);
    img=srcimg;

    memcpy(dstimg->palette,pal256_16,sizeof(Color)*16);

    rc=build_track(
                img,
                dstimg,
                startpos,
                endpos,
                treshold,
                flags,
                shift_table,
                startpos,
                startdirection,
                0
               );
    if ((flags & TRACK_NO_CIRCLES)!=0) {
        remove_circles(
                       img,
                       dstimg,
                       startpos,
                       endpos,
                       treshold,
                       flags,
                       shift_table,
                       -1,
                       startpos
                      );
    } /* endif */

    destroyImage(srcimg);

    return dstimg;
}
