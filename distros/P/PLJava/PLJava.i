/*******************************************************************************
## Name:        PLJava.i
## Purpose:     SWIG interface of PLJava.c
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/07/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
*******************************************************************************/

%module PLJava

extern int      PLJava_start();
extern char*    PLJava_eval(char* code);
extern char*    PLJava_eval_sv(char* code);
extern char*    PLJava_error();
extern void     PLJava_stop();

