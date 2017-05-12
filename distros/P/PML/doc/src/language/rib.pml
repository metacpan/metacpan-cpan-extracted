@include(../common/common.pmlh)
@SECTION(Replace If Blank (@CODE(rib)))

This PML function is very useful for HTML tables.
It is like a reversed @CODE(if) function. It takes
both an argument and a block. If the block turns out
to be empty, then the function will return the string
that was passed in the argument list. Here is an example
used inside HTML:

@CODE_START()
	@HTML_BRACKET(td)
	\@rib( &amp;nbsp; ) {
		\@if (condition) {
			text
		}
	}
	@HTML_BRACKET(/td)
@CODE_END()

If the @CODE(if) function from above does not
return any text, the @CODE(rib) function will 
place a &amp;nbsp; in the output stream.
