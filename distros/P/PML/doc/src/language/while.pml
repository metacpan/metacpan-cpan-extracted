@include(../common/common.pmlh)
@SECTION(The @CODE(while) function)
@SUBSECTION(@CODE(while) loops)

The @CODE(while) function lets you repeat some text
over and over while some condition is true.

@CODE_START()
	\@set(condition, 1)
	\@set(i, 1)
	\@while(\${condition}) {
		Loop number ${i}
		@perl{ $v{i}++; undef}
		@if (@perl{ $v{i} == 3}) {
			@set(condition, 0)
		}
	}
@CODE_END()

That code produces:

@CODE_START()
	Loop number 1
	Loop number 2
	Loop number 3
@CODE_END()

@SUBSECTION(@CODE(until) loops)

You can use @CODE(until) instead of @CODE(while).
The only difference is that @CODE(until) only
loops while the condition is false.
