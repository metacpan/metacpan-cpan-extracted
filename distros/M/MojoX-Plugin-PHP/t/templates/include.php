<?php
/* a php file that includes other php files */

echo "__FILE__ for include.php is ", __FILE__, "\n";

include("./include1.php");

echo "x is $x\n";

require_once("./include2/include3.php");

echo "y is $y\n";

echo "include path is ", get_include_path(), "\n";

include( dirname(__FILE__) . "/include4.php" );

echo "Last line of include.php is ", __LINE__, "\n";