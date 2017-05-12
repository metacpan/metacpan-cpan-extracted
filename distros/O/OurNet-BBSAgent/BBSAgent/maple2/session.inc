# $File: //depot/OurNet-BBSAgent/BBSAgent/maple2/session.inc $ $Author: autrijus $
# $Revision: #7 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $
# Contributed by Smartboy <kcwu@ck.tp.edu.tw>

Maple2/SOB Session

load maple2.base

=message
wait \e[K\e[1;33;46m★
till \e[37;45m\x20
till \x20\e[m
send x
exit

=message_reply
send \x12
wait 過去
send $[message]\n
wait [Y/n]
send \n
exit

# XXX: check if the cursor points to the recipient!
=message_send
call talk_users
send /
wait 代號：
send $[receiver]\n
send w
wait Call-In
send $[message]\n
wait [Y/n]
send \n
exit

=talk
call main
send t\n
wait 聊天說話
till $[pager]

=talk_users
call talk
send u\n
wait m/休閒聊天|好友列表/
till (TAB/f)

=talk_users_refresh
send \x15
wait 休閒聊天
till (TAB/f)
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

=query_user
call talk_users
send /
wait 代號：
send $[id]\n
send q
wait 《ＩＤ暱稱》
till 繼續
send \x20
exit 
