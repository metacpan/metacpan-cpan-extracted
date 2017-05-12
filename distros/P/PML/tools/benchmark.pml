#
# This is PML Code for benchmarking
#

@set('a',  5)
@set('b', 10)
@set('c', 20)
@set('d', 40)

@foreach (${a}, ${b}, ${c}, ${d})
{
	@perl {$v{'.'} *= 10}
}

@if (${a})
{
	this is a test
}
@elsif (${b})
{
	this is a test 2
}
@elsif (${c})
{
	this is a test 3
}
@elsif (${d})
{
	this is a test 4
}
@else
{
	test again
}

@setif('a', 400)
@append('b', again)
@prepend('c', what)

this is some text
here that should
be left alone
because it does not contain any PML makers or variables.
but in just a few lines
we are going to 
use some PML variables
so here is a "${a}"
and here is b "${b}"
and here is c "${c}"
and here is d "${d}"
and here is e eventhoug it is undef ${e} ${e} ${e}

@macro('TEST', 'VAR')
{
	@set('a', ${b})
	@set('b', ${c})
	@set('c', ${d})
	@set('d', ${VAR})
	
	wow, VAR is "${VAR}"
}

@TEST(this)
@TEST(is)
@TEST(a)
@TEST(test)

loading html module
@need(HTML)
done loading
