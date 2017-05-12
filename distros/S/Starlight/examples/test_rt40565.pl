#!perl

@a = $s = '1st';
{
    local ($s, @a);
    @a = $s = '2nd';
    {
        local ($s, @a);
        @a = $s = '3rd';
        $me = fork() ? 'parent' : 'child';
        sleep 1 if $me eq 'parent'; # let the child go first
        print "Scalar: $s - $me$/";
        print "Array: @a - $me$/";
    }
    # The scalar is now undefined in the child:
    print "Scalar: $s - $me$/";
    print "Array: @a - $me$/";
}
# Triggers an "illegal operation" in the child:
print "Scalar: $s - $me$/";
print "Array: @a - $me$/";
wait;
