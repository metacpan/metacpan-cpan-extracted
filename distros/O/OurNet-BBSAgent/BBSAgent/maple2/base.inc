# $File: //depot/OurNet-BBSAgent/BBSAgent/maple2/base.inc $ $Author: autrijus $
# $Revision: #4 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $
# Contributed by Smartboy <kcwu@ck.tp.edu.tw>

Maple2/SOB Base

setv pager	扣機

=login
wait 註冊：
send $[username]\n
send $[password]\n
send n\nn\nq\x20q\x20q\x20q\x20q
goto main

=main
send \e[D\e[D\e[D\e[D\e[D\e[D
wait 主功能表
till $[pager]

=logoff
call main
send g\ny\n\n\n\n
exit
