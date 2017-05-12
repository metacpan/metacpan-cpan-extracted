/*  Last saved: Thu 02 Mar 2017 10:08:09 AM */

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  Copyright (c) 2015 Bob Free. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

#include <stdio.h>

#include "pgopogl.h"

#include "pgopogl_call_XS.h"

#include "gl_util.h"

#ifndef M_PI
#ifdef PI
#define M_PI PI
#else
#define M_PI 3.1415926535897932384626433832795
#endif
#endif


/* Note: this is caching procs once for all contexts */
/* !!! This should instead cache per context */
#if defined(_WIN32) || (defined(__CYGWIN__) && defined(HAVE_W32API))
#define loadProc(proc,name) \
{ \
  if (!proc) \
  { \
    proc = (void *)wglGetProcAddress(name); \
    if (!proc) croak(name " is not supported by this renderer"); \
  } \
}
#define testProc(proc,name) ((proc) ? 1 : !!(proc = (void *)wglGetProcAddress(name)))
#else
#define loadProc(proc,name)
#define testProc(proc,name) 1
#endif


/********************/
/* RPN Processor    */
/********************/

/* RPN Ops */
enum
{
  RPN_NOP = 0,
  RPN_PSH,
  RPN_POP,

  RPN_CNT,
  RPN_IDX,
  RPN_CLS,
  RPN_COL,
  RPN_RWS,
  RPN_ROW,

  RPN_SET,
  RPN_GET,
  RPN_STO,
  RPN_LOD,

  RPN_TST,
  RPN_NOT,
  RPN_EQU,
  RPN_GRE,
  RPN_LES,

  RPN_END,
  RPN_EIF,
  RPN_ERW,
  RPN_ERI,

  RPN_RET,
  RPN_RIF,
  RPN_RRW,
  RPN_RRI,

  RPN_SUM,
  RPN_AVG,

  RPN_RND,
  RPN_DUP,
  RPN_SWP,
  RPN_ABS,
  RPN_NEG,

  RPN_INC,
  RPN_DEC,

  RPN_ADD,	// Also OR
  RPN_MUL,	// ALSO AND
  RPN_DIV,
  RPN_POW,
  RPN_MOD,
  RPN_MIN,
  RPN_MAX,
  RPN_SIN,
  RPN_COS,
  RPN_TAN,
  RPN_AT2,

  RPN_DMP,
  RPN_FLR,
  RPN_CGT,
  RPN_CST,
  RPN_RGT,
  RPN_RST
};

/* RPN breaks */
enum
{
  RPNF_CONTINUE = 0,
  RPNF_END,
  RPNF_ENDROW,
  RPNF_RETURN,
  RPNF_RETURNROW
};

/* RPN OP link-list */
struct tag_rpn_op
{
  int			op;
  GLfloat		value;
  struct tag_rpn_op *	next;
};
typedef struct tag_rpn_op rpn_op;

/* RPN OP stack for a given column */
struct tag_rpn_stack
{
  int		count;
  int		max_count;
  GLfloat *	data;
  rpn_op *	ops;
};
typedef struct tag_rpn_stack rpn_stack;

/* RPN Object */
struct tag_rpn_context
{
  int		rows;
  int		cols;
  int		oga_count;
  oga_struct **	oga_list;
  GLfloat *	store;
  rpn_stack **	stacks;
};
typedef struct tag_rpn_context rpn_context;

/* RPN Parser */
rpn_stack * rpn_parse(int size,char * string)
{
  rpn_stack *	stack = malloc(sizeof(rpn_stack));
  rpn_op *	op = NULL;
  rpn_op *	last = NULL;
  char *	data = NULL;

  /* Will destroy string, so make a copy */
  memset(stack,0,sizeof(rpn_stack));
  if (string && *string)
  {
    /* Assumes ASCII */
    data = malloc(strlen(string)+1);
    strcpy(data,string);
    string = data;
  }

  /* OPs are comma-separated */
  while (string && *string)
  {
    rpn_op *	cur = NULL;
    char *	pos = string;
    char *	end = strchr(pos,',');
    int		len;

    /* Grab op */
    if (end)
    {
      *end = 0;
      string = end+1;
      len = end - pos;
    }
    else
    {
      len = strlen(string);
      string += len;
    }

    /* Empty op is a NOP */
    if (!len) continue;

    /* Update linklist */
    cur = malloc(sizeof(rpn_op));
    memset(cur,0,sizeof(rpn_op));
    if (last)
    {
      last->next = cur;
    }
    else
    {
      op = cur;
    }
    last = cur;

    /* Check for primitive OPs */
    if (len == 1)
    {
      switch (*pos)
      {
        case '!':
        {
          cur->op = RPN_NOT;
          continue;
        }
        case '-':
        {
          cur->op = RPN_NEG;
          continue;
        }
        case '+':
        {
          cur->op = RPN_ADD;
          continue;
        }
        case '*':
        {
          cur->op = RPN_MUL;
          continue;
        }
        case '/':
        {
          cur->op = RPN_DIV;
          continue;
        }
        case '%':
        {
          cur->op = RPN_MOD;
          continue;
        }
        case '=':
        {
          cur->op = RPN_EQU;
          size++;
          continue;
        }
        case '>':
        {
          cur->op = RPN_GRE;
          size++;
          continue;
        }
        case '<':
        {
          cur->op = RPN_LES;
          size++;
          continue;
        }
        case '?':
        {
          cur->op = RPN_TST;
          continue;
        }
      }
    }

    /* Check for textual OPs */
    if (!strcmp(pos,"pop"))
    {
      cur->op = RPN_POP;
    }
    else if (!strcmp(pos,"rand"))
    {
      cur->op = RPN_RND;
      size++;
    }
    else if (!strcmp(pos,"dup"))
    {
      cur->op = RPN_DUP;
      size++;
    }
    else if (!strcmp(pos,"swap"))
    {
      cur->op = RPN_SWP;
    }
    else if (!strcmp(pos,"set"))
    {
      cur->op = RPN_SET;
    }
    else if (!strcmp(pos,"get"))
    {
      cur->op = RPN_GET;
      size++;
    }
    else if (!strcmp(pos,"store"))
    {
      cur->op = RPN_STO;
    }
    else if (!strcmp(pos,"load"))
    {
      cur->op = RPN_LOD;
    }
    else if (!strcmp(pos,"end"))
    {
      cur->op = RPN_END;
    }
    else if (!strcmp(pos,"endif"))
    {
      cur->op = RPN_EIF;
    }
    else if (!strcmp(pos,"endrow"))
    {
      cur->op = RPN_ERW;
    }
    else if (!strcmp(pos,"endrowif"))
    {
      cur->op = RPN_ERI;
    }
    else if (!strcmp(pos,"return"))
    {
      cur->op = RPN_RET;
    }
    else if (!strcmp(pos,"returnif"))
    {
      cur->op = RPN_RIF;
    }
    else if (!strcmp(pos,"returnrow"))
    {
      cur->op = RPN_RRW;
    }
    else if (!strcmp(pos,"returnrowif"))
    {
      cur->op = RPN_RRI;
    }
    else if (!strcmp(pos,"if"))
    {
      cur->op = RPN_TST;
    }
    else if (!strcmp(pos,"or"))
    {
      cur->op = RPN_ADD;
    }
    else if (!strcmp(pos,"and"))
    {
      cur->op = RPN_MUL;
    }
    else if (!strcmp(pos,"inc"))
    {
      cur->op = RPN_INC;
    }
    else if (!strcmp(pos,"dec"))
    {
      cur->op = RPN_DEC;
    }
    else if (!strcmp(pos,"sum"))
    {
      cur->op = RPN_SUM;
    }
    else if (!strcmp(pos,"avg"))
    {
      cur->op = RPN_AVG;
    }
    else if (!strcmp(pos,"abs"))
    {
      cur->op = RPN_ABS;
    }
    else if (!strcmp(pos,"power"))
    {
      cur->op = RPN_POW;
    }
    else if (!strcmp(pos,"min"))
    {
      cur->op = RPN_MIN;
    }
    else if (!strcmp(pos,"max"))
    {
      cur->op = RPN_MAX;
    }
    else if (!strcmp(pos,"sin"))
    {
      cur->op = RPN_SIN;
    }
    else if (!strcmp(pos,"cos"))
    {
      cur->op = RPN_COS;
    }
    else if (!strcmp(pos,"tan"))
    {
      cur->op = RPN_TAN;
    }
    else if (!strcmp(pos,"atan2"))
    {
      cur->op = RPN_AT2;
    }
    else if (!strcmp(pos,"count"))
    {
      cur->op = RPN_CNT;
      size++;
    }
    else if (!strcmp(pos,"index"))
    {
      cur->op = RPN_IDX;
      size++;
    }
    else if (!strcmp(pos,"columns"))
    {
      cur->op = RPN_CLS;
      size++;
    }
    else if (!strcmp(pos,"column"))
    {
      cur->op = RPN_COL;
      size++;
    }
    else if (!strcmp(pos,"rows"))
    {
      cur->op = RPN_RWS;
      size++;
    }
    else if (!strcmp(pos,"row"))
    {
      cur->op = RPN_ROW;
      size++;
    }
    else if (!strcmp(pos,"pi"))
    {
      cur->op = RPN_PSH;
      cur->value = (float)M_PI;
      size++;
    }
    else if (!strcmp(pos,"dump"))
    {
      cur->op = RPN_DMP;
    }
    else if (!strcmp(pos,"floor"))
    {
      cur->op = RPN_FLR;
    }
    else if (!strcmp(pos,"colget"))
    {
      cur->op = RPN_CGT;
    }
    else if (!strcmp(pos,"colset"))
    {
      cur->op = RPN_CST;
    }
    else if (!strcmp(pos,"rowget"))
    {
      cur->op = RPN_RGT;
    }
    else if (!strcmp(pos,"rowset"))
    {
      cur->op = RPN_RST;
    }
    /* Default to a numeric push */
    else
    {
      cur->op = RPN_PSH;
      cur->value = (float)atof(pos);
      size++;
    }
  }

  /* release string copy */
  if (data) free(data);
  stack->data = malloc(sizeof(GLfloat)*size);
  stack->max_count = size;
  stack->ops = op;
  return(stack);
}

/* Instantiate an RPN Object */
rpn_context * rpn_init(int oga_count,oga_struct ** oga_list,int col_count,char ** col_ops)
{
  rpn_context * ctx = NULL;
  int elements = 0;
  int i,j;

  if (!oga_count) croak("Missing OGA count");
  if (!oga_list) croak("Missing OGA list");
  if (!col_count) croak("Missing column count");

  /* Validate OGAs */
  for (i=0; i<oga_count; i++)
  {
    if (!oga_list[i]) croak("Missing OGA %d",i);
    if (!oga_list[i]->item_count) croak("Empty OGA %d",i);

    /* Check that all OGAs have the same dimension */
    if (!i)
    {
      elements = oga_list[i]->item_count;
      if (elements % col_count) croak("Invalid OGA size for %d columns",col_count);
    }
    else if (elements != oga_list[i]->item_count)
    {
      croak("Invalid length in OGA %d",i);
    }

    /* Only supporting GLfloat for now */
    for (j=0; j<oga_list[i]->type_count; j++)
    {
      if (oga_list[i]->types[j] != GL_FLOAT)
        croak("Unsupported type in OGA %d",i);
    }
  }

  /* Alloc Object data */
  ctx = malloc(sizeof(rpn_context));
  if (!ctx) croak("Unable to alloc rpn context");

  /* Alloc current row store */
  ctx->store = malloc(sizeof(GLfloat) * col_count);
  if (!ctx->store) croak("Unable to alloc rpn store");

  /* Alloc column stack array */
  ctx->stacks = malloc(sizeof(rpn_stack *) * col_count);
  if (!ctx->stacks) croak("Unable to alloc rpn stacks");

  ctx->cols =col_count;
  ctx->rows = elements / col_count;
  ctx->oga_count = oga_count;
  ctx->oga_list = oga_list;

  /* Parse and populate column stacks */
  for (i=0; i<col_count; i++)
    ctx->stacks[i] = rpn_parse(oga_count,col_ops[i]);

  return(ctx);
}

/* Release OP link-list */
void rpn_delete_ops(rpn_op * ops)
{
  if (!ops) return;
  rpn_delete_ops(ops->next);
  free(ops);
}

/* Release OPS stack */
void rpn_delete_stack(rpn_stack * stack)
{
  if (!stack) return;
  rpn_delete_ops(stack->ops);
  free(stack->data);
  free(stack);
}

/* Release RPN Object */
void rpn_term(rpn_context * ctx)
{
  if (ctx)
  {
    int i;
    for (i=0; i<ctx->cols; i++)
      rpn_delete_stack(ctx->stacks[i]);

    free(ctx->stacks);
    free(ctx->store);
    free(ctx);
  }
}

/* Push an RPN value on the stack */
void rpn_push(rpn_stack * stack, GLfloat value)
{
  if (stack){
    if(stack->count == stack->max_count)
      croak("Trying to push past allocated rpn stack size: %d", stack->count);
    stack->data[stack->count++] = value;
  }
}

/* Pop an RPN value from the stack */
GLfloat rpn_pop(rpn_stack * stack)
{
  GLfloat value = 0.0;

  if (stack && stack->count)
  {
    value = stack->data[--stack->count];
    if (!stack->count) rpn_push(stack,0.0);
  }

  return(value);
}

/* Dump out the current stack */
void rpn_dump(rpn_stack * stack, int row, int col, float reg)
{
  if (stack && stack->count)
  {
    int i;
    warn("-----------------(row: %d, col: %d)----\n", row, col);
    warn("Register: %.7f\n", reg);
    for (i = stack->count - 1; i >= 0 ; i--)
      warn("Stack %2d: %.7f\n", i, stack->data[stack->count - i - 1]);
  }
  else {
    warn("Empty Stack\n");
  }
}

/* Execute RPN OPs stack */
void rpn_exec(rpn_context * ctx)
{
  int		elements = ctx->rows * ctx->cols;
  int		i,j,k,r = 0;
  GLfloat	v1,v2;

  for (i=0;i<ctx->rows;i++)
  {
    for (j=0;j<ctx->cols;j++)
    {
      rpn_stack *	stack = ctx->stacks[j];
      int		flow  = RPNF_CONTINUE; /* or 0 */
      rpn_op *		ops;

      /* Skip for NOP columns */
      if (!stack || !stack->ops) continue;
      stack->count = 0;

      /* Push oga data on stack - reverse order */
      for (k=ctx->oga_count-1;k>=0;k--)
        rpn_push(stack,((GLfloat *)ctx->oga_list[k]->data)[r+j]);

      /* Process RPN ops */
      ops = stack->ops;
      while (ops)
      {
        int pos = stack->count - 1;

        switch(ops->op)
        {
          case RPN_PSH:
          {
            //printf("RPN_PSH: %f\n",ops->value);
            rpn_push(stack,ops->value);
            break;
          }
          case RPN_POP:
          {
            //printf("RPN_POP\n");
            rpn_pop(stack);
            break;
          }
          case RPN_CNT:
          {
            //printf("RPN_CNT: %f\n",elements);
            rpn_push(stack,(float)elements);
            break;
          }
          case RPN_IDX:
          {
            //printf("RPN_IDX: %f\n",r+j);
            rpn_push(stack,(float)r+j);
            break;
          }
          case RPN_CLS:
          {
            //printf("RPN_CLS: %f\n",ctx->cols);
            rpn_push(stack,(float)ctx->cols);
            break;
          }
          case RPN_COL:
          {
            //printf("RPN_COL: %f\n",j);
            rpn_push(stack,(float)j);
            break;
          }
          case RPN_RWS:
          {
            //printf("RPN_RWS: %f\n",ctx->rows);
            rpn_push(stack,(float)ctx->rows);
            break;
          }
          case RPN_ROW:
          {
            //printf("RPN_ROW: %f\n",i);
            rpn_push(stack,(float)i);
            break;
          }
          case RPN_SET:
          {
            //printf("RPN_SET %d: %f\n",j,stack->data[pos]);
            ctx->store[j] = stack->data[pos];
            break;
          }
          case RPN_GET:
          {
            //printf("RPN_Get %d: %f\n",j,ctx->store[j]);
            rpn_push(stack,ctx->store[j]);
            break;
          }
          case RPN_STO:
          {
            //printf("RPN_STO row %d\n",r);
            v1 = rpn_pop(stack);
            k = ((int)v1) % ctx->oga_count;
            if (k < 0) k += ctx->oga_count;
            memcpy(ctx->store,&((GLfloat *)ctx->oga_list[k]->data)[r],
              ctx->cols*sizeof(GLfloat));
            break;
          }
          case RPN_CGT:
          {
            //printf("RPN_CGT row %d\n",r);
            int _col = (int)rpn_pop(stack);
            if (_col < 0) _col = 0;
            if (_col > ctx->cols-1) _col = ctx->cols-1;
            rpn_push(stack,(float)((GLfloat *)ctx->oga_list[0]->data)[r+_col]);
            break;
          }
          case RPN_CST:
          {
            //printf("RPN_CST row %d\n",r);
            int _col = (int)rpn_pop(stack);
            if (_col < 0) _col = 0;
            if (_col > ctx->cols-1) _col = ctx->cols-1;
            ((GLfloat *)ctx->oga_list[0]->data)[r+_col] = stack->data[pos > 0 ? pos-1 : 0];
            break;
          }
          case RPN_RGT:
          {
            //printf("RPN_RGT row %d\n",r);
            int _col = (int)rpn_pop(stack);
            int _row = (int)rpn_pop(stack);
            if (_row < 0) _row = 0;
            if (_row > ctx->rows-1) _row = ctx->rows-1;
            if (_col < 0) _col = 0;
            if (_col > ctx->cols-1) _col = ctx->cols-1;
            rpn_push(stack,(float)((GLfloat *)ctx->oga_list[0]->data)[_row*ctx->cols+_col]);
            break;
          }
          case RPN_RST:
          {
            //printf("RPN_RST row %d\n",r);
            int _col = (int)rpn_pop(stack);
            int _row = (int)rpn_pop(stack);
            if (_row < 0) _row = 0;
            if (_row > ctx->rows-1) _row = ctx->rows-1;
            if (_col < 0) _col = 0;
            if (_col > ctx->cols-1) _col = ctx->cols-1;
            ((GLfloat *)ctx->oga_list[0]->data)[_row*ctx->cols+_col] = stack->data[pos > 1 ? pos-2 : 0];
            break;
          }
          case RPN_FLR:
          {
            //printf("RPN_FLR %d: %f\n",j,ctx->store[j]);
            int flr = (int)stack->data[pos];
            stack->data[pos] = (float)flr;
            break;
          }
          case RPN_LOD:
          {
            //printf("RPN_LOD rwo %d\n",r);
            v1 = rpn_pop(stack);
            k = ((int)v1) % ctx->oga_count;
            if (k < 0) k += ctx->oga_count;
            memcpy(&((GLfloat *)ctx->oga_list[k]->data)[r],ctx->store,
              ctx->cols*sizeof(GLfloat));
            break;
          }
          case RPN_TST:
          {
            //printf("RPN_TST\n");
            v1 = rpn_pop(stack);
            if (v1 != 0.0)
            {
              rpn_pop(stack);
            }
            else
            {
              v1 = rpn_pop(stack);
              rpn_pop(stack);
              rpn_push(stack,v1);
            }
            break;
          }
          case RPN_NOT:
          {
            //printf("RPN_NOT\n");
            if (!stack->count)
            {
              rpn_push(stack,1.0);
            }
            else if (stack->data[pos] == 0.0)
            {
              stack->data[pos] = 1.0;
            }
            else
            {
              stack->data[pos] = 0.0;
            }
            break;
          }
          case RPN_EQU:
          {
            //printf("RPN_EQU\n");
            v1 = (stack->count) ? rpn_pop(stack) : (float)0.0;
            v2 = (stack->count) ? rpn_pop(stack) : (float)0.0;
            rpn_push(stack,(float)((v1 == v2) ? 1.0 : 0.0));
            break;
          }
          case RPN_GRE:
          {
            //printf("RPN_GRE\n");
            v1 = (stack->count) ? rpn_pop(stack) : (float)0.0;
            v2 = (stack->count) ? rpn_pop(stack) : (float)0.0;
            rpn_push(stack,(float)((v1 > v2) ? 1.0 : 0.0));
            break;
          }
          case RPN_LES:
          {
            //printf("RPN_LES\n");
            v1 = (stack->count) ? rpn_pop(stack) : (float)0.0;
            v2 = (stack->count) ? rpn_pop(stack) : (float)0.0;
            rpn_push(stack,(float)((v1 < v2) ? 1.0 : 0.0));
            break;
          }
          case RPN_END:
          {
            //printf("RPN_END\n");
            flow = RPNF_END;
            ops = 0;
            continue;
          }
          case RPN_EIF:
          {
            //printf("RPN_EIF\n");
            v1 = rpn_pop(stack);
            if (v1 != 0.0)
            {
              flow = RPNF_END;
              ops = 0;
              continue;
            }
            break;
          }
          case RPN_ERW:
          {
            //printf("RPN_ERW\n");
            flow = RPNF_ENDROW;
            ops = 0;
            continue;
          }
          case RPN_ERI:
          {
            //printf("RPN_ERI\n");
            v1 = rpn_pop(stack);
            if (v1 != 0.0)
            {
              flow = RPNF_ENDROW;
              ops = 0;
              continue;
            }
            break;
          }
          case RPN_RET:
          {
            //printf("RPN_RET\n");
            flow = RPNF_RETURN;
            ops = 0;
            continue;
          }
          case RPN_RIF:
          {
            //printf("RPN_RIF\n");
            v1 = rpn_pop(stack);
            if (v1 != 0.0)
            {
              flow = RPNF_RETURN;
              ops = 0;
              continue;
            }
            break;
          }
          case RPN_RRW:
          {
            //printf("RPN_RRW\n");
            flow = RPNF_RETURNROW;
            ops = 0;
            continue;
          }
          case RPN_RRI:
          {
            //printf("RPN_RRI\n");
            v1 = rpn_pop(stack);
            if (v1 != 0.0)
            {
              flow = RPNF_RETURNROW;
              ops = 0;
              continue;
            }
            break;
          }
          case RPN_RND:
          {
            //printf("RPN_RND\n");
            rpn_push(stack,(float)(1.0*rand()/RAND_MAX));
            break;
          }
          case RPN_DUP:
          {
            //printf("RPN_DUP\n");
            rpn_push(stack,stack->data[pos]);
            break;
          }
          case RPN_SWP:
          {
            //printf("RPN_SWP\n");
            if (pos >= 1)
            {
              v1 = stack->data[pos-1];
              stack->data[pos-1] = stack->data[pos];
              stack->data[pos] = v1;
            }
            break;
          }
          case RPN_ABS:
          {
            //printf("RPN_ABS\n");
            stack->data[pos] = (float)fabs(stack->data[pos]);
            break;
          }
          case RPN_NEG:
          {
            //printf("RPN_NEG\n");
            stack->data[pos] *= (float)-1.0;
            break;
          }
          case RPN_INC:
          {
            //printf("RPN_INC\n");
            stack->data[pos] += (float)1.0;
            break;
          }
          case RPN_DEC:
          {
            //printf("RPN_DEC\n");
            stack->data[pos] -= (float)1.0;
            break;
          }
          case RPN_AVG:
          case RPN_SUM:
          {
            //printf("RPN_SUM/AVG\n");
            v1 = 0;

            for(pos=0; pos<stack->count; pos++)
              v1 += stack->data[pos];

            if (ops->op == RPN_AVG) v1 /= stack->count;

            stack->data[0] = v1;
            stack->count = 1;
            break;
          }
          case RPN_ADD:
          {
            //printf("RPN_ADD\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              stack->data[--pos] += v1;
            }
            break;
          }
          case RPN_MUL:
          {
            //printf("RPN_MUL\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              stack->data[--pos] *= v1;
            }
            break;
          }
          case RPN_DIV:
          {
            //printf("RPN_DIV\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              if (v1 != 0.0) stack->data[--pos] /= v1;
            }
            break;
          }
          case RPN_POW:
          {
            //printf("RPN_POW\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              pos--;
              stack->data[pos] = (float)pow(stack->data[pos],v1);
            }
            break;
          }
          case RPN_MOD:
          {
            //printf("RPN_MOD\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              pos--;
              stack->data[pos] = (float)fmod(stack->data[pos],v1);
            }
            break;
          }
          case RPN_MIN:
          {
            //printf("RPN_MIN\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              if (stack->data[--pos] > v1)
                stack->data[pos] = v1;
            }
            break;
          }
          case RPN_MAX:
          {
            //printf("RPN_MAX\n");
            if (stack->count > 1)
            {
              v1 = rpn_pop(stack);
              if (stack->data[--pos] < v1)
                stack->data[pos] = v1;
            }
            break;
          }
          case RPN_SIN:
          {
            //printf("RPN_SIN\n");
            stack->data[pos] = (float)sin(stack->data[pos]);
            break;
          }
          case RPN_COS:
          {
            //printf("RPN_COS\n");
            stack->data[pos] = (float)cos(stack->data[pos]);
            break;
          }
          case RPN_TAN:
          {
            //printf("RPN_TAN\n");
            stack->data[pos] = (float)tan(stack->data[pos]);
            break;
          }
          case RPN_AT2:
          {
            //printf("RPN_AT2\n");
            v2 = rpn_pop(stack);
            v1 = rpn_pop(stack);
            if (v1 != 0.0 || v2 != 0.0)
              rpn_push(stack,(float)atan2(v1,v2));
            break;
          }
          case RPN_DMP:
          {
            //printf("RPN_DMP\n");
            rpn_dump(stack, i, j, ctx->store[j]);
            break;
          }
          case RPN_NOP:
          {
            //printf("RPN_NOP\n");
            break;
          }
          default:
          {
            croak("Unknown RPN op: %d\n",ops->op);
          }
        }

        ops = ops->next;
      }
      if (!flow) { /* RPNF_CONTINUE */
        ((GLfloat *)ctx->oga_list[0]->data)[r+j] = rpn_pop(stack);
      }
      else {
        switch(flow)
        {
          case RPNF_RETURN:
          {
            ((GLfloat *)ctx->oga_list[0]->data)[r+j] = rpn_pop(stack);
            break;
          }
          case RPNF_RETURNROW:
          {
            ((GLfloat *)ctx->oga_list[0]->data)[r+j] = rpn_pop(stack);
            j = ctx->cols;
            break;
          }
          case RPNF_ENDROW:
          {
            j = ctx->cols;
            break;
          }
        }
      }
    }
    r += ctx->cols;
  }
}


MODULE = OpenGL::Array		PACKAGE = OpenGL::Array


#//# $oga = OpenGL::Array->new($count, @types);
#//- Constructor for multi-type OGA - unpopulated
OpenGL::Array
new(Class, count, type, ...)
	GLsizei	count
	GLenum	type
	CODE:
	{
		int oga_len = sizeof(oga_struct);
		oga_struct * oga = malloc(oga_len);
		int i,j;

		memset(oga,0,oga_len);

		oga->dimension_count = 1;
		oga->dimensions[0] = count;
		
		oga->type_count = items - 2;
		oga->item_count = count * (items - 2);
		
		oga->types = malloc(sizeof(GLenum) * oga->type_count);
		oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
		for(i=0,j=0;i<oga->type_count;i++) {
			oga->types[i] = SvIV(ST(i+2));
			oga->type_offset[i] = j;
			j += gl_type_size(oga->types[i]);
		}
		oga->total_types_width = j;
		
		oga->data_length = oga->total_types_width *
			// ((count + oga->type_count-1) / oga->type_count); # vas is das?
			count;
		
		oga->data = malloc(oga->data_length);
		memset(oga->data,0,oga->data_length);

		oga->free_data = 1;
		
		RETVAL = oga;
	}
	OUTPUT:
		RETVAL



#//# $oga = OpenGL::Array->new_list($type, @data);
#//- Constructor for mono-type OGA - populated
OpenGL::Array
new_list(Class, type, ...)
	GLenum	type
	CODE:
	{
		int oga_len = sizeof(oga_struct);
		oga_struct * oga = malloc(oga_len);
		int count = items - 2;

		memset(oga,0,oga_len);

		oga->dimension_count = 1;
		oga->dimensions[0] = count;

		oga->type_count = 1;
		oga->item_count = count;
		oga->total_types_width = gl_type_size(type);
		oga->data_length = oga->total_types_width * oga->item_count;
		
		oga->types = malloc(sizeof(GLenum) * oga->type_count);
		oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
		oga->data = malloc(oga->data_length);
		oga->free_data = 1;

		oga->type_offset[0] = 0;
		oga->types[0] = type;

		SvItems(type,2,(GLuint)oga->item_count,oga->data);
		
		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# $oga = OpenGL::Array->new_scalar($type, (PACKED)data, $length);
#//- Constructor for mono-type OGA - populated by string
OpenGL::Array
new_scalar(Class, type, data, length)
	GLenum	type
	SV *	data
        GLsizei	length
	CODE:
	{
		int width = gl_type_size(type);
		void * data_s = EL(data, width*length);
		int oga_len = sizeof(oga_struct);
		oga_struct * oga = malloc(oga_len);
		int count = length / width;

		memset(oga,0,oga_len);

		oga->dimension_count = 1;
		oga->dimensions[0] = count;

		oga->type_count = 1;
		oga->item_count = count;
		oga->total_types_width = width;
		oga->data_length = length;
		
		oga->types = malloc(sizeof(GLenum) * oga->type_count);
		oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
		oga->data = malloc(oga->data_length);
		oga->free_data = 1;

		oga->type_offset[0] = 0;
		oga->types[0] = type;

		memcpy(oga->data,data_s,oga->data_length);
		
		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# $oga = OpenGL::Array->new_pointer($type, (CPTR)ptr, $elements);
#//- Constructor for mono-type OGA wrapper over a C pointer
OpenGL::Array
new_pointer(Class, type, ptr, elements)
	GLenum	type
	void *	ptr
	GLsizei	elements
	CODE:
	{
		int width = gl_type_size(type);
		int oga_len = sizeof(oga_struct);
		oga_struct * oga = malloc(sizeof(oga_struct));

		memset(oga,0,oga_len);

		oga->dimension_count = 1;
		oga->dimensions[0] = elements;
		
		oga->type_count = 1;
		oga->item_count = elements;
		
		oga->types = malloc(sizeof(GLenum) * oga->type_count);
		oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
		oga->types[0] = type;
		oga->type_offset[0] = 0;
		oga->total_types_width = width;
		
		oga->data_length = elements * width;
		
		oga->data = ptr;
		oga->free_data = 0;
		
		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# $oga = OpenGL::Array->new_from_pointer((CPTR)ptr, $length);
#//- Constructor for GLubyte OGA wrapper over a C pointer
OpenGL::Array
new_from_pointer(Class, ptr, length)
	void *	ptr
	GLsizei	length
	CODE:
	{
		int oga_len = sizeof(oga_struct);
		oga_struct * oga = malloc(sizeof(oga_struct));

		memset(oga,0,oga_len);

		oga->dimension_count = 1;
		oga->dimensions[0] = length;
		
		oga->type_count = 1;
		oga->item_count = length;
		
		oga->types = malloc(sizeof(GLenum) * oga->type_count);
		oga->type_offset = malloc(sizeof(GLint) * oga->type_count);
		oga->types[0] = GL_UNSIGNED_BYTE;
		oga->type_offset[0] = 0;
		oga->total_types_width = 1;
		
		oga->data_length = oga->item_count;
		
		oga->data = ptr;
		oga->free_data = 0;
		
		RETVAL = oga;
	}
	OUTPUT:
		RETVAL

#//# $oga->update_pointer((CPTR)ptr);
#//- Replace OGA's C pointer - old one is not released
GLboolean
update_pointer(oga, ptr)
	OpenGL::Array oga
	void *	ptr
	CODE:
	{
        RETVAL = (oga->data != ptr);
		oga->data = ptr;
	}
	OUTPUT:
		RETVAL

#//# $oga->bind($vboID);
#//- Bind a VBO to an OGA
void
bind(oga, bind)
	OpenGL::Array oga
	GLint	bind
	INIT:
#ifdef GL_ARB_vertex_buffer_object
		loadProc(glBindBufferARB,"glBindBufferARB");
#endif
	CODE:
	{
#ifdef GL_ARB_vertex_buffer_object
		oga->bind = bind;
		glBindBufferARB(GL_ARRAY_BUFFER_ARB,bind);
#else
		croak("OpenGL::Array::bind requires GL_ARB_vertex_buffer_object");
#endif
	}

#//# $vboID = $oga->bound();
#//- Return OGA's bound VBO ID
GLint
bound(oga)
	OpenGL::Array oga
	CODE:
		RETVAL = oga->bind;
	OUTPUT:
		RETVAL

#//# $oga->calc([@(OGA)moreOGAs,]@rpnOPs);
#//- Execute RPN instructions on one or more OGAs
void
calc(...)
	CODE:
	{
		rpn_context *	ctx;
		oga_struct **	oga_list;
		int		oga_count = 0;
		int		ops_count,i;
		char **		ops;

		/* Determine number of OGAs passed in */
		for (i=0; i<items; i++)
		{
			SV *	sv = ST(i);
			if (sv == &PL_sv_undef ||
				!sv_derived_from(sv,"OpenGL::Array")) break;
			oga_count++;
		}

		/* Grab OGA data buffers */
		if (!oga_count) croak("Missing OGA parameters");
		ops_count = items - oga_count;

		oga_list = malloc(sizeof(oga_struct *) * oga_count);
		if (!oga_list) croak("Unable to alloc oga_list");

		for (i=0; i<oga_count; i++)
		{
			IV ref = SvIV((SV*)SvRV(ST(i)));
			oga_list[i] = INT2PTR(OpenGL__Array,ref);
		}

		ops = malloc(sizeof(char *) * ops_count);
		if (!ops) croak("Unable to alloc ops");

		/* Parse parameters */
		for (i=0;i<ops_count;i++)
		{
			SV *	sv = ST(i+oga_count);
			char *	op = (sv != &PL_sv_undef) ?
				(char *)SvPV(sv,PL_na) : "";
			ops[i] = op;
		}

		/* Instantiate RPN context */
		ctx = rpn_init(oga_count,oga_list,ops_count,ops);
		rpn_exec(ctx);
		rpn_term(ctx);

		/* Delete lists */
		free(ops);
		free(oga_list);
	}

#//# $oga->assign($pos,@data);
#//- Set OGA values starting from offset
void
assign(oga, pos, ...)
	OpenGL::Array oga
	GLint	pos
	CODE:
	{
		int i,j;
		int end;
		GLenum t;
		char* offset;
		
		i = pos;
		end = i + items - 2;
		
		if (end > oga->item_count)
			end = oga->item_count;
		/* FIXME: is this char* conversion what is intended? */
		offset = ((char*)oga->data) +
			(pos / oga->type_count * oga->total_types_width) + 
			oga->type_offset[pos % oga->type_count];
		
		j = 2;

		/* Handle multi-type OGAs */		
		for (;i<end;i++,j++) {
			t = oga->types[i % oga->type_count];
			switch (t) {
#ifdef GL_VERSION_1_2
			case GL_UNSIGNED_BYTE_3_3_2:
			case GL_UNSIGNED_BYTE_2_3_3_REV:
				(*(GLubyte*)offset) = (GLubyte)SvIV(ST(j));
				offset += sizeof(GLubyte);
				break;
			case GL_UNSIGNED_SHORT_5_6_5:
			case GL_UNSIGNED_SHORT_5_6_5_REV:
			case GL_UNSIGNED_SHORT_4_4_4_4:
			case GL_UNSIGNED_SHORT_4_4_4_4_REV:
			case GL_UNSIGNED_SHORT_5_5_5_1:
			case GL_UNSIGNED_SHORT_1_5_5_5_REV:
				(*(GLushort*)offset) = (GLushort)SvIV(ST(j));
				offset += sizeof(GLushort);
				break;
			case GL_UNSIGNED_INT_8_8_8_8:
			case GL_UNSIGNED_INT_8_8_8_8_REV:
			case GL_UNSIGNED_INT_10_10_10_2:
			case GL_UNSIGNED_INT_2_10_10_10_REV:
				(*(GLuint*)offset) = (GLuint)SvIV(ST(j));
				offset += sizeof(GLuint);
				break;
#endif
			case GL_UNSIGNED_BYTE:
			case GL_BITMAP:
				(*(GLubyte*)offset) = (GLubyte)SvIV(ST(j));
				offset += sizeof(GLubyte);
				break;
			case GL_BYTE:
				(*(GLbyte*)offset) = (GLbyte)SvIV(ST(j));
				offset += sizeof(GLbyte);
				break;
			case GL_UNSIGNED_SHORT:
				(*(GLushort*)offset) = (GLushort)SvIV(ST(j));
				offset += sizeof(GLushort);
				break;
			case GL_SHORT:
				(*(GLshort*)offset) = (GLshort)SvIV(ST(j));
				offset += sizeof(GLshort);
				break;
			case GL_UNSIGNED_INT:
				(*(GLuint*)offset) = (GLuint)SvIV(ST(j));
				offset += sizeof(GLuint);
				break;
			case GL_INT:
				(*(GLint*)offset) = (GLint)SvIV(ST(j));
				offset += sizeof(GLint);
				break;
			case GL_FLOAT: 
				(*(GLfloat*)offset) = (GLfloat)SvNV(ST(j));
				offset += sizeof(GLfloat);
				break;
			case GL_DOUBLE: 
				(*(GLdouble*)offset) = (GLdouble)SvNV(ST(j));
				offset += sizeof(GLdouble);
				break;
			case GL_2_BYTES:
			{
				unsigned long v = (unsigned long)SvIV(ST(j));
				(*(GLubyte*)offset) = (GLubyte)(v >> 8);
				offset++;
				(*(GLubyte*)offset) = (GLubyte)v & 0xff;
				offset++;
				break;
			}
			case GL_3_BYTES:
			{
				unsigned long v = (unsigned long)SvIV(ST(j));
				(*(GLubyte*)offset) = (GLubyte)(v >> 16)& 0xff;
				offset++;
				(*(GLubyte*)offset) = (GLubyte)(v >> 8) & 0xff;
				offset++;
				(*(GLubyte*)offset) = (GLubyte)(v >> 0) & 0xff;
				offset++;
				break;
			}
			case GL_4_BYTES:
			{
				unsigned long v = (unsigned long)SvIV(ST(j));
				(*(GLubyte*)offset) = (GLubyte)(v >> 24)& 0xff;
				offset++;
				(*(GLubyte*)offset) = (GLubyte)(v >> 16)& 0xff;
				offset++;
				(*(GLubyte*)offset) = (GLubyte)(v >> 8) & 0xff;
				offset++;
				(*(GLubyte*)offset) = (GLubyte)(v >> 0) & 0xff;
				offset++;
				break;
			}
			default:
				croak("unknown type");
			}
		}
	}

#//# $oga->assign_data($pos,(PACKED)data);
#//- Set OGA values by string, starting from offset
void
assign_data(oga, pos, data)
	OpenGL::Array	oga
	GLint	pos
	SV *	data
	CODE:
	{
		void * offset;
		void * src;
		STRLEN len;
		
		offset = ((char*)oga->data) +
			(pos / oga->type_count * oga->total_types_width) + 
			oga->type_offset[pos % oga->type_count];
		
		src = SvPV(data, len);
		
		memcpy(offset, src, len);
	}

#//# @data = $oga->retrieve($pos,$len);
#//- Get OGA data array, by offset and length
void
retrieve(oga, ...)	
	OpenGL::Array	oga
	PPCODE:
	{
		GLint	pos = (items > 1) ? SvIV(ST(1)) : 0;
		GLint	len = (items > 2) ? SvIV(ST(2)) : (oga->item_count - pos);
		char * offset;
		int end = pos + len;
		int i;

		offset = ((char*)oga->data) +
			(pos / oga->type_count * oga->total_types_width) + 
			oga->type_offset[pos % oga->type_count];
		
		if (end > oga->item_count)
			end = oga->item_count;
		
		EXTEND(sp, end-pos);
		
		i = pos;
		
		for (;i<end;i++) {
			GLenum t = oga->types[i % oga->type_count];
			switch (t) {
#ifdef GL_VERSION_1_2
			case GL_UNSIGNED_BYTE_3_3_2:
			case GL_UNSIGNED_BYTE_2_3_3_REV:
				PUSHs(sv_2mortal(newSViv( (*(GLubyte*)offset) )));
				offset += sizeof(GLubyte);
				break;
			case GL_UNSIGNED_SHORT_5_6_5:
			case GL_UNSIGNED_SHORT_5_6_5_REV:
			case GL_UNSIGNED_SHORT_4_4_4_4:
			case GL_UNSIGNED_SHORT_4_4_4_4_REV:
			case GL_UNSIGNED_SHORT_5_5_5_1:
			case GL_UNSIGNED_SHORT_1_5_5_5_REV:
				PUSHs(sv_2mortal(newSViv( (*(GLushort*)offset) )));
				offset += sizeof(GLushort);
				break;
			case GL_UNSIGNED_INT_8_8_8_8:
			case GL_UNSIGNED_INT_8_8_8_8_REV:
			case GL_UNSIGNED_INT_10_10_10_2:
			case GL_UNSIGNED_INT_2_10_10_10_REV:
				PUSHs(sv_2mortal(newSViv( (*(GLuint*)offset) )));
				offset += sizeof(GLuint);
				break;
#endif
			case GL_UNSIGNED_BYTE:
			case GL_BITMAP:
				PUSHs(sv_2mortal(newSViv( (*(GLubyte*)offset) )));
				offset += sizeof(GLubyte);
				break;
			case GL_BYTE:
				PUSHs(sv_2mortal(newSViv( (*(GLbyte*)offset) )));
				offset += sizeof(GLbyte);
				break;
			case GL_UNSIGNED_SHORT:
				PUSHs(sv_2mortal(newSViv( (*(GLushort*)offset) )));
				offset += sizeof(GLushort);
				break;
			case GL_SHORT:
				PUSHs(sv_2mortal(newSViv( (*(GLshort*)offset) )));
				offset += sizeof(GLshort);
				break;
			case GL_UNSIGNED_INT:
				PUSHs(sv_2mortal(newSViv( (*(GLuint*)offset) )));
				offset += sizeof(GLuint);
				break;
			case GL_INT:
				PUSHs(sv_2mortal(newSViv( (*(GLint*)offset) )));
				offset += sizeof(GLint);
				break;
			case GL_FLOAT: 
				PUSHs(sv_2mortal(newSVnv( (*(GLfloat*)offset) )));
				offset += sizeof(GLfloat);
				break;
			case GL_DOUBLE: 
				PUSHs(sv_2mortal(newSVnv( (*(GLdouble*)offset) )));
				offset += sizeof(GLdouble);
				break;
			case GL_2_BYTES:
			case GL_3_BYTES:
			case GL_4_BYTES:
			default:
				croak("unknown type");
			}
		}
	}

#//# $data = $oga->retrieve_data($pos,$len);
#//- Get OGA data as packed string, by offset and length
SV *
retrieve_data(oga, ...)
	OpenGL::Array	oga
	CODE:
	{
		GLint	pos = (items > 1) ? SvIV(ST(1)) : 0;
		GLint	len = (items > 2) ? SvIV(ST(2)) : (oga->item_count - pos);
		void * offset;
		
		offset = ((char*)oga->data) +
			(pos / oga->type_count * oga->total_types_width) + 
			oga->type_offset[pos % oga->type_count];

		RETVAL = newSVpv((char*)offset, len);
	}
	OUTPUT:
	    RETVAL

#//# $count = $oga->elements();
#//- Get number of OGA elements
GLsizei
elements(oga)
	OpenGL::Array	oga
	CODE:
		RETVAL = oga->item_count;
	OUTPUT:
		RETVAL

#//# $len = $oga->length();
#//- Get size of OGA in bytes
GLsizei
length(oga)
	OpenGL::Array	oga
	CODE:
		RETVAL = oga->data_length;
	OUTPUT:
		RETVAL

#//# (CPTR)ptr = $oga->ptr();
#//- Get C pointer to OGA data
void *
ptr(oga)
	OpenGL::Array	oga
	CODE:
	    RETVAL = oga->data;
	OUTPUT:
	    RETVAL

#//# (CPTR)ptr = $oga->offset($pos);
#//- Get C pointer to OGA data, by element offset
void *
offset(oga, pos)
	OpenGL::Array	oga
	GLint	pos
	CODE:
	    RETVAL = ((char*)oga->data) +
		(pos / oga->type_count * oga->total_types_width) + 
		oga->type_offset[pos % oga->type_count];
	OUTPUT:
	    RETVAL

#//# $oga->affine((OGA)matrix|@matrix|$scalar);
#//- Perform affine transform on an OGA
void
affine(oga, ...)
	OpenGL::Array oga
	CODE:
	{
		GLfloat *	data = (GLfloat *)oga->data;
		GLfloat *	mat = NULL;
		int		len = oga->item_count;
		int		fbo_width = 0;
		int		i,j,count,dim,cols;
		SV *		sv = ST(1);
		int		free_mat = 0;

		/* Get transform matrix OGA */
		if (sv != &PL_sv_undef && sv_derived_from(sv,"OpenGL::Array"))
		{
			IV ref = SvIV((SV*)SvRV(sv));
			oga_struct *oga_mat = INT2PTR(OpenGL__Array,ref);
			count = oga_mat->item_count;

			for (i=0;i<oga_mat->type_count;i++)
			{
				if (oga_mat->types[i] != GL_FLOAT)
					croak("Unsupported datatype in affine matrix");
			}

			mat = (GLfloat *)oga_mat->data;
		}
		else
		{
			count = items - 1;
			free_mat = 1;
		}
		if (!count) croak("No matrix values");

		/* Currently only support GLfloat */
		for (i=0;i<oga->type_count;i++)
		{
			if (oga->types[i] != GL_FLOAT)
				croak("Unsupported datatype");
		}

		/* Scalar Multiply */
		if (count == 1)
		{
			GLfloat scalar = mat ? mat[0] : (GLfloat)SvNV(ST(1));
			for (i=0;i<len;i++) data[i] *= scalar;
			XSRETURN_EMPTY;
		}

		/* Calc matrix dimension from sqrt of array size */
		dim = (int)sqrt(count);
		if (count != dim*dim) croak("Not a square matrix");

		/* Affine matrix dimension is one element larger than vector data */
		cols = dim - 1;
		if (len % cols)
			croak("Matrix does not match array vector size");

		/* Grab affine matrix */
		if (!mat)
		{
			mat = malloc(sizeof(GLfloat) * count);
			for (i=0; i<count; i++)
				mat[i] = (GLfloat)SvNV(ST(i+1));
		}
#if 0 /* Need to figure out why this is slower than CPU calcs */ 
		/* Use GPU if FBOs and Fragment Programs are supported */
		fbo_width = gpgpu_width(len);
		if (dim == 4 && fbo_width)
		{
			GLuint target = GL_TEXTURE_RECTANGLE_ARB;
			int w = fbo_width;
			int h = len / (w*3);

			/* Setup and enable FBO */
			enable_fbo(oga,w,h,target,GL_RGB32F_ARB,GL_RGB,GL_FLOAT);

			/* Pass affine matrix to shader */
			enable_affine(oga);
			for (i=0;i<4;i++)
			{
				glProgramLocalParameter4fvARB(GL_FRAGMENT_PROGRAM_ARB,
					i,&mat[i<<2]);
			}

			/* Render to FBO via fragment shader */
			glBegin(GL_QUADS);
			{
				glTexCoord2i(0,0); glVertex2i(0,0);
				glTexCoord2i(w,0); glVertex2i(w,0);
				glTexCoord2i(w,h); glVertex2i(w,h);
				glTexCoord2i(0,h); glVertex2i(0,h);
			}
			glEnd();

			/* Done rendering */
			disable_affine(oga);

			/* Save back to OGA */
			//glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);
			glReadPixels(0,0,w,h,GL_RGB,GL_FLOAT,oga->data);

			disable_fbo(oga);
		}
		/* Use CPU to do transform */
		else
#endif
		{
			int s = sizeof(GLfloat) * cols;
			GLfloat *vec = malloc(s);
			int k,r;

			/* Iterate each data row */
			for (i=0; i < len; i+=cols)
			{
				/* Iterate each result column */
				for (j=0,r=0; j<cols; j++,r+=dim)
				{
					vec[j] = 0.0;

					/* Iterate each matrix column */
					for (k=0; k<cols; k++)
					{
						vec[j] += data[i+k] * mat[r+k];
					}
					/* Matrix translate column */
					vec[j] += mat[r+cols];
				}

				memcpy(data+i,vec,s);
			}

			free(vec);
		}

		if (free_mat) free(mat);
	}


#//# @dimensions = $oga->get_dimensions();
#//- Get OGA data array, by offset and length
void
get_dimensions(oga)
	OpenGL::Array	oga
	PPCODE:
	{
		int end = oga->dimension_count;
		int i = 0;

		EXTEND(sp, end);

		for (;i<end;i++) {
		    PUSHs(sv_2mortal(newSViv( oga->dimensions[i] )));
		}
	}


#// OGA Destructor
void
DESTROY(oga)
	OpenGL::Array	oga
	CODE:
	{
#if 0  /* Cleanup for GPU-based affine calcs */
#ifdef GL_ARB_fragment_program
		if (oga->affine_handle)
		{
			glBindProgramARB(GL_FRAGMENT_PROGRAM_ARB, 0);
			glDeleteProgramsARB(1,&oga->affine_handle);
		}
#endif
#ifdef GL_EXT_framebuffer_object
		release_fbo(oga);
#endif
#endif
#if 0
#ifdef GL_ARB_vertex_buffer_object
		if (oga->bind)
		{
			glBindBufferARB(GL_ARRAY_BUFFER_ARB,0);
			glDeleteBuffersARB(1,&oga->bind);
		}
#endif
#endif
		if (oga->free_data)
		{
			/* To make sure dangling pointers will be obvious */
			memset(oga->data, '\0', oga->data_length);
			free(oga->data);
		}
	
		free(oga->types);
		free(oga->type_offset);
		free(oga);
	}

BOOT:
  PGOPOGL_CALL_BOOT(boot_OpenGL__Matrix);

