@include(../common/common.pmlh)
@SECTION(@CODE(prepend))

@CODE(prepend) is just like @CODE(append) except that the
string is added to the front of the variable, with a space
between the string and the variable. If the variable is an
array, the list is unshifted on to the array.
