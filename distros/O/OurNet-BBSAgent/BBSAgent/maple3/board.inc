# $File: //depot/OurNet-BBSAgent/BBSAgent/maple3/board.inc $ $Author: autrijus $
# $Revision: #5 $ $Change: 2895 $ $DateTime: 2002/01/17 06:37:53 $

Maple3 Board

load maple3.base
setv escape	\cU

=board
call main
send b\n
send s
wait 名稱
send $[board]\n\x20\x20
wait 板主：
wait 文  章  標  題

=board_list_last
call board $[board]
send 1\n\x24h\x20 # 1, $, h, space
wait 板主：
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
till 板主：
exit

# 簽名檔 post 前就問
=article_post_raw
call board $[board]
send \cP$[title]\n0\n$[body]
# clean header
send \cS\cY\cY\cY\cY
# save
send \cX
send s\n
wait (E)繼續編輯 (W)強制寫入？[E]
  or \e[m
doif $[1]
    send w\n
endo
send \x20
exit
