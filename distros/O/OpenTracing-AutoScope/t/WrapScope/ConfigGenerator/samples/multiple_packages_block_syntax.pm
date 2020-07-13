package Multi {
    sub foo { }
    sub bar { }
}

{
    package Multi::Two;
    sub foo  { }
    sub bar2 { }

    package Multi::Three {
        sub foo  { }
        sub bar3 { }
    }

    {
        package Multi::One {
            sub foo  { }
            sub bar1 { }
        }
    }
}

1;
