#ifndef _bb188d3e_e320_11dc_8b9d_00502c05c241_
#define _bb188d3e_e320_11dc_8b9d_00502c05c241_

#define MAX_INCLUDE_DEPTH 32
#define MAX_LINE_LENGTH 4096
#define MAX_LINE_INDEX MAX_LINE_LENGTH - 1

#define BUFFER_TYPE_FILE 1
#define BUFFER_TYPE_LINE 2
#define BUFFER_TYPE_RESCAN 3

void initialize_lexer(char *filename);
void handle_include_file();
FILE *open_include_file(char *path);
int include_file(char *path);
void include_string(const char *string, int bfr_type);
int not_a_macro();
int not_an_object_macro();
void do_replacement();
char *getCurrentFilename();
int getCurrentLineNumber();
void pp_number_init(char first, char second);
void pp_not_a_literal();
void pp_octal_digit();
void pp_decimal_digit();
void pp_hexadecimal_digit();
void pp_l_suffix();
void pp_f_suffix();
void pp_u_suffix();
void pp_exponent(char second);
void pp_period();
int test_pp_number();
void end_of_line();
void enter_cond_state();
void exit_cond_state();

#endif // _bb188d3e_e320_11dc_8b9d_00502c05c241_

