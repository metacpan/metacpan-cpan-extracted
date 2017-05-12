#ifndef PWMATRIX_H
#define PWMATRIX_H

/*
 * Declaration of the PWMatrix class
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#undef bool
#include "qwmatrix.h"
#include "ppntarry.h"
#include "prect.h"
#include "pqt.h"

class PWMatrix : public QWMatrix {
public:
    PWMatrix() {}
    PWMatrix(float m11, float m12, float m21, float m22, float dx, float dy) :
	QWMatrix(m11, m12, m21, m22, dx, dy) {}
    PWMatrix(const QWMatrix &matrix) { *(QWMatrix *)this = matrix; }
};

#endif  // PWMATRIX_H
