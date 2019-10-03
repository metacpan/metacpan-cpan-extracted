#include "parser.h"
#include "macro.h"
#include "state.h"
#include "debug.h"
#include "xsutil.h"

AV* parse (pTHX_ HV* state, register char* p) {
  DEBUG_OUT("line: %s", p);

  AV* ret = NULL;
  while (*p != '\0') {
    SKIP_WSPACE(p);
    if (*p == '\0') break;

    const IV context = get_parser_context(aTHX_ state);
    switch (context) {
      case CONTEXT_GLOBAL:
        DEBUG_OUT("context: GLOBAL\n");
        p = parse_global(aTHX_ state, p);
        break;
      case CONTEXT_CREATE_TABLE:
        DEBUG_OUT("context: CREATE TABLE\n");
        p = parse_create_table(aTHX_ state, p);
        break;
      case CONTEXT_CREATE_TABLE_COLUMN:
        DEBUG_OUT("context: CREATE TABLE (column)\n");
        p = parse_create_table_column(aTHX_ state, p);
        break;
      case CONTEXT_BLOCK_COMMENT:
        DEBUG_OUT("context: BLOCK COMMENT\n");
        p = parse_block_comment(aTHX_ state, p);
        break;
      case CONTEXT_INSERT_INTO:
        DEBUG_OUT("context: INSER INTO\n");
        p = parse_insert_into(aTHX_ state, p);
        break;
      case CONTEXT_INSERT_VALUES:
        DEBUG_OUT("context: INSER INTO (values)\n");
        if (! ret) {
          ret = newAV_mortal();
        }
        p = parse_insert_values(aTHX_ state, p, ret);
        break;
      default:
        croak("Unexpected context:%d", (int)context);
    }
  }

  return ret;
}

char* parse_global (pTHX_ HV* state, register char* p) {
  while (*p != '\0') {
    DEBUG_OUT("[GLOBAL] char: %c\n", *p);
    if (*p == '/') {
      // is comment ?
      if (*(p + 1) == '*') {
        p += 2;
        set_parser_context(aTHX_ state, CONTEXT_BLOCK_COMMENT);
        break;
      }
      else {
        p++;
      }
    }
    else if (*p == '-' && *(p + 1) == '-') {
      // line comment
      while (*p != '\0' && *p != '\n') p++;
    }
    else if (IS_WSPACE(p)) {
      SKIP_WSPACE(p);
    }
    else if (*p == 'C')  {
      // is create table?
      if (IS_CREATE(p)) {
        p += 6;
        SKIP_WSPACE(p);
        if (*p == '\0') break;
        if (IS_TABLE(p)) {
          p += 5;
          SKIP_WSPACE(p);

          // set context and extract table name
          set_parser_context(aTHX_ state, CONTEXT_CREATE_TABLE);
          char* mark;
          if (*p == '`') {
            mark = ++p;
            while (*p != '\0' && *p != '`') p++;
          }
          else {
            mark = p;
            SKIP_UNTIL_WSPACE(p);
          }
          if (*p == '\0') break;
          set_table(aTHX_ state, mark, p - mark);
          p++;
          SKIP_WSPACE(p);

          break;
        }
      }
      else {
        p++;
      }
    }
    else if (*p == 'I')  {
      // is insert?
      if (IS_INSERT(p)) {
        p += 6;
        SKIP_WSPACE(p);
        if (*p == '\0') break;
        if (IS_INTO(p)) {
          p += 4;
          SKIP_WSPACE(p);

          // set context and extract table name
          set_parser_context(aTHX_ state, CONTEXT_INSERT_INTO);
          char* mark;
          if (*p == '`') {
            mark = ++p;
            while (*p != '\0' && *p != '`') p++;
          }
          else {
            mark = p;
            SKIP_UNTIL_WSPACE(p);
          }
          if (*p == '\0') break;
          set_table(aTHX_ state, mark, p - mark);
          p++;
          SKIP_WSPACE(p);

          break;
        }
      }
      else {
        p++;
      }
    }
    else {
      p++;
    }
  }
  return p;
}

char* parse_block_comment (pTHX_ HV* state, register char* p) {
  while (*p != '\0') {
    DEBUG_OUT("[BLOCK COMMENT] char: %c\n", *p);
    if (*p++ == '*') {
      if (*p++ == '/') {
        restore_context(aTHX_ state);
        break;
      }
    }
  }
  return p;
}

char* parse_create_table (pTHX_ HV* state, register char* p) {
  HV* schema  = get_current_schema(aTHX_ state);
  AV* columns = get_or_create_columns(aTHX_ schema);
  while (*p != '\0') {
    DEBUG_OUT("[CREATE TABLE] char: %c\n", *p);
    if (*p == '/') {
      // is comment ?
      if (*(p + 1) == '*') {
        p += 2;
        set_parser_context(aTHX_ state, CONTEXT_BLOCK_COMMENT);
        break;
      }
    }
    else if (*p == '-' && *(p + 1) == '-') {
      // line comment
      while (*p != '\0' && *p != '\n') p++;
    }
    else if (IS_WSPACE(p)) {
      SKIP_WSPACE(p);
    }
    else if (*p == '(') {
      p++;
      incr_nest(aTHX_ state);
    }
    else if (*p == ')') {
      p++;
      decr_nest(aTHX_ state);
    }
    else {
      const IV nest = get_nest(aTHX_ state);
      DEBUG_OUT("nest:%d\n", (int)nest);
      if (nest == 0) {
        while (*p != '\0' && *p != '(' && *p != ';' && *p != '/') p++;
        if (*p == ';') {
          p++;
          set_parser_context(aTHX_ state, CONTEXT_GLOBAL);
          break;
        }
        else {
          continue;
        }
      }
      else if (nest == 1) {
        if (! IS_MAYBE_KEY(p)) {
          char *mark;
          if (*p == '`') {
            mark = ++p;
            while (*p != '\0' && *p != '`') p++;
          }
          else {
            mark = p;
            SKIP_UNTIL_WSPACE(p);
          }
          if (*p == '\0') break;
          XSUTIL_AV_PUSH_NOINC(columns, newSVpvn(mark, p - mark));
          DEBUG_OUT("column name: %.*s\n", (int)(p - mark), mark);
          p++;
        }
        set_parser_context(aTHX_ state, CONTEXT_CREATE_TABLE_COLUMN);
        break;
      }
      else {
        p++;
      }
    }
  }
  return p;
}

char* parse_create_table_column (pTHX_ HV* state, register char* p) {
  while (1) {
    DEBUG_OUT("[CREATE TABLE (column)] char: %c\n", *p);
    if (*p == '\0') {
      return p;
    }
    else if (*p == '/') {
      // is comment ?
      if (*(p + 1) == '*') {
        p += 2;
        set_parser_context(aTHX_ state, CONTEXT_BLOCK_COMMENT);
        return p;
      }
    }
    else if (*p == '-' && *(p + 1) == '-') {
      // line comment
      while (*p != '\0' && *p != '\n') p++;
    }
    else if (IS_WSPACE(p)) {
      SKIP_WSPACE(p);
    }
    else if (*p == '(') {
      p++;
      incr_nest(aTHX_ state);
    }
    else if (*p == ')') {
      const IV nest = get_nest(aTHX_ state);
      if (nest == 0) break;
      p++;
      decr_nest(aTHX_ state);
    }
    else if (*p == '\'' || *p == '"') {
      char symbol = *p++;
      while (*p != '\0' && *p != symbol) {
        if (*p == '\\') p++;
        p++;
      }
      if (*p != '\0') p++;
    }
    else {
      const IV nest = get_nest(aTHX_ state);
      DEBUG_OUT("nest:%d\n", (int)nest);
      if (nest == 0 && *p == ',') {
        break;
      }
      else {
        p++;
      }
    }
  }

  set_parser_context(aTHX_ state, CONTEXT_CREATE_TABLE);
  if (*p != ')') incr_nest(aTHX_ state); /* XXX: fix nest to 1 */
  p++;
  return p;
}

char* parse_insert_into (pTHX_ HV* state, register char* p) {
  while (*p != '\0') {
    DEBUG_OUT("[INSERT INTO] char: %c\n", *p);
    if (*p == '/') {
      // is comment ?
      if (*(p + 1) == '*') {
        p += 2;
        set_parser_context(aTHX_ state, CONTEXT_BLOCK_COMMENT);
        break;
      }
    }
    else if (*p == '-' && *(p + 1) == '-') {
      // line comment
      while (*p != '\0' && *p != '\n') p++;
    }
    else if (IS_WSPACE(p)) {
      SKIP_WSPACE(p);
    }
    else if (*p == '(') {
      p++;
      DEBUG_OUT("SET COLUMNS (INSERT INTO)\n");
      HV* schema  = get_current_schema(aTHX_ state);
      AV* columns = get_or_create_columns(aTHX_ schema);
      av_clear(columns);

      char *mark;
      while (*p != '\0' && *p != ')') {
        SKIP_WSPACE(p);
        if (*p == '`') {
          mark = ++p;
          while (*p != '\0' && *p != '`') p++;
        }
        else {
          mark = p;
          while (*p != '\0' && *p != ',' && *p != ')') p++;
        }
        if (*p == '\0') break;
        XSUTIL_AV_PUSH_NOINC(columns, newSVpvn(mark, p - mark));
        DEBUG_OUT("name: %.*s\n", (int)(p - mark), mark);
        if (*++p == ',') p++;
      }
      if (*p == '\0') break;
      p++;
    }
    else if (IS_VALUES(p)) {
      p += 6;
      set_parser_context(aTHX_ state, CONTEXT_INSERT_VALUES);
      break;
    }
    else {
      DEBUG_OUT("[INSERT INTO] Unexpected char: %c\n", *p);
    }
  }
  return p;
}

char* parse_insert_values (pTHX_ HV* state, register char* p, AV* ret) {
  HV* schema  = get_current_schema(aTHX_ state);
  AV* columns = get_or_create_columns(aTHX_ schema);
  while (*p != '\0') {
    DEBUG_OUT("[INSERT INTO VALUES] char: %c\n", *p);
    if (*p == '/') {
      // is comment ?
      if (*(p + 1) == '*') {
        p += 2;
        set_parser_context(aTHX_ state, CONTEXT_BLOCK_COMMENT);
        break;
      }
    }
    else if (*p == '-' && *(p + 1) == '-') {
      // line comment
      while (*p != '\0' && *p != '\n') p++;
    }
    else if (IS_WSPACE(p)) {
      SKIP_WSPACE(p);
    }
    else if (*p == '(') {
      DEBUG_OUT("SET VALUE\n");
      HV* row = newHV_mortal();
      p++;

      I32 column_id = 0;
      while (*p != '\0' && *p != ')') {
        // get column name
        SV** column_ref = XSUTIL_AV_FETCH(columns, column_id);
        if (! column_ref) croak("Cannot fetch columns[%d]", column_id);
        SV* column = *column_ref;
        DEBUG_OUT("key: %s\n", SvPV_nolen(column));

        // extract and store value
        if (IS_NULL_STR(p)) {
          // null value
          p += 4;
          DEBUG_OUT("value: (NULL)\n");
          XSUTIL_HV_STORE_ENT_NOINC(row, column, &PL_sv_undef);
        }
        else if (*p == '\'' || *p == '"') {
          // string
          char  symbol = *p;
          char* mark   = ++p;
          SV*   value  = NULL;
          while (*p != '\0' && *p != symbol) {
            // handle mySQL string literals
            if (*p == '\\') {
              char c[2] = {'\0', '\0'};

              if (value == NULL) {
                value = newSVpvn(mark, p - mark);
              }
              else {
                sv_catpvn(value, mark, p - mark);
              }

              p++;
              switch (*p) {
              case '0':
                c[0] = '\0';
                break;
              case 'b':
                c[0] = '\b';
                break;
              case 'n':
                c[0] = '\n';
                break;
              case 'r':
                c[0] = '\r';
                break;
              case 't':
                c[0] = '\t';
                break;
              case 'Z':
                c[0] = '\x1A';
                break;
              default:
                c[0] = *p;
                break;
              }
              sv_catpvn(value, c, 1);
              mark = p + 1;
            }
            p++;
          }
          if (value == NULL) {
            value = newSVpvn(mark, p - mark);
          }
          else {
            sv_catpvn(value, mark, p - mark);
          }
          DEBUG_OUT("value: %s (string)\n", SvPV_nolen(value));
          XSUTIL_HV_STORE_ENT_NOINC(row, column, value);
        }
        else {
          // normal value
          char* mark = p;
          while (*p != '\0' && *p != ',' && *p != ')') p++;

          // store
          SV* value = newSVpvn(mark, p - mark);
          DEBUG_OUT("value: %s(normal value)\n", SvPV_nolen(value));
          XSUTIL_HV_STORE_ENT_NOINC(row, column, value);
        }

        // skip
        while (*p != '\0' && *p != ',' && *p != ')') p++;
        if (*p == '\0') return p;
        SKIP_WSPACE(p);
        if (*p == ',') {
          column_id++;
          p++;
        }
        SKIP_WSPACE(p);
      }

      XSUTIL_AV_PUSH_REF(ret, (SV*)row);
    }
    else if (*p == ';') {
      p++;
      set_parser_context(aTHX_ state, CONTEXT_GLOBAL);
      break;
    }
    else {
      p++;
    }
  }
  return p;
}

