<pre>
$_FILES = <?php 
var_export($_FILES); 
/* TODO: look in $_FILES[...]['tmp_name'] and verify uploads */
?>
-------------------------------
</pre>

<pre>
<?php

$f = $_FILES['output'];
print_r($f);

$b1 = 0+is_uploaded_file($f['tmp_name']);
echo "is_uploaded_file [1] result = $b1\n";

$b2 = 0+move_uploaded_file( $f['tmp_name'], "/tmp/uploaded-output.txt" );
echo "move_uploaded_file result = $b2\n";

$b3 = 0+is_uploaded_file($f['tmp_name']);
echo "is_uploaded_file [2] result = $b3\n";

$fh = fopen( "/tmp/uploaded-output.txt", "r" );
$string = fread( $fh, filesize( "/tmp/uploaded-output.txt" ) );
$len = strlen($string);
fclose($fh);

echo "length read = $len\n";

echo "--------------------\nFile content (length $len)\n--------------------\n";
echo $string;


?>
</pre>