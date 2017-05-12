# $File: //depot/OurNet-BBSAgent/BBSAgent/firebird2/base.inc $ $Author: autrijus $
# $Revision: #3 $ $Change: 2217 $ $DateTime: 2001/10/27 06:03:10 $
# Contributed by Smartboy <kcwu@ck.tp.edu.tw>

Firebird2 Base

setv statustail 停留[
setv afterlogin qqqqqq

=login
wait 註冊請輸入
send $[username]\n$[password]\n\n\n
send $[afterlogin]

goto main

=main
send \e[D\e[D\e[D\e[D\e[D\e[D
wait 主選單
till $[statustail]
