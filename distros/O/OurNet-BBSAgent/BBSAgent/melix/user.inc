# $File: //depot/OurNet-BBSAgent/BBSAgent/melix/user.inc $ $Author: autrijus $
# $Revision: #3 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $

Melix User

load melix.base

=mail_send
call mail
send s\n
wait \e[7m
send $[receiver]\n
wait \e[7m
send $[subject]\n
send $[content]\x18
wait \e[7m
send s\n\n
wait \e[7m
doif $[savelocal]
    send \n
else
    send n\n
endo
send \n

=configure
call main
send c\n
wait \e[;H\e[2J\e[1;44;37m
till ]\e[31m

=mood_get
call configure
send m\n
wait \e[1;31m\x20
till \x20\e[
wait \e[7m
send \n
exit

=mood_set
call configure
send m\n
wait \e[7m
send 0\n$[mood]\n
exit

=mail
call main
send m\n
wait \e[;H\e[2J\e[1;44;37m
till ]\e[31m

