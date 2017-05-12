/*
 * Copyright (c) 2000 Charles Ying. All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as sendmail itself.
 *
 */

#ifndef __CALLBACKS_H_
#define __CALLBACKS_H_

extern void init_callbacks(int, int);
extern void register_callbacks(struct smfiDesc *, char *, HV *, int);

#endif /* __CALLBACKS_H_ */
