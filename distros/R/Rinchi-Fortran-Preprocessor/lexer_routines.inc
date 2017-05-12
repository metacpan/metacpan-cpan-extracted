/*
 *
 */
void initialize_lexer(char *filename) {
  struct stat st;
  int res;

  include_stack_ptr = 0;
  file_stack_ptr = 0;
  curfilenode = newNodeFile(preprocessing_file_index);
  filenode[file_stack_ptr] = curfilenode;
  curfilenode->lines = 1;
  curfilenode->path = strdup(filename);
  res = stat(filename, &st);
  if (res == 0) {
    curfilenode->atime = st.st_atime;
    if (st.st_atime > max_st_atime) {
      max_st_atime = st.st_atime;
    }
    curfilenode->mtime = st.st_mtime;
    if (st.st_mtime > max_st_mtime) {
      max_st_mtime = st.st_mtime;
    }
  }

  repl_id[0] = NULL;
  line_buf = (char *) malloc(MAX_LINE_LENGTH);
  memset(line_buf,0,MAX_LINE_LENGTH);
}

/*
 *
 */
void handle_include_file() {
  int i,j,len;
  char *path;
  char *filename;
  int result;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s %s\n",__func__,include_file_name);
  }
//  filename = filenames[file_stack_ptr];
  filename = curfilenode->path;
  
  i = strlen(filename)-1;
  while (i >=0 && filename[i] != '/' && filename[i] != '\\') i--;
  i++;
  
  len=strlen(include_file_name)+i+1;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s %s %d %d\n",filename,include_file_name,i,len);
  }
  path = (char *) malloc(len);
  for (j=i--; i >=0; i-- ) path[i] = filename[i];
  for (i=0; include_file_name[i] >0; i++, j++ ) path[j] = include_file_name[i];
  path[j] = 0;
  result = include_file(path);
  if (result != 0) {
    handle_file_begin(preprocessing_file_index);
  }
}

/*
 *
 */
FILE *open_include_file(char *path) {
  struct stat st;
  int res;
  FILE *file;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) start\n",__func__,path);
  }
  file = fopen(path, "r" );
  if ( file ) {
    include_stack[include_stack_ptr++] = YY_CURRENT_BUFFER;
    yy_switch_to_buffer(yy_create_buffer( yyin, YY_BUF_SIZE ) );
    file_stack_ptr++;
    curfilenode = newNodeFile(preprocessing_file_index);
    filenode[file_stack_ptr] = curfilenode;
    curfilenode->lines = 1;
    curfilenode->path = strdup(path);

    buffer_type[include_stack_ptr] = BUFFER_TYPE_FILE;
    res = stat(path, &st);
    if (res == 0) {
      curfilenode->atime = st.st_atime;
      if (st.st_atime > max_st_atime) {
        max_st_atime = st.st_atime;
      }
      curfilenode->mtime = st.st_mtime;
      if (st.st_mtime > max_st_mtime) {
        max_st_mtime = st.st_mtime;
      }
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) end\n",__func__,path);
  }
  return file;
}

/*
 *
 */
int include_file(char *path) {
  static FILE *file;
  int result = 0;
  char *inc_path = 0;
  char buf[256];
  char *fnm;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) start\n",__func__,path);
  }
  if ( include_stack_ptr >= MAX_INCLUDE_DEPTH ) {
    fprintf( stderr, "Includes nested too deeply %s\n",path );
    return 0;
  } else {

    file = open_include_file(path);
    if ( file ) {
      yyin = file;
      add_dependency(include_file_name);
      result = 1;
    } else {
      goto_incl_first();
      while ((inc_path = get_incl_path()) != NULL) {
        sprintf(buf,"%s/%s",inc_path,include_file_name);
        fnm = strdup(buf);
        file = open_include_file(fnm);
        if ( file ) {
          yyin = file;
          add_dependency(strdup(fnm));
          incl_path_used();
          return 1;
        }
        free(fnm);
        goto_incl_next();
      }
      fprintf( stderr, "Error: open failed for include file %s\n",path );
      add_dependency(include_file_name);
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) end\n",__func__,path);
  }
  return result;
}

/*
 *
 */
int not_a_macro() {
  int result,tr;
  char *repl;
  result = 0;
  tr = test_identifier();
  switch (tr) {
  case 1:
//    include_string("",BUFFER_TYPE_RESCAN);
    break;
  case 2:
    repl = get_replacement_string();
//    repl = get_function_replacement_string();
    if (repl != NULL) {
      include_string(repl,BUFFER_TYPE_RESCAN);
    } else {
      result = 1;
    }
    break;
  case 3:
    break;
  case 4:
    paren_level = 0;
    yy_push_state(X_MACRO_INV);
    break;
  default:
    result = 1;
    break;
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() = %d;\n",__func__,result);
  }

  return result;
}

/*
 *
 */
int not_an_object_macro() {
  int result,tr;
  char *repl;
  result = 0;
  tr = test_identifier();
  switch (tr) {
  case 1:
//    include_string("",BUFFER_TYPE_RESCAN);
    break;
  case 2:
    repl = get_replacement_string();
//    repl = get_function_replacement_string();
    if (repl != NULL) {
      include_string(repl,BUFFER_TYPE_RESCAN);
    } else {
      result = 1;
    }
    break;
  case 3:
  case 4:
  default:
    result = 1;
    break;
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() = %d;\n",__func__,result);
  }

  return result;
}

/*
 *
 */
void do_replacement() {
  char *repl;

  repl = get_replacement_string();
//  repl = get_function_replacement_string();
  fprintf(stderr,"%s() = \"%s\";\n",__func__,repl);
  if (repl != NULL) {
    include_string(repl,BUFFER_TYPE_RESCAN);
  }
}

/*
 *
 */
char *getCurrentFilename() {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d);\n",__func__,file_stack_ptr);
  }
//  return filenames[file_stack_ptr];
  return curfilenode->path;
}

/*
 *
 */
int getCurrentLineNumber() {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d);\n",__func__,file_stack_ptr);
  }
//  return line_counts[file_stack_ptr];
  if(curfilenode != NULL) {
    return curfilenode->lines;
  }
  return -1;
}

/*
 *
 */
void pp_number_init(char first, char second) {

  switch (first) {
  case '0':
    if (second == 'X' || second == 'x') {
      isHex = 1; 
      isOct = 0;
    } else {
      isHex = 0; 
      isOct = 1;
    }
    isDec = 0;
    isFloat = 1;
    periods = 0;
    break;
  case '.':
    isHex = 0;
    isDec = 0;
    isOct = 0;
    isFloat = 1;
    periods = 1;
    break;
  default:
    isHex = 0;
    isDec = 1;
    isOct = 0;
    isFloat = 1;
    periods = 0;
    break;
  }
  f_suffix = 0;
  l_suffix = 0;
  u_suffix = 0;
}

/*
 *
 */
void pp_not_a_literal() {
//  fprintf(stderr,"pp_not_a_literal()\n");
  isHex = 0;
  isDec = 0;
  isOct = 0;
  isFloat = 0;
}

/*
 *
 */
void pp_octal_digit() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
}

/*
 *
 */
void pp_decimal_digit() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
  isOct = 0;
}

/*
 *
 */
void pp_hexadecimal_digit() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
  isDec = 0;
  isOct = 0;
  isFloat = 0;
}

/*
 *
 */
void pp_l_suffix() {
  if(l_suffix != 0) {
    pp_not_a_literal();
  }
  if(f_suffix != 0) {
    isFloat = 0;
  }
  l_suffix = 1;
}

/*
 *
 */
void pp_f_suffix() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
  isDec = 0;
  isOct = 0;
  f_suffix++;
}

/*
 *
 */
void pp_u_suffix() {
  if(u_suffix != 0) {
    pp_not_a_literal();
  }
  isFloat = 0;
  u_suffix = 1;
}

/*
 *
 */
void pp_exponent(char second) {
  if (second == '+' || second == '-') isHex =  0;
  isDec = 0;
  isOct = 0;
  periods = 0;
}

/*
 *
 */
void pp_period() {
  if(periods != 0) {
    pp_not_a_literal();
  }
  isHex = 0;
  isDec = 0;
  isOct = 0;
  periods = 1;
}

/*
 *
 */
int test_pp_number() {
  if (isOct) {
    yypp_lval.lval = get_value_octal();
    return OCTAL_LITERAL;
  }
  if (isDec) {
    yypp_lval.lval = get_value_decimal();
    return DECIMAL_LITERAL;
  }
  if (isHex) {
    yypp_lval.lval = get_value_hexadecimal();
    return HEXADECIMAL_LITERAL;
  }
  if(f_suffix > 1) {
    isFloat = 0;
  }
  if (isFloat) {
    return FLOATING_LITERAL;
  }
  return PP_NUMBER;
}

/*
 *
 */
void end_of_line() {
  static char *ln;
  int matched;

  matched = use_on_code_matched();
  if (yypp_debug != 0) {
    fprintf(stderr,"matched: %d, line %d %s: \"%s\"\n",matched,curfilenode->lines,curfilenode->path,line_buf);
  }
  line_buf[line_buf_ptr++] = '\n';
  if (matched != 0) {
    handle_location();
//    line_counts[file_stack_ptr]++;
    curfilenode->lines++;
    yy_pop_state();
    ln = strdup(line_buf);
    include_string(ln,BUFFER_TYPE_LINE);
  }
  line_buf_ptr=0;
  memset(line_buf,0,MAX_LINE_LENGTH);
}

/*
 *
 */
void enter_cond_state() {
  int start;

  start = YY_START;
  if(start == X_PPD_IF) {
    yy_push_state(X_COND);
  }
}

/*
 *
 */
void exit_cond_state() {
  int start;

  start = YY_START;
  if(start == X_COND) {
    yy_pop_state();
  }
}

/*
 * This exists only to prevent warnings during compilation.
 */
void dummy() {
  yyunput(0,0);
  if(yy_top_state == NULL);
}
