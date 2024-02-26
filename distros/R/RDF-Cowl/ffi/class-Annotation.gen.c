#include "cowl.h"

/*
 * DO NOT EDIT
 *
 * Generated via maint/tt/Class.c.tt
 */


CowlAnnotation * COWL_WRAP_cowl_annotation (
	CowlAnnotProp * prop,
	CowlAnyAnnotValue * value,
	CowlVector * annot
) {
	return cowl_annotation(
		prop,
		value,
		annot
	);
}


CowlAnnotProp * COWL_WRAP_cowl_annotation_get_prop (
	CowlAnnotation * annot
) {
	return cowl_annotation_get_prop(
		annot
	);
}


CowlAnnotValue * COWL_WRAP_cowl_annotation_get_value (
	CowlAnnotation * annot
) {
	return cowl_annotation_get_value(
		annot
	);
}


CowlVector * COWL_WRAP_cowl_annotation_get_annot (
	CowlAnnotation * annot
) {
	return cowl_annotation_get_annot(
		annot
	);
}

