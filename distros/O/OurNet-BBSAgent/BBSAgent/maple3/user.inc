# $File: //depot/OurNet-BBSAgent/BBSAgent/maple3/user.inc $ $Author: autrijus $
# $Revision: #3 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $

Maple3 User

load maple3.base

=mail_send
call mail
send s\n
wait 代號：
send $[receiver]\n
wait 主題：
send $[subject]\n
wait 編輯文章
send $[content]\x18
wait 檔案處理
send s\n\n
wait 底稿
doif $[savelocal]
    send \n
else
    send n\n
endo
send \n

=configure
call main
send c\n
wait 其他功能
till Call機

=mood_get
call configure
send m\n
wait 目前心情\x20\e[1;31m\x20
till \x20\e[
wait 第幾項：
send \n
exit

=mood_set
call configure
send m\n
wait 第幾項：
send 0\n$[mood]\n
exit

=mail
call main
send m\n
wait 電子郵件
till Call機

