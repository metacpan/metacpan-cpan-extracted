# $File: //depot/OurNet-BBSAgent/BBSAgent/firebird2/board.inc $ $Author: autrijus $
# $Revision: #5 $ $Change: 2895 $ $DateTime: 2002/01/17 06:37:53 $
# Contributed by Smartboy <kcwu@ck.tp.edu.tw>

Firebird2 Board

load firebird2.base

setv headl \x0d?
setv headr :\x20(.+?)(?:,\x20信區:\x20.+)?$
setv headi 發信人,標\x20\x20題,發信站
setv escape \e\e
setv separator \e\[\\d;1H

setv bottom 時間

=board
call main
send s\n
wait 自動搜尋):
send $[board]\nr\n\x20
wait 板主:
till $[statustail]

=board_list_last
call board $[board]
send \x24\x0c
wait 板主:
wait \x0d>
till $[bottom]
exit

=board_article_fetch_first
call board $[board]
send $[article]\n\n
wait \e[J
till \e[1;44;31m[閱讀文章]
  or \e[1;44;32m下面還有喔
till 結束
wait m/\^X\x20?或\x20?p\x20\e\[m/
  or │\x20\x20\x20\x20\x20\e[m
exit

=board_article_fetch_next
send \x20
till \e[1;44;31m[閱讀文章]
  or \e[1;44;32m下面還有喔
till 結束
wait m/\^X\x20?或\x20?p\x20\e\[m/
  or │\x20\x20\x20\x20\x20\e[m
exit

=board_article_fetch_last
send q
wait $[statustail]
exit

=article_post_raw
call board $[board]
send \x10$[title]\n\n
send $[body]
send \cX
send s\n
send \x20
exit
