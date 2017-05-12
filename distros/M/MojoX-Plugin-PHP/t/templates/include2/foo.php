<?php

include_once( "./include3.php");
$y = $y / 49 + 6;
include_once( dirname( dirname(__FILE__) ) . "/../include1.php");
$x = $x / 25 + 7;

?>
x is <?php echo $x; ?><br/>
y is <?php echo $y; ?><br/>
cwd is <?php echo getcwd(); ?>
</br>
