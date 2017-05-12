#!./perl -w

my @type = qw(Andalso Assign Backq Bang Body Cbody Nowait Brace Concat
Count Else Flat Dup Epilog Newfn Forin If Qword Orelse Pipe Pre Redir
Rmfn Args Subshell Case Switch Match Var Varsub While Word Lappend
Nmpipe);

for (sort @type) {
    print qq[  case n$_: return "$_";\n];
}

