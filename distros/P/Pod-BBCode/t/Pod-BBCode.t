# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Pod-BBCode.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;

BEGIN { use_ok('Pod::BBCode') };

#########################

# Basic
my $p=new Pod::BBCode;
ok($p);
ok(ref($p));
ok($p->isa('Pod::BBCode'));

# Head
my %tests=(
    "\n=head1 Heading 1\n\n"    => "\n[size=5]Heading 1[/size]\n",
    "\n=head2 Heading 2\n\n"    => "\n[size=4]Heading 2[/size]\n",
    "\n=head3 Heading 3\n\n"    => "\n[size=3]Heading 3[/size]\n",
    "\n=head4 Heading 4\n\n"    => "\n[size=2]Heading 4[/size]\n",
);
while(my ($pod,$expected)=each %tests) {
    my $result;
    my ($ih,$oh);
    open($ih,"<",\$pod);
    open($oh,">",\$result);
    $p->parse_from_filehandle($ih,$oh);
    ok($result eq $expected);
}

# Sequence
%tests=(
    "\n=head1 B<Heading 1>\n\n" => "\n[size=5][b]Heading 1[/b][/size]\n",
    "\n=head2 I<Heading 2>\n\n" => "\n[size=4][i]Heading 2[/i][/size]\n",
    "\n=head3 F<Heading 3>\n\n" => "\n[size=3][pre]Heading 3[/pre][/size]\n",
    "\n=head4 C<Heading 4>\n\n" => "\n[size=2][pre]Heading 4[/pre][/size]\n",
);
while(my ($pod,$expected)=each %tests) {
    my $result;
    my ($ih,$oh);
    open($ih,"<",\$pod);
    open($oh,">",\$result);
    $p->parse_from_filehandle($ih,$oh);
    ok($result eq $expected);
}

# Verbatim
%tests=(
    <<EOF1  => <<EOF2,

=pod

    verbatim paragraph
    on two lines

=cut

EOF1
[code]
    verbatim paragraph
    on two lines
[/code]
EOF2
);
while(my ($pod,$expected)=each %tests) {
    my $result;
    my ($ih,$oh);
    open($ih,"<",\$pod);
    open($oh,">",\$result);
    $p->parse_from_filehandle($ih,$oh);
    ok($result eq $expected);
}

