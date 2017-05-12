#ifndef PPALETTE_H
#define PPALETTE_H

/*
 * Declaration of the PPalette and PColorGroup classes
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "qpalette.h"
#include "pcolor.h"
#include "pqt.h"

class PColorGroup : public QColorGroup {
public:
    PColorGroup() {}
    PColorGroup(const QColor &foreground, const QColor &background,
		const QColor &light, const QColor &dark, const QColor &mid,
		const QColor &text, const QColor &base) :
	QColorGroup(foreground, background, light, dark, mid, text, base) {}

    PColorGroup(const QColorGroup &colorgroup) {
	*(QColorGroup *)this = colorgroup;
    }
};

class PPalette : public QPalette {
public:
    PPalette() {}
    PPalette(const QColor &background) : QPalette(background) {}
    PPalette(const QColorGroup &normal, const QColorGroup &disabled,
	     const QColorGroup &active) : QPalette(normal, disabled, active) {}

    PPalette(const QPalette &palette) { *(QPalette *)this = palette; }
};

#endif  // PPALETTE_H
