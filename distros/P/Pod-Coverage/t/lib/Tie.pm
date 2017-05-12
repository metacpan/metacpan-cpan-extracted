package Tie;

=head1 NAME

Tie - stubs to make sure that TIE* and friends are skipped

=head1 METHODS

=item foo

blah blah

=cut

sub foo {
    print "I like pie\n";
}

sub TIESCALAR { print "foo"; }
sub TIEARRAY { print "foo"; }
sub TIEHASH { print "foo"; }
sub TIEHANDLE { print "foo"; }
sub FETCH { print "foo"; }
sub STORE { print "foo"; }
sub UNTIE { print "foo"; }
sub FETCHSIZE { print "foo"; }
sub STORESIZE { print "foo"; }
sub POP { print "foo"; }
sub PUSH { print "foo"; }
sub SHIFT { print "foo"; }
sub UNSHIFT { print "foo"; }
sub SPLICE { print "foo"; }
sub DELETE { print "foo"; }
sub EXISTS { print "foo"; }
sub EXTEND { print "foo"; }
sub CLEAR { print "foo"; }
sub FIRSTKEY { print "foo"; }
sub NEXTKEY { print "foo"; }
sub PRINT { print "foo"; }
sub PRINTF { print "foo"; }
sub WRITE { print "foo"; }
sub READLINE { print "foo"; }
sub GETC { print "foo"; }
sub READ { print "foo"; }
sub CLOSE { print "foo"; }
sub BINMODE { print "foo"; }
sub OPEN { print "foo"; }
sub EOF { print "foo"; }
sub FILENO { print "foo"; }
sub SEEK { print "foo"; }
sub TELL { print "foo"; }

1;
