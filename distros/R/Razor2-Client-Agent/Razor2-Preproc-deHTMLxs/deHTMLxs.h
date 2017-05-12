#ifndef RAZOR2_PREPROC_DEHTML_HH
#define RAZOR2_PREPROC_DEHTML_HH

int CM_PREPROC_is_html(const char *);

/* caller must give us empty buffer *text that */
/* is at least as big as *s. */
char *CM_PREPROC_html_strip(char *, char *);

#endif
