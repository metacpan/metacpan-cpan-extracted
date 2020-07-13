package Multi;

sub foo { }
sub bar { }

{
package Multi::One;
    sub foo { }
    sub bar1 { }
}

{
    package Multi::Two;
    sub foo  { }
    sub bar2 { }

    {
        package Multi::Three;
        sub foo  { }
        sub bar3 { }
    }
}

sub Multi::Four::foo { }
sub Multi::Four::bar4 { }

1;
