# $File: //depot/OurNet-BBSAgent/BBSAgent/maple2/board.inc $ $Author: autrijus $
# $Revision: #10 $ $Change: 2899 $ $DateTime: 2002/01/17 22:20:11 $
# Contributed by Smartboy <kcwu@ck.tp.edu.tw>

Maple2/SOB Board

load maple2.base

setv cursor	●
setv morehead	m/\e\[0?m\e\[(?:[\d;]+)m\x20\x20瀏覽\x20P./
setv moretail	m/\[q\]\e\[30m結束\x20\x20\x20\e\[0?m/
setv postsign	0 # 簽名檔在 post 後問
setv escape	\cU
setv leftparen	(
setv rightparen	)

# 假設在主選單及看板內, 都可以 select board
=board
send s
wait 名稱
send $[board]\n\x20\x20
wait 板主：
till 文章選讀

=board_list_last
call board $[board]
send 1\n\x24h\x20
wait 板主：
wait \x0d$[cursor]
till /
exit

=board_article_fetch_first
call board $[board]
send $[article]\n\n
wait m/\e\[2?J/
till $[morehead]
wait $[leftparen]
till $[rightparen]
wait $[moretail]
exit

=board_article_fetch_next
send \x20
till $[morehead]
wait $[leftparen]
till $[rightparen]
wait $[moretail]
exit

=board_article_fetch_last
send qq
wait 文章選讀
exit

=board_list_author
call board $[board]
send a$[author]\n
wait $[cursor]
till 文章選讀
exit

=article_post_raw
call board $[board]
send \cP$[title]\n
doif $[postsign]
else
  send 0\n
endo
send $[body]
#send \e,\cY\cY\cY\cY
send \cX
send \cXs\n
wait (E)繼續編輯 (W)強制寫入？[E]
  or \e[m
doif $[1]
    send w\n
endo
doif $[postsign]
  send 0\n
endo
send \x20
doif $[author]
    call article_edit_author $[author]
endo # ?
exit

=article_edit_author
send \x24E\cY\cY\cY\cY
# 1 empty 2 from 3 origin 4 --
send \cXs\n
wait 文章選讀
exit

=article_edit_raw
send E$[content]\x18
wait 檔案處理
send s\n
doif $[postsign]
  send 0\n
endo
send \x20
doif $[author]
    call article_edit_author $[author]
endo
exit
