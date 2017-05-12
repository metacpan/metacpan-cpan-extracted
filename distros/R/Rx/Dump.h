typedef unsigned (*RXCALLBACK)(unsigned, AV *);


SV * dump_compiled_regex(regexp *);
void dump_tree_h(int, OP *);
void rsprint(unsigned, char *) ;
void do_re_inst(int, regnode *, regnode *) ;
SV * regargSV(int, char *) ;
SV * dump_regex(const char *, PMOP *);
void dump_offset_data(regexp *, SV **, SV **) ;
unsigned _partial_dump_regex(regnode *, regnode *, HV *);
PMOP * _options_to_pm(const char *);
char *recompile_dump(HV *) ;
OP * _locate_match_op(const char *) ;
OP * _search_op_for_match(OP *) ;
void start(SV *, SV *, RXCALLBACK);
void _install_compiled_regex(OP *, REGEXP *);
SV *instrument(char *, char *, SV *);

unsigned  test_callback(unsigned, AV *);
