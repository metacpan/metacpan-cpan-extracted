<?php
/* set some cookies. */
$the_past = 1300000000;        // Mar 12 2011
$the_future = 2000000000;      // May 17 2033
setcookie("cookie1","value1", $the_future);
setcookie("cookie2","value2", $the_past);
setcookie("cookie3","value[3]", $the_future, "/");
setcookie("cookie4","value4", $the_future, "/foo");
echo "\0";
?>