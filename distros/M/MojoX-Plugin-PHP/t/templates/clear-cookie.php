<?php
/* set some cookies. */
$the_past = 1300000000;        // Mar 12 2011
$the_future = 2000000000;      // May 17 2033
setcookie("cookie1","", $the_past);
setcookie("cookie2","", $the_past);
setcookie("cookie3","", $the_past);
setcookie("cookie4","", $the_past);
echo "\0";
?>