// Tokenizer-C.cpp : Defines the entry point for the console application.
//

#include <stdio.h>
#include <stdlib.h>  
#include <fstream>
#include <iostream>
#include "tokenizer.h"
#include "forward_scan.h"

using namespace PPITokenizer;
using namespace std;

void forward_scan2_unittest();

void checkToken( Tokenizer *tk, const char *text, TokenTypeNames type, int line) {
	Token *token = tk->pop_one_token();
	if ( token == NULL ) {
		if ( text != NULL ) {
			printf("CheckedToken: Got unexpected NULL token (line %d)\n", line);
		}
		return;
	}

	if ( text == NULL ) {
		printf("CheckedToken: Token was expected to be NULL (line %d)\n", line);
	} else 
	if ( type != token->type->type ) {
		printf("CheckedToken: Incorrect token type: expected %d, got %d (line %d)\n", type, token->type->type, line);
	} else 
	if ( strcmp(text, token->text) ) {
		printf("CheckedToken: Incorrect token content: expected |%s|, got |%s| (line %d)\n", text, token->text, line);
	}
	tk->freeToken(token);
}

void checkExtendedTokenModifiers(
					     ExtendedToken *qtoken,
						 const char *section, 
						 int line) {
	bool hasError = false;
	if ( section == NULL ) {
		if ( qtoken->modifiers.size > 0 ) {
			printf("checkExtendedTokenModifiers: no modifiers were supposed to be\n");
			hasError = true;
		}
	} else {
		size_t len = strlen( section );
		if ( len != qtoken->modifiers.size ) {
			printf("checkExtendedTokenModifiers: Section length does not match\n");
			hasError = true;
		} else if ( strncmp( section, qtoken->text + qtoken->modifiers.position, len ) ) {
			printf("checkExtendedTokenModifiers: Section text does not match\n");
			hasError = true;
		}
	}
	if ( hasError ) {
		printf("checkExtendedTokenModifiers: Got incorrect modifiers:\n");
		if ( section != NULL ) {
			printf("expected size %d and modifiers |%s|\n", strlen( section ), section);
		} else {
			printf("expected not to find modifiers\n");
		}
		printf("got size %d and section |", qtoken->modifiers.size);
		for (unsigned long ix = 0; ix < qtoken->modifiers.size; ix++) {
			printf("%c", qtoken->text[ qtoken->modifiers.position + ix ]);
		}
		printf("| (line %d)\n", line);
	}
}

void checkExtendedTokenSection(
					     ExtendedToken *qtoken,
					     unsigned char section_to_check,
						 const char *section, 
						 int line) {
	bool hasError = false;
	if ( section == NULL ) {
		if ( qtoken->current_section > section_to_check ) {
			printf("checkExtendedTokenSection: Section was not supposed to be\n");
			hasError = true;
		}
	} else {
		size_t len = strlen( section );
		if ( len != qtoken->sections[section_to_check].size ) {
			printf("checkExtendedTokenSection: Section length does not match\n");
			hasError = true;
		} else if ( strncmp( section, qtoken->text + qtoken->sections[section_to_check].position, len ) ) {
			printf("checkExtendedTokenSection: Section text does not match\n");
			hasError = true;
		}
	}
	if ( hasError ) {
		printf("checkExtendedToken: Got incorrect section %d:\n", section_to_check);
		printf("expected size %d, got size %d (line %d)\n", strlen( section ), qtoken->sections[section_to_check].size, line);
		printf("expected section |%s|, got section |", section );
		for (unsigned long ix = 0; ix < qtoken->sections[section_to_check].size; ix++) {
			printf("%c", qtoken->text[ qtoken->sections[section_to_check].position + ix ]);
		}
		printf("|\n");
	}
}

void checkExtendedToken( Tokenizer *tk, 
						 const char *text, 
						 const char *section1, 
						 const char *section2,
						 const char *modifiers,
						 TokenTypeNames type, 
						 int line) {
	Token *token = tk->pop_one_token();
	if ( token == NULL ) {
		if ( text != NULL ) {
			printf("checkExtendedToken: Got unexpected NULL token (line %d)\n", line);
		}
		return;
	}
	if ( text == NULL ) {
		printf("checkExtendedToken: Token was expected to be NULL (line %d)\n", line);
	} else 
	if ( type != token->type->type ) {
		printf("checkExtendedToken: Incorrect token type: expected %d, got %d (line %d)\n", type, token->type->type, line);
	} else 
	if ( strcmp(text, token->text) ) {
		printf("checkExtendedToken: Incorrect token content: expected |%s|, got |%s| (line %d)\n", text, token->text, line);
	} else 
	{
		ExtendedToken *qtoken = (ExtendedToken *)token;
		if ( qtoken->current_section >= 1 )
			checkExtendedTokenSection( qtoken, 0, section1, line);
		if ( qtoken->current_section >= 2 )
			checkExtendedTokenSection( qtoken, 1, section2, line);
		checkExtendedTokenModifiers( qtoken, modifiers, line );
	}

	tk->freeToken(token);
}
#define CheckToken( tk, text, type ) checkToken(tk, text, type, __LINE__);
#define CheckExtendedToken( tk, text, section1, section2, modifiers, type ) checkExtendedToken(tk, text, section1, section2, modifiers, type, __LINE__);
#define Tokenize( line ) tk.tokenizeLine( line , (unsigned long)strlen(line) );

void VerifyInheritence( AbstractTokenType **type_pool );

void TestOnNodePm() {
	char buffer[200];
	Tokenizer tk;
	ifstream file;
	file.open("C:\\Perl\\AdamKProjects\\PPI\\t\\data\\26_bom\\utf8.code");
	while (!file.eof()) {
		file.getline(buffer, 200);
		unsigned long line_len = file.gcount();
		tk.tokenizeLine(buffer, line_len);
	}
}

void stam1() {
	Tokenizer tk;
	Tokenize("X<<f+X;g(<~\" \n");
	Tokenize("1\n");
	Tokenize("*");
}

void stam2() {
	Tokenizer tk;
	Tokenize("qw(");
	tk.EndOfDocument();
	ExtendedToken *t = (ExtendedToken *)tk.pop_one_token();
	printf("Done\n");
}

void stam3() {
	Tokenizer tk;
	Tokenize("s {foo} <bar>i");
	tk.EndOfDocument();
	ExtendedToken *t = (ExtendedToken *)tk.pop_one_token();
	printf("Done\n");
}

int main(int argc, char* argv[])
{
	forward_scan2_unittest();
	//TestOnNodePm();
	//stam1();
	//stam2();
	stam3();
	Tokenizer tk;
	VerifyInheritence( tk.TokenTypeNames_pool );

	Tokenize("s {foo} <bar>i");
	CheckExtendedToken( &tk, "s {foo} <bar>i", "foo", "bar", "i", Token_Regexp_Substitute );

	Tokenize("package Foo::100;\n");
	CheckToken(&tk, "package", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "Foo::100", Token_Word);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("2*foo;\n");
	CheckToken(&tk, "2", Token_Number);
	CheckToken(&tk, "*", Token_Operator);
	CheckToken(&tk, "foo", Token_Word);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("%^H=();\n");
	CheckToken(&tk, "%^H", Token_Magic);
	CheckToken(&tk, "=", Token_Operator);
	CheckToken(&tk, "(", Token_Structure);
	CheckToken(&tk, ")", Token_Structure);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("$::|=1;\n");
	CheckToken(&tk, "$::|", Token_Magic);
	CheckToken(&tk, "=", Token_Operator);
	CheckToken(&tk, "1", Token_Number);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("&$wanted;\n");
	CheckToken(&tk, "&", Token_Cast);
	CheckToken(&tk, "$wanted", Token_Symbol);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("@{^_Bar};\n");
	CheckToken(&tk, "@{^_Bar}", Token_Magic);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("$${^MATCH};\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "$", Token_Cast);
	CheckToken(&tk, "${^MATCH}", Token_Magic);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("${^MATCH};\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "${^MATCH}", Token_Magic);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("$#-;\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "$#-", Token_Magic);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("%-;\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "%-", Token_Magic);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("0E0;\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "0E0", Token_Number_Exp);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("indirect_class_with_colon Foo::;\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "indirect_class_with_colon", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "Foo::", Token_Word);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("  {  }   \n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "  ", Token_Whitespace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "  ", Token_Whitespace);
	CheckToken(&tk, "}", Token_Structure);
	CheckToken(&tk, "   \n", Token_Whitespace);

	Tokenize("  # aabbcc d\n");
	CheckToken(&tk, "  # aabbcc d\n", Token_Comment);

	Tokenize("foo  # aabbcc d\n");
	CheckToken(&tk, "foo", Token_Word);
	CheckToken(&tk, "  ", Token_Whitespace);
	CheckToken(&tk, "# aabbcc d", Token_Comment);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize(" + \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "+", Token_Operator);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" $testing \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "$testing", Token_Symbol);

	Tokenize(" \"ab cd ef\" \n");
	CheckToken(&tk, " \n", Token_Whitespace);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "\"ab cd ef\"", Token_Quote_Double);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" \"ab cd ef \n");
	Tokenize("xs cd ef\" \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "\"ab cd ef \nxs cd ef\"", Token_Quote_Double);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" 'ab cd ef' \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "'ab cd ef'", Token_Quote_Single);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" qq / baaccvf cxxdf/  q/zxcvvfdcvff/ qq !a\\!a!\n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qq / baaccvf cxxdf/", " baaccvf cxxdf", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "  ", Token_Whitespace);
	CheckExtendedToken( &tk, "q/zxcvvfdcvff/", "zxcvvfdcvff", NULL, NULL, Token_Quote_Literal );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qq !a\\!a!", "a\\!a", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize(" qq { baa{ccv\\{f cx}xdf}  q(zx(cv(vfd))cvff) qq <a\\!a>\n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qq { baa{ccv\\{f cx}xdf}", " baa{ccv\\{f cx}xdf", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "  ", Token_Whitespace);
	CheckExtendedToken( &tk, "q(zx(cv(vfd))cvff)", "zx(cv(vfd))cvff", NULL, NULL, Token_Quote_Literal );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qq <a\\!a>", "a\\!a", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize(" qw{ aa bb \n");
	Tokenize(" cc dd }\n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qw{ aa bb \n cc dd }", " aa bb \n cc dd ", NULL, NULL, Token_QuoteLike_Words );
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize(" <FFAA> <$var> \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "<FFAA>", "FFAA", NULL, NULL, Token_QuoteLike_Readline );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "<$var>", "$var", NULL, NULL, Token_QuoteLike_Readline );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" m/aabbcc/i m/cvfder/ =~ /rewsdf/xds \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "m/aabbcc/i", "aabbcc", NULL, "i", Token_Regexp_Match );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "m/cvfder/", "cvfder", NULL, NULL, Token_Regexp_Match );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "=~", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "/rewsdf/xds", "rewsdf", NULL, "xds", Token_Regexp_Match_Bare );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" qr/xxccvvb/ qr{xcvbfv}i \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qr/xxccvvb/", "xxccvvb", NULL, NULL, Token_QuoteLike_Regexp );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "qr{xcvbfv}i", "xcvbfv", NULL, "i", Token_QuoteLike_Regexp );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" s/xxccvvb/ccffdd/ s/xxccvvb/ccffdd/is \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "s/xxccvvb/ccffdd/", "xxccvvb", "ccffdd", NULL, Token_Regexp_Substitute );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "s/xxccvvb/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Substitute );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" tr/xxccvvb/ccffdd/ tr/xxccvvb/ccffdd/is \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "tr/xxccvvb/ccffdd/", "xxccvvb", "ccffdd", NULL, Token_Regexp_Transliterate );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "tr/xxccvvb/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Transliterate );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" y/xxccvvb/ccffdd/ y/xxccvvb/ccffdd/is \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "y/xxccvvb/ccffdd/", "xxccvvb", "ccffdd", NULL, Token_Regexp_Transliterate );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "y/xxccvvb/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Transliterate );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" s{xxccvvb} {ccffdd} s{xxccvvb}{ccffdd}is \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "s{xxccvvb} {ccffdd}", "xxccvvb", "ccffdd", NULL, Token_Regexp_Substitute );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "s{xxccvvb}{ccffdd}is", "xxccvvb", "ccffdd", "is", Token_Regexp_Substitute );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" s{xxccvvb} [ccffdd] s{xxccvvb}/ccffdd/is \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "s{xxccvvb} [ccffdd]", "xxccvvb", "ccffdd", NULL, Token_Regexp_Substitute );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "s{xxccvvb}/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Substitute );
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" 17, .17, 15.34, 54..34, 53.2..45.6, 0x56Bd3, -0x71, 0b101,\n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "17", Token_Number);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, ".17", Token_Number_Float);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "15.34", Token_Number_Float);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "54", Token_Number);
	CheckToken(&tk, "..", Token_Operator);
	CheckToken(&tk, "34", Token_Number);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "53.2", Token_Number_Float);
	CheckToken(&tk, "..", Token_Operator);
	CheckToken(&tk, "45.6", Token_Number_Float);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "0x56Bd3", Token_Number_Hex);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "-0x71", Token_Number_Hex);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "0b101", Token_Number_Binary);
	CheckToken(&tk, ",", Token_Operator);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("04324 12.34e-56 12.34e+56 / 12.34e56 123.e12 123.edc \n");
	CheckToken(&tk, "04324", Token_Number_Octal);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "12.34e-56", Token_Number_Exp);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "12.34e+56", Token_Number_Exp);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "/", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "12.34e56", Token_Number_Exp);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "123.e12", Token_Number_Exp);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "123", Token_Number);
	CheckToken(&tk, ".", Token_Operator);
	CheckToken(&tk, "edc", Token_Word);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" $#array + $^X Hello: ;\n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "$#array", Token_ArrayIndex);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "+", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "$^X", Token_Magic);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "Hello:", Token_Label);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("sub mmss:attrib{return 5}\n");
	CheckToken(&tk, "sub", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "mmss", Token_Word);
	CheckToken(&tk, ":", Token_Operator_Attribute);
	CheckToken(&tk, "attrib", Token_Attribute);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "return", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "5", Token_Number);
	CheckToken(&tk, "}", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("sub mmss:attrib(45) {return 5}\n");
	CheckToken(&tk, "sub", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "mmss", Token_Word);
	CheckToken(&tk, ":", Token_Operator_Attribute);
	CheckToken(&tk, "attrib(45)", Token_Attribute_Parameterized);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "return", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "5", Token_Number);
	CheckToken(&tk, "}", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize("=head start of pod\n");
	Tokenize("=cut \n");
	CheckToken(&tk, "=head start of pod\n=cut \n", Token_Pod);

	Tokenize(" %$symbol; \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "%", Token_Cast);
	CheckToken(&tk, "$symbol", Token_Symbol);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("sub mmss ($$) {return 5}\n");
	CheckToken(&tk, " \n", Token_Whitespace);
	CheckToken(&tk, "sub", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "mmss", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "($$)", Token_Prototype);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "return", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "5", Token_Number);
	CheckToken(&tk, "}", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);

	Tokenize(" + -hello \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "+", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "-hello", Token_Word);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize(" 1.2.3 \n");
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, "1.2.3", Token_Number_Version);
	CheckToken(&tk, " \n", Token_Whitespace);

	Tokenize("print <<XYZ;\n");
	Tokenize("asds vghtjty\n");
	Tokenize("poiuyt treewq\n");
	Tokenize("XYZ\n");
	CheckToken(&tk, "print", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	//CheckToken(&tk, "<<XYZ", Token_HereDoc);
	CheckExtendedToken( &tk, "<<XYZasds vghtjty\npoiuyt treewq\nXYZ\n", 
		"<<XYZ", "asds vghtjty\npoiuyt treewq\nXYZ\n", "XYZ", Token_HereDoc );
	CheckToken(&tk, ";", Token_Structure);
	//CheckExtendedToken( &tk, "XYZasds vghtjty\npoiuyt treewq\nXYZ\n", 
	//	"XYZ", "asds vghtjty\npoiuyt treewq\nXYZ\n", NULL, Token_HereDoc );

	Tokenize("print << 'XYZ';\n");
	Tokenize("asds vghtjty\n");
	Tokenize("poiuyt treewq\n");
	Tokenize("XYZ\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "print", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "<< 'XYZ'asds vghtjty\npoiuyt treewq\nXYZ\n", 
		"<< 'XYZ'", "asds vghtjty\npoiuyt treewq\nXYZ\n", "XYZ", Token_HereDoc );
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("print <<XYZ . <<ABC;\n");
	Tokenize("asds vghtjty\n");
	Tokenize("poiuyt treewq\n");
	Tokenize("XYZ\n");
	Tokenize("kjgkfdfkk  kkslkjf\n");
	Tokenize("kjslk remnrea\n");
	Tokenize("ABC\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "print", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "<<XYZasds vghtjty\npoiuyt treewq\nXYZ\n", 
		"<<XYZ", "asds vghtjty\npoiuyt treewq\nXYZ\n", "XYZ", Token_HereDoc );
	CheckToken(&tk, " ", Token_Whitespace);
	CheckToken(&tk, ".", Token_Operator);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "<<ABCkjgkfdfkk  kkslkjf\nkjslk remnrea\nABC\n", 
		"<<ABC", "kjgkfdfkk  kkslkjf\nkjslk remnrea\nABC\n", "ABC", Token_HereDoc );
	CheckToken(&tk, ";", Token_Structure);


	Tokenize("__END__\n");
	CheckToken(&tk, "\n", Token_Whitespace);
	Tokenize("FDGDF hfghhgfhg gfh\n");
	Tokenize("=start\n");
	Tokenize("aaad dkfjs dfsd\n");
	Tokenize("=cut\n");
	Tokenize("hjkil jkhjk hjh\n");
	tk.EndOfDocument();
	CheckToken(&tk, "__END__", Token_Separator);
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "FDGDF hfghhgfhg gfh\n", Token_End);
	CheckToken(&tk, "=start\naaad dkfjs dfsd\n=cut\n", Token_Pod);
	CheckToken(&tk, "hjkil jkhjk hjh\n", Token_End);

	tk.Reset();
	Tokenize("$symbol;\n");
	Tokenize("__DATA__\n");
	Tokenize("FDGDF hfghhgfhg gfh\n");
	Tokenize("=start\n");
	tk.EndOfDocument();
	CheckToken(&tk, "$symbol", Token_Symbol);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "__DATA__", Token_Separator);
	CheckToken(&tk, "\n", Token_Whitespace);
	CheckToken(&tk, "FDGDF hfghhgfhg gfh\n=start\n", Token_Data);

	tk.Reset();
	Tokenize("F;");
	tk.EndOfDocument();
	CheckToken(&tk, "F", Token_Word);
	CheckToken(&tk, ";", Token_Structure);

	tk.Reset();
	Tokenize("print <<END;\n");
	Tokenize("Foo\n");
	Tokenize("END"); // no newline
	tk.EndOfDocument();
	CheckToken(&tk, "print", Token_Word);
	CheckToken(&tk, " ", Token_Whitespace);
	CheckExtendedToken( &tk, "<<ENDFoo\nEND", 
		"<<END", "Foo\nEND", "END", Token_HereDoc );
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_Whitespace);


	Token *tkn;
	while (( tkn = tk.pop_one_token() ) != NULL ) {
		printf("Token: |%s| (%d, %d)\n", tkn->text, tkn->length, tkn->type->type);
		tk.freeToken(tkn);
	}
	return 0;
}

static void is_true( bool check, int line ) {
	if (!check)
		printf("Forward_scan_UI: %d: Is not correct (false)\n", line);
}

static void is_false( bool check, int line ) {
	if (check)
		printf("Forward_scan_UI: %d: Is not correct (true)\n", line);
}
#define BE_TRUE( check ) is_true( (check), __LINE__ );
#define BE_FALSE( check ) is_false( (check), __LINE__ );

extern const char l_test[] = "yz";

void forward_scan2_unittest() {
	PredicateIsChar< 'x' > regex1;
	unsigned long pos = 0;
	BE_TRUE( regex1.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 1 );
	BE_FALSE( regex1.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 1 );
	
	PredicateLiteral< 2, l_test > regex2;
	pos = 0;
	BE_FALSE( regex2.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 0 );
	pos = 1;
	BE_TRUE( regex2.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 3 );
}

void checkISA( AbstractTokenType *tested, TokenTypeNames type, TokenTypeNames should, int line ) {
	if ( !tested->isa( should ) ) {
		printf("ISA error: %d is not parent of type %d (%d)\n", should, type, line );
	}
}
#define CheckISA( type, should_be ) checkISA( type_pool[ type ], type, should_be, __LINE__ ) 

void VerifyInheritence( AbstractTokenType **type_pool ) {
	// I dont care for tokens that only inherent from PPI::Token
      //PPI::Token
      //   PPI::Token::HereDoc
      //   PPI::Token::Cast
      //   PPI::Token::Structure
      //   PPI::Token::Label
      //   PPI::Token::Separator
      //   PPI::Token::Data
      //   PPI::Token::End
      //   PPI::Token::Prototype
      //   PPI::Token::Attribute
      //   PPI::Token::Unknown
      //   PPI::Token::ArrayIndex
      //   PPI::Token::Operator
      //   PPI::Token::Word
      //   PPI::Token::DashedWord
      //   PPI::Token::Whitespace
      //   PPI::Token::Comment
      //   PPI::Token::Pod
	// the following are interesting.

	  //   PPI::Token::Number
      //      PPI::Token::Number::Binary
      //      PPI::Token::Number::Octal
      //      PPI::Token::Number::Hex
      //      PPI::Token::Number::Float
      //         PPI::Token::Number::Exp
      //      PPI::Token::Number::Version
	CheckISA( Token_Number_Version, Token_Number );
	CheckISA( Token_Number_Binary, Token_Number );
	CheckISA( Token_Number_Hex, Token_Number );
	CheckISA( Token_Number_Float, Token_Number );
	CheckISA( Token_Number_Octal, Token_Number );
	CheckISA( Token_Number_Exp, Token_Number );
	CheckISA( Token_Number_Exp, Token_Number_Float );
      //   PPI::Token::Symbol
      //      PPI::Token::Magic
	CheckISA( Token_Magic, Token_Symbol );
      //   PPI::Token::Quote
      //      PPI::Token::Quote::Single
      //      PPI::Token::Quote::Double
      //      PPI::Token::Quote::Literal
      //      PPI::Token::Quote::Interpolate
      //   PPI::Token::QuoteLike
      //      PPI::Token::QuoteLike::Backtick
      //      PPI::Token::QuoteLike::Command
      //      PPI::Token::QuoteLike::Regexp
      //      PPI::Token::QuoteLike::Words
      //      PPI::Token::QuoteLike::Readline
      //   PPI::Token::Regexp
      //      PPI::Token::Regexp::Match
      //      PPI::Token::Regexp::Substitute
      //      PPI::Token::Regexp::Transliterate
}

