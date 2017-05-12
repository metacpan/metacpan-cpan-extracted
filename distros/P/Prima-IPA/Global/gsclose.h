/* $Id$ */

#ifndef __GSCLOSE_H__
#define __GSCLOSE_H__

#include "IPAsupp.h"
#include <stdio.h>

/* Constants */

/* Worm algorithm flags */
#define TRACK_USE_MAXIMUM           0x0001 /* Двигаться по максимальным значениям */
#define TRACK_USE_MINIMUM           0x0000 /* Двигаться по минимальным значениям */
#define TRACK_REACH_END_POINT       0x0002 /* Двигаться до достижения заданной */
                                           /* конечной точки */
#define TRACK_CLOSE_CONTOUR         0x0000 /* Двигаться, пока не замкнется контур */
#define TRACK_CLOSE_ON_FIRST        0x0004 /* Закрывать только по достижению стартовой */
                                           /* точки */
#define TRACK_CLOSE_ON_ANY          0x0000 /* Закрывать по достижению любой точки контура */
#define TRACK_SLOPPY_DIRECTIONS     0x0008 /* Используются пять направлений из 9 */
#define TRACK_STRICT_DIRECTIONS     0x0000 /* Используются три направления из 9 */
#define TRACK_NO_CIRCLES            0x0010 /* "Отрезать" кольца */

extern PImage gs_close_edges(
                      PImage edges,
                      PImage gradient,
                      int maxlen,      /* максимально допустимая длина вновь созданного участка гpаницы */
                      int minedgelen,  /* минимальная длина "длинной" границы */
                      int mingradient  /* минимальное значение гpадиента, котоpое будет учитываться */
                     );
extern PImage gs_track(
                       PImage img,
                       int startpos,
                       int endpos,
                       int treshold,
                       unsigned long flags
                      );

#endif /* __GSCLOSE_H__ */

