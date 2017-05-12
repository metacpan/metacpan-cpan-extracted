
=Tags

Simple: \TEST.
Guarded: \\TEST.
Sequence: \TEST\TOAST.

With body: \TOAST<toast>.
Sequence: \TEST<test>\TOAST<toast>.
Nested: \TEST<tested \TOAST<toast>>.

With parameters: \TEST{par1=p1 par2=p2}
Sequence: \TEST{t=test}\TOAST{t=toast}.

Complete: \TEST{t=test}<test>
Sequence: \TEST{t=test}<test>\TOAST{t=toast}<toast>.
Nested: \TEST{t=test}<tested \TOAST{t=toast}<toast>>.

Headline reference (forward): \REF{name="Tag in a headline"}.

=Tag in a \TEST<headline>

* \TEST<Tags>

# \TOAST<in>

:\FONT{color=blue}<item>: list \TEST<po\TOAST<i>nts>.

   And in
   a \TEST<block>.

<<EOM

  Tags are currently \TEST<not>
  processed in \TOAST<Verbatim blocks>.

EOM

String parameter: \TEST{t=test addr="http://www.perl.com"}<test>

Headline reference (backwards): \REF{name="Tag in a headline"}.