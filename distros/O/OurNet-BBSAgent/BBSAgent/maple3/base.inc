# $File: //depot/OurNet-BBSAgent/BBSAgent/maple3/base.inc $ $Author: autrijus $
# $Revision: #5 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $

Maple3 Base

=login
wait 代號：
send $[username]\n
doif $[password]
    wait 密碼：
    send $[password]\nn\n
endo
# login failure, unsaved article, kick multi-logins
send \n\n\n
# skips splash screens (if any)
send \x20\x20\x20

=main
send qqqqqqee
wait 主功能表
till 呼叫器

=logoff
call main
send g\ng\ny\ny\n\n\n
exit
