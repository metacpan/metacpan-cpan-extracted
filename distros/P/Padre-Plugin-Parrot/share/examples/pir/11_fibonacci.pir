.sub fibonacci
    .param int n
    .local int result
    result = 1
    if n == 0 goto return
    result = 1
    if n == 1 goto return
    .local int f1, f2, n1, n2
    n1 = n - 1
    n2 = n - 2
    f1 = fibonacci(n1)
    f2 = fibonacci(n2)
    result = f1 + f2

    return:
       .return (result)
.end

.sub anyname :main
    .local int maxnum
    maxnum = 10
    print "Fibonacci from 0 to "
    print maxnum
    print "\n"

    .local int result, i
    i = 0
    myloop:
    print i
    print '   '
    result = fibonacci(i)
    print result
    print "\n"
    inc i
    if i <= maxnum goto myloop

    print "done\n"
.end
