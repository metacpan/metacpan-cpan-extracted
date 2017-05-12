use lib (-e 't' ? 't' : 'test'), 'inc';
use TestModuleCompile tests => 9;

filters({ perl => 'process' });

no_diff;
run_is perl => 'folded';

sub process { Module::Compile->pmc_fold_blocks(shift) }

__DATA__

=== Fold a heredoc whilst preserving ~s
--- perl
my $x = "~ ~~ ~~~ ~~~~ ~~~~~";

sub foo {
    my $self = shift;
    $self->baz(<<END);
sub bar {
    print "bar";
} 
END
}

--- folded
my $x = "~ ~~ ~~~ ~~~~ ~~~~~";

sub foo {
    my $self = shift;
    $self->baz(<<END);
8dc957d71f448e926d28ebe8444d5b33c1d69dc2
END
}


=== Folded heredoc, ignoring <<=
--- perl
my $x = 1234;
$x <<= 3;
my $y = 4321;

sub foo {
    my $self = shift;
    $self->baz(<<END);
sub bar {
    print "bar";
} 
END
}

--- folded
my $x = 1234;
$x <<= 3;
my $y = 4321;

sub foo {
    my $self = shift;
    $self->baz(<<END);
8dc957d71f448e926d28ebe8444d5b33c1d69dc2
END
}


=== Empty string termination
--- perl
sub foo {
    my $self = shift;
    $self->baz(<<'');
sub bar {
    print "bar";
} 

}

--- folded
sub foo {
    my $self = shift;
    $self->baz(<<'');
8dc957d71f448e926d28ebe8444d5b33c1d69dc2

}


=== A double heredoc
--- perl
sub foo {
    my $self = shift;
    $self->baz(<<'THIS', <<"THAT");
THERE
THAT
THIS
THIS
THAT
THERE
}

--- folded
sub foo {
    my $self = shift;
    $self->baz(<<'THIS', <<"THAT");
fe5485c0595b48c3a4126af814e8d53517ecd1d8
THIS
5b35b1abf837461ac7f9b09d42f8560601b028f6
THAT
THERE
}

=== A double heredoc. Same END token
--- perl
sub foo {
    my $self = shift;
    $self->baz(<<END, <<END);
THERE
THAT
END
THIS
END
THERE
}

--- folded
sub foo {
    my $self = shift;
    $self->baz(<<END, <<END);
fe5485c0595b48c3a4126af814e8d53517ecd1d8
END
5b35b1abf837461ac7f9b09d42f8560601b028f6
END
THERE
}

=== A Heredoc inside Pod
--- perl
my $a = 1;

=head1 Stuffy Stuff

my $foo = <<END;

=cut

my $bar = <<END;
ONE
TWO
END
THREE

--- folded
my $a = 1;

=pod 6d44253d8e3ebb3bc202ea5a2585d542c7c3c57b
=cut

my $bar = <<END;
0a1177eb51a480f6ae3ff77264820e6068284b0f
END
THREE


=== A Heredoc inside comment block
--- perl
my $a = 1;

# my $foo = <<END;
# my $baz = <<END;

my $bar = <<END;
ONE
TWO
END
THREE

--- folded
my $a = 1;

# 04e1a5fcd227db0d2beed0a1dacadb4562451127

my $bar = <<END;
0a1177eb51a480f6ae3ff77264820e6068284b0f
END
THREE


=== Not a heredoc, but a literal "<<"
--- perl
(

    '<<'  => 
    '>>',

);
--- folded
(

    '<<'  => 
    '>>',

);
=== All kinds
--- perl
print "ok 1";

# $xxx = <<END;
# =head1 Hey1
# =cut
# __END__

=head1 Hey2
$xxx = <<END;
__END__
# comment
=cut

my $foo = <<'END';
__END__
$bar = <<BAR;
XXX
=head1 Hey3
=cut
END

print $foo;

__END__
$foo = <<FOO;
=head1 Hey4
# comment

--- folded
print "ok 1";

# 0aaf3d0e5f1c247fa72dd952df5728719b4f474e

=pod 401ec699fc81869e1c155a19c05ac9e9e622817b
=cut

my $foo = <<'END';
557737b9b1378f1b8ef45b92d739ddca273705f6
END

print $foo;

__DATA__
124fdf752349d6465bd0462bc8195df2ef333bc9

