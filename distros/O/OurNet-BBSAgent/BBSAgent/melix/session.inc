# $File: //depot/OurNet-BBSAgent/BBSAgent/melix/session.inc $ $Author: autrijus $
# $Revision: #5 $ $Change: 2809 $ $DateTime: 2002/01/08 21:44:45 $

Melix Session

load melix.base

=message
wait \e[1;33;46m
wait m/../
till \x20\e[37;45m\x20
till \x20\e[m
exit

=message_reply
send \x12
wait \e[m
send $[message]\n
wait [Y]
send \n
wait \e[37;45m
wait \e[m
exit

=message_send
call talk_users
send /
wait \e[7m
send $[receiver]\n
wait $[receiver]
send s
wait \e[7m
send $[message]\n
wait [Y]
send \n
wait \e[m
exit

=chat_enter
call talk
send c\no\n\n
wait \x00\x00\x00\x00\x00

=chat_room
send /j $[room]\n
wait [$[room]]
exit

=chat_say
send $[message]\n
wait $[message]
exit

=chat_listen
wait ;1H\x00\x00\x00\x00\x00
till :\x20
  or *\x20
till \e[
exit

=chat_leave
send /bye\n
wait [C]
send c\n
goto main

=chat_message_send
send /m $[caller] $[message]\n
wait $[message]
exit

=talk
call main
send t\n
wait \e[;H\e[2J\e[1;44;37m
till ]\e[31m

=talk_users
call talk
send u\n
wait \e[;H\e[2J\e[1;44;37m
wait \e[44m
wait \e[m

=talk_users_refresh
send \x15
wait \e[;H\e[2J\e[1;44;37m
wait \e[44m
wait \e[m
exit
