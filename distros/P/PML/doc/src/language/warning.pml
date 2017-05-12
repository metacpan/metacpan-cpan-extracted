@include(../common/common.pmlh)
@SECTION(@CODE(warning))

The @CODE(warning) function controls weather or
not PML will produce warning messages. By default,
warnings are turned off. Setting the warning flag
to a true value will turn them on.

@CODE_START()
	\@warning(1)
	\${new}
	\# this will produce a warning because
	\# new did not have a value
	\@perl{ldkj';;}
	\# warning above because the perl statement
	\# had syntax errors
@CODE_END()
