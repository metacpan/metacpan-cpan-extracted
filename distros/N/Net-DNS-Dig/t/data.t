# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#	data.t
######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
        $| = 1; print "1..24\n"; 
        *CORE::GLOBAL::localtime = \&localtime;
}
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNS::ToolKit qw(
	put1char
	inet_aton
);
use Net::DNS::ToolKit::RR;
use Net::DNS::Dig;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

{	undef local $^W;
	*Net::DNS::Dig::ndd_gethostbyname = \&mygethostbyname;
}
# dummy mygethostbyname
sub mygethostbyname {
  return inet_aton('97.65.43.21') if $_[0] =~ /[a-zA-Z]/;       # is a name
  return inet_aton($_[0]);                              # else decode IP address
}


require './recurse2txt';

$Net::DNS::Dig::VERSION = sprintf("%d.%02d",0,1);	# always test as version 0.01

Net::DNS::Dig::_set_NS(inet_aton('12.34.56.78'),inet_aton('23.45.67.89'));

# dummy localtime
sub localtime {
  return 'Mon Oct  3 13:41:57 2011';
}

my $ques2 = q
| 0	:  0100_1101  0x4D   77  M  
  1	:  0101_1100  0x5C   92  \  
  2	:  0000_0001  0x01    1    
  3	:  0000_0000  0x00    0    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0000  0x00    0    
  8	:  0000_0000  0x00    0    
  9	:  0000_0000  0x00    0    
  10	:  0000_0000  0x00    0    
  11	:  0000_0000  0x00    0    
  12	:  0000_0100  0x04    4    
  13	:  0110_0001  0x61   97  a  
  14	:  0111_0010  0x72  114  r  
  15	:  0111_0000  0x70  112  p  
  16	:  0110_0001  0x61   97  a  
  17	:  0000_0011  0x03    3    
  18	:  0110_0011  0x63   99  c  
  19	:  0110_1111  0x6F  111  o  
  20	:  0110_1101  0x6D  109  m  
  21	:  0000_0000  0x00    0    
  22	:  0000_0000  0x00    0    
  23	:  0001_1100  0x1C   28    
  24	:  0000_0000  0x00    0    
  25	:  0000_0001  0x01    1    |;

my $ans2 = q
| 0	:  0100_1101  0x4D   77  M  
  1	:  0101_1100  0x5C   92  \  
  2	:  1000_0001  0x81  129    
  3	:  1000_0000  0x80  128    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_0001  0x01    1    
  8	:  0000_0000  0x00    0    
  9	:  0000_1000  0x08    8    
  10	:  0000_0000  0x00    0    
  11	:  0000_1000  0x08    8    
  12	:  0000_0100  0x04    4    
  13	:  0110_0001  0x61   97  a  
  14	:  0111_0010  0x72  114  r  
  15	:  0111_0000  0x70  112  p  
  16	:  0110_0001  0x61   97  a  
  17	:  0000_0011  0x03    3    
  18	:  0110_0011  0x63   99  c  
  19	:  0110_1111  0x6F  111  o  
  20	:  0110_1101  0x6D  109  m  
  21	:  0000_0000  0x00    0    
  22	:  0000_0000  0x00    0    
  23	:  0001_1100  0x1C   28    
  24	:  0000_0000  0x00    0    
  25	:  0000_0001  0x01    1    
  26	:  1100_0000  0xC0  192    
  27	:  0000_1100  0x0C   12    
  28	:  0000_0000  0x00    0    
  29	:  0001_1100  0x1C   28    
  30	:  0000_0000  0x00    0    
  31	:  0000_0001  0x01    1    
  32	:  0000_0000  0x00    0    
  33	:  0000_0000  0x00    0    
  34	:  0000_0000  0x00    0    
  35	:  0001_0000  0x10   16    
  36	:  0000_0000  0x00    0    
  37	:  0001_0000  0x10   16    
  38	:  0010_0110  0x26   38  &  
  39	:  0000_0111  0x07    7    
  40	:  1111_0010  0xF2  242    
  41	:  1111_1000  0xF8  248    
  42	:  1010_0101  0xA5  165    
  43	:  0111_0000  0x70  112  p  
  44	:  0000_0000  0x00    0    
  45	:  0000_0000  0x00    0    
  46	:  0000_0000  0x00    0    
  47	:  0000_0000  0x00    0    
  48	:  0000_0000  0x00    0    
  49	:  0000_0000  0x00    0    
  50	:  0000_0000  0x00    0    
  51	:  0000_0000  0x00    0    
  52	:  0000_0000  0x00    0    
  53	:  0000_0010  0x02    2    
  54	:  1100_0000  0xC0  192    
  55	:  0000_1100  0x0C   12    
  56	:  0000_0000  0x00    0    
  57	:  0000_0010  0x02    2    
  58	:  0000_0000  0x00    0    
  59	:  0000_0001  0x01    1    
  60	:  0000_0000  0x00    0    
  61	:  0000_0001  0x01    1    
  62	:  0101_0000  0x50   80  P  
  63	:  1010_1101  0xAD  173    
  64	:  0000_0000  0x00    0    
  65	:  0001_0110  0x16   22    
  66	:  0000_0101  0x05    5    
  67	:  0111_0000  0x70  112  p  
  68	:  0110_0100  0x64  100  d  
  69	:  0110_1110  0x6E  110  n  
  70	:  0111_0011  0x73  115  s  
  71	:  0011_0110  0x36   54  6  
  72	:  0000_1000  0x08    8    
  73	:  0111_0101  0x75  117  u  
  74	:  0110_1100  0x6C  108  l  
  75	:  0111_0100  0x74  116  t  
  76	:  0111_0010  0x72  114  r  
  77	:  0110_0001  0x61   97  a  
  78	:  0110_0100  0x64  100  d  
  79	:  0110_1110  0x6E  110  n  
  80	:  0111_0011  0x73  115  s  
  81	:  0000_0010  0x02    2    
  82	:  0110_0011  0x63   99  c  
  83	:  0110_1111  0x6F  111  o  
  84	:  0000_0010  0x02    2    
  85	:  0111_0101  0x75  117  u  
  86	:  0110_1011  0x6B  107  k  
  87	:  0000_0000  0x00    0    
  88	:  1100_0000  0xC0  192    
  89	:  0000_1100  0x0C   12    
  90	:  0000_0000  0x00    0    
  91	:  0000_0010  0x02    2    
  92	:  0000_0000  0x00    0    
  93	:  0000_0001  0x01    1    
  94	:  0000_0000  0x00    0    
  95	:  0000_0001  0x01    1    
  96	:  0101_0000  0x50   80  P  
  97	:  1010_1101  0xAD  173    
  98	:  0000_0000  0x00    0    
  99	:  0001_0100  0x14   20    
  100	:  0000_0101  0x05    5    
  101	:  0111_0000  0x70  112  p  
  102	:  0110_0100  0x64  100  d  
  103	:  0110_1110  0x6E  110  n  
  104	:  0111_0011  0x73  115  s  
  105	:  0011_0100  0x34   52  4  
  106	:  0000_1000  0x08    8    
  107	:  0111_0101  0x75  117  u  
  108	:  0110_1100  0x6C  108  l  
  109	:  0111_0100  0x74  116  t  
  110	:  0111_0010  0x72  114  r  
  111	:  0110_0001  0x61   97  a  
  112	:  0110_0100  0x64  100  d  
  113	:  0110_1110  0x6E  110  n  
  114	:  0111_0011  0x73  115  s  
  115	:  0000_0011  0x03    3    
  116	:  0110_1111  0x6F  111  o  
  117	:  0111_0010  0x72  114  r  
  118	:  0110_0111  0x67  103  g  
  119	:  0000_0000  0x00    0    
  120	:  1100_0000  0xC0  192    
  121	:  0000_1100  0x0C   12    
  122	:  0000_0000  0x00    0    
  123	:  0000_0010  0x02    2    
  124	:  0000_0000  0x00    0    
  125	:  0000_0001  0x01    1    
  126	:  0000_0000  0x00    0    
  127	:  0000_0001  0x01    1    
  128	:  0101_0000  0x50   80  P  
  129	:  1010_1101  0xAD  173    
  130	:  0000_0000  0x00    0    
  131	:  0001_0100  0x14   20    
  132	:  0000_0101  0x05    5    
  133	:  0111_0000  0x70  112  p  
  134	:  0110_0100  0x64  100  d  
  135	:  0110_1110  0x6E  110  n  
  136	:  0111_0011  0x73  115  s  
  137	:  0011_0010  0x32   50  2  
  138	:  0000_1000  0x08    8    
  139	:  0111_0101  0x75  117  u  
  140	:  0110_1100  0x6C  108  l  
  141	:  0111_0100  0x74  116  t  
  142	:  0111_0010  0x72  114  r  
  143	:  0110_0001  0x61   97  a  
  144	:  0110_0100  0x64  100  d  
  145	:  0110_1110  0x6E  110  n  
  146	:  0111_0011  0x73  115  s  
  147	:  0000_0011  0x03    3    
  148	:  0110_1110  0x6E  110  n  
  149	:  0110_0101  0x65  101  e  
  150	:  0111_0100  0x74  116  t  
  151	:  0000_0000  0x00    0    
  152	:  1100_0000  0xC0  192    
  153	:  0000_1100  0x0C   12    
  154	:  0000_0000  0x00    0    
  155	:  0000_0010  0x02    2    
  156	:  0000_0000  0x00    0    
  157	:  0000_0001  0x01    1    
  158	:  0000_0000  0x00    0    
  159	:  0000_0001  0x01    1    
  160	:  0101_0000  0x50   80  P  
  161	:  1010_1101  0xAD  173    
  162	:  0000_0000  0x00    0    
  163	:  0000_1000  0x08    8    
  164	:  0000_0101  0x05    5    
  165	:  0111_0000  0x70  112  p  
  166	:  0110_0100  0x64  100  d  
  167	:  0110_1110  0x6E  110  n  
  168	:  0111_0011  0x73  115  s  
  169	:  0011_0001  0x31   49  1  
  170	:  1100_0000  0xC0  192    
  171	:  1000_1010  0x8A  138    
  172	:  1100_0000  0xC0  192    
  173	:  0000_1100  0x0C   12    
  174	:  0000_0000  0x00    0    
  175	:  0000_0010  0x02    2    
  176	:  0000_0000  0x00    0    
  177	:  0000_0001  0x01    1    
  178	:  0000_0000  0x00    0    
  179	:  0000_0001  0x01    1    
  180	:  0101_0000  0x50   80  P  
  181	:  1010_1101  0xAD  173    
  182	:  0000_0000  0x00    0    
  183	:  0001_0101  0x15   21    
  184	:  0000_0101  0x05    5    
  185	:  0111_0000  0x70  112  p  
  186	:  0110_0100  0x64  100  d  
  187	:  0110_1110  0x6E  110  n  
  188	:  0111_0011  0x73  115  s  
  189	:  0011_0101  0x35   53  5  
  190	:  0000_1000  0x08    8    
  191	:  0111_0101  0x75  117  u  
  192	:  0110_1100  0x6C  108  l  
  193	:  0111_0100  0x74  116  t  
  194	:  0111_0010  0x72  114  r  
  195	:  0110_0001  0x61   97  a  
  196	:  0110_0100  0x64  100  d  
  197	:  0110_1110  0x6E  110  n  
  198	:  0111_0011  0x73  115  s  
  199	:  0000_0100  0x04    4    
  200	:  0110_1001  0x69  105  i  
  201	:  0110_1110  0x6E  110  n  
  202	:  0110_0110  0x66  102  f  
  203	:  0110_1111  0x6F  111  o  
  204	:  0000_0000  0x00    0    
  205	:  1100_0000  0xC0  192    
  206	:  0000_1100  0x0C   12    
  207	:  0000_0000  0x00    0    
  208	:  0000_0010  0x02    2    
  209	:  0000_0000  0x00    0    
  210	:  0000_0001  0x01    1    
  211	:  0000_0000  0x00    0    
  212	:  0000_0001  0x01    1    
  213	:  0101_0000  0x50   80  P  
  214	:  1010_1101  0xAD  173    
  215	:  0000_0000  0x00    0    
  216	:  0000_1000  0x08    8    
  217	:  0000_0101  0x05    5    
  218	:  0111_0101  0x75  117  u  
  219	:  0110_0100  0x64  100  d  
  220	:  0110_1110  0x6E  110  n  
  221	:  0111_0011  0x73  115  s  
  222	:  0011_0010  0x32   50  2  
  223	:  1100_0000  0xC0  192    
  224	:  1000_1010  0x8A  138    
  225	:  1100_0000  0xC0  192    
  226	:  0000_1100  0x0C   12    
  227	:  0000_0000  0x00    0    
  228	:  0000_0010  0x02    2    
  229	:  0000_0000  0x00    0    
  230	:  0000_0001  0x01    1    
  231	:  0000_0000  0x00    0    
  232	:  0000_0001  0x01    1    
  233	:  0101_0000  0x50   80  P  
  234	:  1010_1101  0xAD  173    
  235	:  0000_0000  0x00    0    
  236	:  0000_1000  0x08    8    
  237	:  0000_0101  0x05    5    
  238	:  0111_0101  0x75  117  u  
  239	:  0110_0100  0x64  100  d  
  240	:  0110_1110  0x6E  110  n  
  241	:  0111_0011  0x73  115  s  
  242	:  0011_0001  0x31   49  1  
  243	:  1100_0000  0xC0  192    
  244	:  1000_1010  0x8A  138    
  245	:  1100_0000  0xC0  192    
  246	:  0000_1100  0x0C   12    
  247	:  0000_0000  0x00    0    
  248	:  0000_0010  0x02    2    
  249	:  0000_0000  0x00    0    
  250	:  0000_0001  0x01    1    
  251	:  0000_0000  0x00    0    
  252	:  0000_0001  0x01    1    
  253	:  0101_0000  0x50   80  P  
  254	:  1010_1101  0xAD  173    
  255	:  0000_0000  0x00    0    
  256	:  0000_1000  0x08    8    
  257	:  0000_0101  0x05    5    
  258	:  0111_0000  0x70  112  p  
  259	:  0110_0100  0x64  100  d  
  260	:  0110_1110  0x6E  110  n  
  261	:  0111_0011  0x73  115  s  
  262	:  0011_0011  0x33   51  3  
  263	:  1100_0000  0xC0  192    
  264	:  0110_1010  0x6A  106  j  
  265	:  1100_0000  0xC0  192    
  266	:  1010_0100  0xA4  164    
  267	:  0000_0000  0x00    0    
  268	:  0000_0001  0x01    1    
  269	:  0000_0000  0x00    0    
  270	:  0000_0001  0x01    1    
  271	:  0000_0000  0x00    0    
  272	:  0000_0000  0x00    0    
  273	:  1110_1110  0xEE  238    
  274	:  0101_1001  0x59   89  Y  
  275	:  0000_0000  0x00    0    
  276	:  0000_0100  0x04    4    
  277	:  1100_1100  0xCC  204    
  278	:  0100_1010  0x4A   74  J  
  279	:  0110_1100  0x6C  108  l  
  280	:  0000_0001  0x01    1    
  281	:  1100_0000  0xC0  192    
  282	:  1000_0100  0x84  132    
  283	:  0000_0000  0x00    0    
  284	:  0000_0001  0x01    1    
  285	:  0000_0000  0x00    0    
  286	:  0000_0001  0x01    1    
  287	:  0000_0000  0x00    0    
  288	:  0000_0000  0x00    0    
  289	:  1110_1110  0xEE  238    
  290	:  0101_1001  0x59   89  Y  
  291	:  0000_0000  0x00    0    
  292	:  0000_0100  0x04    4    
  293	:  1100_1100  0xCC  204    
  294	:  0100_1010  0x4A   74  J  
  295	:  0110_1101  0x6D  109  m  
  296	:  0000_0001  0x01    1    
  297	:  1100_0001  0xC1  193    
  298	:  0000_0001  0x01    1    
  299	:  0000_0000  0x00    0    
  300	:  0000_0001  0x01    1    
  301	:  0000_0000  0x00    0    
  302	:  0000_0001  0x01    1    
  303	:  0000_0000  0x00    0    
  304	:  0000_0001  0x01    1    
  305	:  0010_0101  0x25   37  %  
  306	:  1010_0110  0xA6  166    
  307	:  0000_0000  0x00    0    
  308	:  0000_0100  0x04    4    
  309	:  1100_0111  0xC7  199    
  310	:  0000_0111  0x07    7    
  311	:  0100_0100  0x44   68  D  
  312	:  0000_0001  0x01    1    
  313	:  1100_0000  0xC0  192    
  314	:  0110_0100  0x64  100  d  
  315	:  0000_0000  0x00    0    
  316	:  0000_0001  0x01    1    
  317	:  0000_0000  0x00    0    
  318	:  0000_0001  0x01    1    
  319	:  0000_0000  0x00    0    
  320	:  0000_0001  0x01    1    
  321	:  0010_0101  0x25   37  %  
  322	:  1010_0110  0xA6  166    
  323	:  0000_0000  0x00    0    
  324	:  0000_0100  0x04    4    
  325	:  1100_0111  0xC7  199    
  326	:  0000_0111  0x07    7    
  327	:  0100_0101  0x45   69  E  
  328	:  0000_0001  0x01    1    
  329	:  1100_0000  0xC0  192    
  330	:  1011_1000  0xB8  184    
  331	:  0000_0000  0x00    0    
  332	:  0000_0001  0x01    1    
  333	:  0000_0000  0x00    0    
  334	:  0000_0001  0x01    1    
  335	:  0000_0000  0x00    0    
  336	:  0000_0001  0x01    1    
  337	:  0010_0101  0x25   37  %  
  338	:  1010_0110  0xA6  166    
  339	:  0000_0000  0x00    0    
  340	:  0000_0100  0x04    4    
  341	:  1100_1100  0xCC  204    
  342	:  0100_1010  0x4A   74  J  
  343	:  0111_0010  0x72  114  r  
  344	:  0000_0001  0x01    1    
  345	:  1100_0000  0xC0  192    
  346	:  0100_0010  0x42   66  B  
  347	:  0000_0000  0x00    0    
  348	:  0000_0001  0x01    1    
  349	:  0000_0000  0x00    0    
  350	:  0000_0001  0x01    1    
  351	:  0000_0000  0x00    0    
  352	:  0000_0001  0x01    1    
  353	:  0010_0101  0x25   37  %  
  354	:  1010_0110  0xA6  166    
  355	:  0000_0000  0x00    0    
  356	:  0000_0100  0x04    4    
  357	:  1100_1100  0xCC  204    
  358	:  0100_1010  0x4A   74  J  
  359	:  0111_0011  0x73  115  s  
  360	:  0000_0001  0x01    1    
  361	:  1100_0000  0xC0  192    
  362	:  1110_1101  0xED  237    
  363	:  0000_0000  0x00    0    
  364	:  0000_0001  0x01    1    
  365	:  0000_0000  0x00    0    
  366	:  0000_0001  0x01    1    
  367	:  0000_0000  0x00    0    
  368	:  0000_0001  0x01    1    
  369	:  0010_0101  0x25   37  %  
  370	:  1010_0110  0xA6  166    
  371	:  0000_0000  0x00    0    
  372	:  0000_0100  0x04    4    
  373	:  1100_1100  0xCC  204    
  374	:  0100_0101  0x45   69  E  
  375	:  1110_1010  0xEA  234    
  376	:  0000_0001  0x01    1    
  377	:  1100_0000  0xC0  192    
  378	:  1101_1001  0xD9  217    
  379	:  0000_0000  0x00    0    
  380	:  0000_0001  0x01    1    
  381	:  0000_0000  0x00    0    
  382	:  0000_0001  0x01    1    
  383	:  0000_0000  0x00    0    
  384	:  0000_0001  0x01    1    
  385	:  0010_0101  0x25   37  %  
  386	:  1010_0110  0xA6  166    
  387	:  0000_0000  0x00    0    
  388	:  0000_0100  0x04    4    
  389	:  1100_1100  0xCC  204    
  390	:  0100_1010  0x4A   74  J  
  391	:  0110_0101  0x65  101  e  
  392	:  0000_0001  0x01    1    |;

#; <<>> dig.pl 1.11 <<>> -d -t aaaa arpa.com
#;;
#;; Got answer.
#;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19804
#;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 8, ADDITIONAL: 8
#
#;; QUESTION SECTION:
#;arpa.com.		IN	AAAA
#
#;; ANSWER SECTION:
#arpa.com.	16	IN	AAAA	2607:F2F8:A570:0:0:0:0:2 
#
#;; AUTHORITY SECTION:
#arpa.com.	86189	IN	NS	pdns6.ultradns.co.uk. 
#arpa.com.	86189	IN	NS	pdns4.ultradns.org. 
#arpa.com.	86189	IN	NS	pdns2.ultradns.net. 
#arpa.com.	86189	IN	NS	pdns1.ultradns.net. 
#arpa.com.	86189	IN	NS	pdns5.ultradns.info. 
#arpa.com.	86189	IN	NS	udns2.ultradns.net. 
#arpa.com.	86189	IN	NS	udns1.ultradns.net. 
#arpa.com.	86189	IN	NS	pdns3.ultradns.org. 
#
#;; ADDITIONAL SECTION:
#pdns1.ultradns.net.	61017	IN	A	204.74.108.1 
#pdns2.ultradns.net.	61017	IN	A	204.74.109.1 
#pdns3.ultradns.org.	75174	IN	A	199.7.68.1 
#pdns4.ultradns.org.	75174	IN	A	199.7.69.1 
#pdns5.ultradns.info.	75174	IN	A	204.74.114.1 
#pdns6.ultradns.co.uk.	75174	IN	A	204.74.115.1 
#udns1.ultradns.net.	75174	IN	A	204.69.234.1 
#udns2.ultradns.net.	75174	IN	A	204.74.101.1 
#
#;; Query time: 67 ms
#;; SERVER: 192.168.1.171#53(192.168.1.171)
#;; WHEN: Sun Oct  9 15:11:23 2011
#;; MSG SIZE rcvd: 393 -- XFR size: 18 records
#
 
sub makebuf {
  my $dp = shift;
  my @data = split("\n",$$dp);
  my $off = 0;
  my $buffer = '';
  foreach (@data) {
    $_ =~ /0x.{2}\s+(\d+)/;
    $off = put1char(\$buffer,$off,$1);
  }
  return \$buffer;
}
my $qbp = makebuf(\$ques2);
my $abp = makebuf(\$ans2);

## test 2	set up buffer for processing
my($get,$put,$parse) = new Net::DNS::ToolKit::RR;

my $dig = Net::DNS::Dig->new(PeerAddr => '127.1');
$dig->{SERVER} = '127.1';
$dig->{ELAPSED} = 65;

$dig->_proc_body($abp,$qbp,$get,$put);
my $obj = $dig->to_text;

my $exp = q|174	= {
	'ADDITIONAL'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns1.ultradns.net.',
		'RDATA'	=> ['204.74.108.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 61017,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns2.ultradns.net.',
		'RDATA'	=> ['204.74.109.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 61017,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns3.ultradns.org.',
		'RDATA'	=> ['199.7.68.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns4.ultradns.org.',
		'RDATA'	=> ['199.7.69.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns5.ultradns.info.',
		'RDATA'	=> ['204.74.114.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns6.ultradns.co.uk.',
		'RDATA'	=> ['204.74.115.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'udns1.ultradns.net.',
		'RDATA'	=> ['204.69.234.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'udns2.ultradns.net.',
		'RDATA'	=> ['204.74.101.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
],
	'ANSWER'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['2607:F2F8:A570:0:0:0:0:2',],
		'RDLEN'	=> 16,
		'TTL'	=> 16,
		'TYPE'	=> 'AAAA',
	},
],
	'AUTHORITY'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns6.ultradns.co.uk.',],
		'RDLEN'	=> 22,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns4.ultradns.org.',],
		'RDLEN'	=> 20,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns2.ultradns.net.',],
		'RDLEN'	=> 20,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns1.ultradns.net.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns5.ultradns.info.',],
		'RDLEN'	=> 21,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['udns2.ultradns.net.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['udns1.ultradns.net.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns3.ultradns.org.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
],
	'BYTES'	=> 393,
	'Class'	=> 'IN',
	'ELAPSED'	=> 65,
	'HEADER'	=> {
		'AA'	=> 0,
		'AD'	=> 0,
		'ANCOUNT'	=> 1,
		'ARCOUNT'	=> 8,
		'CD'	=> 0,
		'ID'	=> 19804,
		'MBZ'	=> 0,
		'NSCOUNT'	=> 8,
		'OPCODE'	=> 'QUERY',
		'QDCOUNT'	=> 1,
		'QR'	=> 1,
		'RA'	=> 1,
		'RCODE'	=> 'NOERROR',
		'RD'	=> 1,
		'TC'	=> 0,
	},
	'NRECS'	=> 18,
	'PeerAddr'	=> ['127.1',],
	'PeerPort'	=> 53,
	'Proto'	=> 'UDP',
	'QUESTION'	=> [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'TYPE'	=> 'AAAA',
	},
],
	'Recursion'	=> 256,
	'SERVER'	=> '127.1',
	'TEXT'	=> '
; <<>> Net::DNS::Dig 0.01 <<>> -t aaaa arpa.com.
;;
;; Got answer.
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19804
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 8, ADDITIONAL: 8

;; QUESTION SECTION:
;arpa.com.		IN	AAAA

;; ANSWER SECTION:
arpa.com.	16	IN	AAAA	 2607:F2F8:A570:0:0:0:0:2

;; AUTHORITY SECTION:
arpa.com.	86189	IN	NS	 pdns6.ultradns.co.uk.
arpa.com.	86189	IN	NS	 pdns4.ultradns.org.
arpa.com.	86189	IN	NS	 pdns2.ultradns.net.
arpa.com.	86189	IN	NS	 pdns1.ultradns.net.
arpa.com.	86189	IN	NS	 pdns5.ultradns.info.
arpa.com.	86189	IN	NS	 udns2.ultradns.net.
arpa.com.	86189	IN	NS	 udns1.ultradns.net.
arpa.com.	86189	IN	NS	 pdns3.ultradns.org.

;; ADDITIONAL SECTION:
pdns1.ultradns.net.	61017	IN	A	 204.74.108.1
pdns2.ultradns.net.	61017	IN	A	 204.74.109.1
pdns3.ultradns.org.	75174	IN	A	 199.7.68.1
pdns4.ultradns.org.	75174	IN	A	 199.7.69.1
pdns5.ultradns.info.	75174	IN	A	 204.74.114.1
pdns6.ultradns.co.uk.	75174	IN	A	 204.74.115.1
udns1.ultradns.net.	75174	IN	A	 204.69.234.1
udns2.ultradns.net.	75174	IN	A	 204.74.101.1

;; Query time: 65 ms
;; SERVER: 127.0.0.1# 53(127.1)
;; WHEN: Mon Oct  3 13:41:57 2011
;; MSG SIZE rcvd: 393 -- XFR size: 18 records
',
	'Timeout'	=> 15,
	'_SS'	=> {
		'127.1'	=> '  ',
	},
};
|;

my $got = Dumper($obj);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

########################################

## test 3 - 22
my @section = ('', qw( QUESTION ANSWER AUTHORITY ADDITIONAL ));
my @expected = (
			# test 3, 4
q|8	= [{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['&òø¥p         ',],
		'RDLEN'	=> 16,
		'TTL'	=> 16,
		'TYPE'	=> 28,
	},
];
|,
			# test 5, 6
q|8	= [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['2607:F2F8:A570:0:0:0:0:2',],
		'RDLEN'	=> 16,
		'TTL'	=> 16,
		'TYPE'	=> 'AAAA',
	},
];
|,
			# test 7, 8
q|4	= [{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'TYPE'	=> 28,
	},
];
|,
			# test 9, 10
q|4	= [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'TYPE'	=> 'AAAA',
	},
];
|,
			# test 11, 12
q|8	= [{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['&òø¥p         ',],
		'RDLEN'	=> 16,
		'TTL'	=> 16,
		'TYPE'	=> 28,
	},
];
|,
			# test 13, 14
q|8	= [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['2607:F2F8:A570:0:0:0:0:2',],
		'RDLEN'	=> 16,
		'TTL'	=> 16,
		'TYPE'	=> 'AAAA',
	},
];
|,
			# test 15, 16
q|64	= [{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['pdns6.ultradns.co.uk',],
		'RDLEN'	=> 22,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['pdns4.ultradns.org',],
		'RDLEN'	=> 20,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['pdns2.ultradns.net',],
		'RDLEN'	=> 20,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['pdns1.ultradns.net',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['pdns5.ultradns.info',],
		'RDLEN'	=> 21,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['udns2.ultradns.net',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['udns1.ultradns.net',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'arpa.com',
		'RDATA'	=> ['pdns3.ultradns.org',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 2,
	},
];
|,
			# test 17, 18
q|64	= [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns6.ultradns.co.uk.',],
		'RDLEN'	=> 22,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns4.ultradns.org.',],
		'RDLEN'	=> 20,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns2.ultradns.net.',],
		'RDLEN'	=> 20,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns1.ultradns.net.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns5.ultradns.info.',],
		'RDLEN'	=> 21,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['udns2.ultradns.net.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['udns1.ultradns.net.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'arpa.com.',
		'RDATA'	=> ['pdns3.ultradns.org.',],
		'RDLEN'	=> 8,
		'TTL'	=> 86189,
		'TYPE'	=> 'NS',
	},
];
|,
			# test 19, 20
q|64	= [{
		'CLASS'	=> 1,
		'NAME'	=> 'pdns1.ultradns.net',
		'RDATA'	=> ['ÌJl',],
		'RDLEN'	=> 4,
		'TTL'	=> 61017,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'pdns2.ultradns.net',
		'RDATA'	=> ['ÌJm',],
		'RDLEN'	=> 4,
		'TTL'	=> 61017,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'pdns3.ultradns.org',
		'RDATA'	=> ['ÇD',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'pdns4.ultradns.org',
		'RDATA'	=> ['ÇE',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'pdns5.ultradns.info',
		'RDATA'	=> ['ÌJr',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'pdns6.ultradns.co.uk',
		'RDATA'	=> ['ÌJs',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'udns1.ultradns.net',
		'RDATA'	=> ['ÌEê',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 1,
	},
{
		'CLASS'	=> 1,
		'NAME'	=> 'udns2.ultradns.net',
		'RDATA'	=> ['ÌJe',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 1,
	},
];
|,
			# test 21, 22
q|64	= [{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns1.ultradns.net.',
		'RDATA'	=> ['204.74.108.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 61017,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns2.ultradns.net.',
		'RDATA'	=> ['204.74.109.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 61017,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns3.ultradns.org.',
		'RDATA'	=> ['199.7.68.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns4.ultradns.org.',
		'RDATA'	=> ['199.7.69.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns5.ultradns.info.',
		'RDATA'	=> ['204.74.114.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'pdns6.ultradns.co.uk.',
		'RDATA'	=> ['204.74.115.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'udns1.ultradns.net.',
		'RDATA'	=> ['204.69.234.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
{
		'CLASS'	=> 'IN',
		'NAME'	=> 'udns2.ultradns.net.',
		'RDATA'	=> ['204.74.101.1',],
		'RDLEN'	=> 4,
		'TTL'	=> 75174,
		'TYPE'	=> 'A',
	},
];
|,
);

sub checkdata {
  for (my($i,$k) = (0,0); $i <= $#section; $i++, $k+=2) {

## test 3	get data pointer, binary
    my $rv = $dig->data($section[$i]);
    my $exp = $expected[$k];
    my $got = Dumper($rv);
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
    &ok;

## test 4	validate array mode
    my @rv = $dig->data($section[$i]);
    $got = Dumper(\@rv);
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
    &ok;

## test 5	get data pointer, text
    $rv = $obj->data($section[$i]);
    $exp = $expected[$k+1];
    $got = Dumper($rv);
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
    &ok;

## test 4	validate array mode
    @rv = $obj->data($section[$i]);
    $got = Dumper(\@rv);
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
    &ok;
  }
}
&checkdata;

## test 23	test for bad section name
$exp = q|0	= [];
|;
my $rv = $dig->data('random');
$got = Dumper($rv);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

## test 24	validate array respose
my @rv = $dig->data('random');
$got = Dumper(\@rv);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

