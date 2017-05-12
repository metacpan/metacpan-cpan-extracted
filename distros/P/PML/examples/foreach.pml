#
# Example file for the foreach PML function
#
#
# foreach will execute the code in it's block one time
# for each argument you give it, setting the variable ${.}
# to the current argument
#
#
# it is easy to use and understand if you get the code below
#
#
@set("t1", 1)
@set("t2", 2)
@set("t3", 3)

@foreach(${t1}, ${t2}, ${t3})
{
	the current number is ${.}
}

#
#
# this is a little easier on the hands
#
#
@set("t", "4", "5", "6")
@foreach(${t})
{ 
	oh, now we see ${.} 
}
