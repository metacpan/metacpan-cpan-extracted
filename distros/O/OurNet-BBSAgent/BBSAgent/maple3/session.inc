# $File: //depot/OurNet-BBSAgent/BBSAgent/maple3/session.inc $ $Author: autrijus $
# $Revision: #5 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $

Maple3 Session

load maple3.base

=message
wait \e[1;33;46m★
till \x20\e[37;45m\x20
till \x20\e[m
exit

=message_reply
send \x12
wait 回應
wait \e[23;1H
send $[message]\n
wait [Y]
send \n
wait \e[37;45m
wait \e[m
exit

=message_send
call talk_users
send /
wait 姓名：
send $[receiver]\n
wait $[receiver]
send s
wait Call-In：
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
wait 聊天說話
till Call機

=talk_users
call talk
send u\n
wait 休閒聊天
till (TAB/f)

=talk_users_refresh
send \x15
wait 休閒聊天
till (TAB/f)
exit
