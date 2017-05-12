@include(../common/common.pmlh)
@SECTION(The @CODE(perl) Function)

The @CODE(perl) function is used to eval perl code. This function does not take
any arguments, just a block. The code to eval should be in the block.
@BREAK()

You can access the PML variables inside the evaled perl by the hash %v.

@CODE_START()
	\@set(x, 1)
	\@perl{ \$v{x}++; undef}
@CODE_END()

The reason that you need the @CODE(undef) is because the output from the 
eval is injected into the output stream. Your Perl code will always
be evaled in list context.

@CODE_START()
	\@perl{ scalar localtime }
	\# puts the localtime into the output stream
@CODE_END()
