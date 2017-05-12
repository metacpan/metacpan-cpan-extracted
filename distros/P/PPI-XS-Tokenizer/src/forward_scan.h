
#ifndef __FORWARD_SCAN_H__
#define __FORWARD_SCAN_H__

bool inline is_digit(char c) {
	return ( ( c >= '0' ) && ( c <= '9' ) );
}

bool inline is_letter(char c) {
	return ( ( ( c >= 'a' ) && ( c <= 'z' ) ) || ( ( c >= 'A' ) && ( c <= 'Z' ) ) );
}

bool inline is_word(char c) {
	return ( is_digit(c) || is_letter(c) || ( c == '_' ) );
}

bool inline is_whitespace(char c) {
	return ( (  c == ' ' ) || (  c == '\t' ) || (  c == 10 ) || (  c == 13 ) );
}

bool inline is_sigil(char c) {
	return ( ( c == '$' ) || (  c == '@' ) || (  c == '%' ) || (  c == '*' ) );
}

bool inline is_upper_or_underscore(char c) {
	return ( ( ( c >= 'A' ) && (  c <= 'Z' ) ) || (  c == '_' ) );
}

typedef bool (*predicate_function)(char c);

template <predicate_function func> 
class PredicateFunc {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		if ( *position >= line_lenght )
			return false;
		if ( func ( text[*position] ) ) {
			(*position)++;
			return true;
		}
		return false;
	}
};

class PredicateTrue {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		(void)text;
		(void)position;
		(void)line_lenght;
		return true;
	}
};

class PredicateFalse {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		(void)text;
		(void)position;
		(void)line_lenght;
		return false;
	}
};

template <class A1, class A2, class A3 = PredicateTrue, class A4 = PredicateTrue, class A5 = PredicateTrue>
class PredicateAnd {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		unsigned long pos = *position;
		if ( a1.test(text, &pos, line_lenght) &&
			 a2.test(text, &pos, line_lenght) &&
			 a3.test(text, &pos, line_lenght) &&
			 a4.test(text, &pos, line_lenght) &&
			 a5.test(text, &pos, line_lenght) ) {
			*position = pos;
			return true;
		} else {
			return false;
		}
	}
private:
	A1 a1;
	A2 a2;
	A3 a3;
	A4 a4;
	A5 a5;
};

template <class A1, class A2, class A3 = PredicateFalse, class A4 = PredicateFalse>
class PredicateOr {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		unsigned long pos = *position;
		if ( a1.test(text, &pos, line_lenght) ||
			 a2.test(text, &pos, line_lenght) ||
			 a3.test(text, &pos, line_lenght) ||
			 a4.test(text, &pos, line_lenght) ) {
			*position = pos;
			return true;
		} else {
			return false;
		}
	}
private:
	A1 a1;
	A2 a2;
	A3 a3;
	A4 a4;
};

// forwrd negation zero length
template <class A1>
class PredicateNot {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		unsigned long pos = *position;
		return (!inner.test( text, &pos, line_lenght ));
	}
private:
	A1 inner;
};

template <unsigned char c>
class PredicateIsChar {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		if ( *position >= line_lenght )
			return false;
		if ( text[*position] == c ) {
			(*position)++;
			return true;
		}
		return false;
	}
};

template <unsigned char c>
class PredicateIsNotChar {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		if ( *position >= line_lenght )
			return false;
		if ( text[*position] != c ) {
			(*position)++;
			return true;
		}
		return false;
	}
};

// please define the input as: extern const char my_str[] = "...";
template <unsigned long len, const char *str>
class PredicateLiteral {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		if ( str[len] != '\0' ) {
			printf("PredicateLiteral failure: last char is not zero (%s)", str);
			return false;
		}
		if ( *position >= ( line_lenght - len + 1 ) )
			return false;
		unsigned long pos = *position;
		for (unsigned long ix = 0; ix < len; ix++) {
			if ( text[pos + ix] != str[ix] ) {
				return false;
			}
		}
		*position += len;
		return true;
	}
};

// class defined for the future posebility that we use strncmp for PredicateLiteral,
// that won't work well for binary data
template <unsigned long len, const char *str>
class PredicateBinaryLiteral {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		return inner.test( text, position, line_lenght );
	}
private:
	PredicateLiteral< len, str > inner;
};

template <class A1>
class PredicateZeroOrMore {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		while (inner.test( text, position, line_lenght ) ) {}
		return true;
	}
private:
	A1 inner;
};

template <class A1>
class PredicateOneOrMore {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		if (!inner.test( text, position, line_lenght ) )
			return false;
		while (inner.test( text, position, line_lenght ) ) {}
		return true;
	}
private:
	A1 inner;
};

template <class A1>
class PredicateZeroOrOne {
public:
	bool inline test( const char *text, unsigned long *position, unsigned long line_lenght ) {
		inner.test( text, position, line_lenght );
		return true;
	}
private:
	A1 inner;
};

#endif
