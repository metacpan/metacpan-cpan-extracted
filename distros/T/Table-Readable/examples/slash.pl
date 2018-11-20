#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Table::Readable 'read_table';
my $table =<<'EOF';
a: \  b     
%%c:
\

d

%%
%%e:

f

!


\
%%
EOF
my @entries = read_table ($table, scalar => 1);
for my $k (keys %{$entries[0]}) {
    my $v = $entries[0]{$k};
    $v =~ s/!$//;
    print "'$k' = '$v'\n";
}

