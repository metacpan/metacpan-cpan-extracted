# $File: //depot/OurNet-BBSAgent/BBSAgent/melix/base.inc $ $Author: autrijus $
# $Revision: #6 $ $Change: 2765 $ $DateTime: 2002/01/06 00:30:18 $

Melix Base

=login
wait \e[7m
send $[username]\n
doif $[password]
    wait \e[7m
    send $[password]\nn\n
endo
# login failure, unsaved article, kick multi-logins
send \n\n
# skips splash screens (if any)
send \x20\x20\x20

=main
send qqqqqqee
wait \e[;H\e[2J\e[1;44;37m
till ]\e[31m

=logoff
call main
send g\ng\ny\ny\n\n\n
exit
