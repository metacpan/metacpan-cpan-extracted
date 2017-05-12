
=Tables

\TABLE{bg=blue separator="|" border=2}

column 1  |  column 2  | column 3
xxxx      |  yyyy      |  zzzzz
uuuu      |  vvvv      |  wwwww

\END_TABLE


@|+crazy+@+colsep+|
column 1  |+crazy+@+colsep+|  column 2  |+crazy+@+colsep+| column 3
xxxx      |+crazy+@+colsep+|  yyyy      |+crazy+@+colsep+|  zzzzz
uuuu      |+crazy+@+colsep+|  vvvv      |+crazy+@+colsep+|  wwwww


\TABLE{bg=blue separator="|" border=2}

column 1
xxxx
uuuu

\END_TABLE


@|+crazy+@+colsep+|
column 1
xxxx
uuuu

\TABLE{bg=blue separator="|" border=2}

column 1  |  column 2  | column 3
xxxx
xxxx      |
uuuu      |  vvvv
uuuu      |  vvvv      |

\END_TABLE


@|+crazy+@+colsep+|
column 1  |+crazy+@+colsep+|  column 2  |+crazy+@+colsep+| column 3
xxxx
xxxx      |+crazy+@+colsep+|
uuuu      |+crazy+@+colsep+|  vvvv
uuuu      |+crazy+@+colsep+|  vvvv      |+crazy+@+colsep+|


\TABLE{separator="|"}
column 1  |  column 2
xxxx      |  yyyy      \END_TABLE


Inlined: \TABLE{bg=blue separator="|" border=2 rowseparator="+++"}
column 1 | column 2 | column 3 +++ xxxx | yyyy | zzzzz +++ uuuu |
vvvv | wwwww \END_TABLE


Nested 1: \TABLE{rowseparator="+++"} column 1 | column 2 |
\TABLE{rowseparator="%%%"} n1 | n2 %%% n3 | n4 \END_TABLE
+++ xxxx | yyyy | zzzzz +++ uuuu |
vvvv | wwwww \END_TABLE

@|
column 1 | column 2 | \TABLE{rowseparator="%%%"} n1 | n2 %%% n3 | n4 \END_TABLE
xxxx | yyyy | zzzzz
uuuu | vvvv | wwwww
