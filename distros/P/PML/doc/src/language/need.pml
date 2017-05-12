@include(../common/common.pmlh)
@SECTION(Need)

The @CODE(need) function is used to load in a external PML Module.
It takes a list of PML Modules to load:

@CODE_START()
	\@need(CGI)
	\@need(LWP)
@CODE_END()

Note: these are PML modules, not Perl Modules
