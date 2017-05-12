.sub main
    .local int maxnum
    maxnum = 10
    print "Square from 1 to "
    print maxnum
    print "\n"
    .local int square, i
    i = 1
myloop:
    square = i * i
    # is the same as
    #mul square, i, i

    print i
    print ' * '
    print i
    print ' = '
    print square
    print "\n"
    inc i

    if i <= maxnum goto myloop
    # is the same as
    #le i, maxnum, myloop
    
    print "done\n"
.end