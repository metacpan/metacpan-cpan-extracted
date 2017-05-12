@include(../common/common.pmlh)
@SECTION(@CODE(set))

The @CODE(set) function sets a variable. It takes
as it's arguments, a variable to set and the value(s)
to set it to.

@CODE_START()
	\@set(name, Peter)
	\#name is now set to Peter
	\${name}
@CODE_END()

If you give more then on value, the variable will
be set as an array. You can then access the 
individual values by number, starting at 0.

@CODE_START()
	\@set(cookies, peanutbuttter, peanutbutter chip, oatmeal)
	\${cookies[0]}
	\${cookies[1]}
	\${cookies[2]}
@CODE_END()
