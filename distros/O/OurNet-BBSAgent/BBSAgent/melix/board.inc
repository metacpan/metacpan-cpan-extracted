# $File: //depot/OurNet-BBSAgent/BBSAgent/melix/board.inc $ $Author: autrijus $
# $Revision: #4 $ $Change: 2895 $ $DateTime: 2002/01/17 06:37:53 $

Melix Board

load melix.base
setv escape	\cU

=board
call main
send s\n
wait \e[7m
send $[board]\n\x20\x20
wait \e[;H\e[2J\e[1;44;37m
wait \e[44m
wait \e[m

=board_list_last
call board $[board]
send 1\n\x24h\x20 # 1, $, h, space
wait \e[;H\e[2J\e[1;44;37m
wait \x0d>
till /
exit

=board_article_fetch_first
call board $[board]
send $[article]\n\n
wait \e[2J
till \e[0;34;46m
  or \e[34;46m
till \e[31;47m (
wait \e[m
exit

=board_article_fetch_next
send \n
till \e[0;34;46m
  or \e[34;46m
till \e[31;47m (
wait \e[m
exit

=board_article_fetch_last
send q
wait \e[;H\e[2J\e[1;44;37m
exit

=article_post_raw
call board $[board]
send \cP
wait \e[7m
send $[title]\n
wait \e[7m
send 0\n
send $[body]
# clean header
send \cS\cY\cY\cY\cY
send \cX
wait \e[7m
send s\n
wait (E)繼續編輯 (W)強制寫入？[E]
  or \e[m
doif $[1]
    send w\n
endo
send \x20
send \x20
exit 


