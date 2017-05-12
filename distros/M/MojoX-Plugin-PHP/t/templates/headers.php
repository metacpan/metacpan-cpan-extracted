<?php
// output form data back as headers.
foreach ( array_keys($_REQUEST) as $key ) {
    echo "$key => $_REQUEST[$key]<p/>\n";
    header("X-header-$key: $_REQUEST[$key]");
}
?>