<?php
$loc = $_GET['location'];
if ($loc == 1) {
  $location = "http://localhost/redirect_destination.php";
  $location = "/redirect_destination.php";
} else {
  $location = "http://localhost/redirect_destination2.php";
  $location = "/redirect_destination2.php";
}

// what is the correct way to redirect with status other than 302?
// I've seen:
//
//     http_response_code( 301 );
//     header("Location: http://whatever.com/", true, 301);
//     header("HTTP/1.1 301 Moved Permanently", true);
//     header("Status: 301 Moved Permanently", true);
//
// only the last one seems to work

if (isset($_GET['status'])) {
   if ($_GET['status'] == 301) {
      header("Status: 301 Moved Permanently", true);
//     header("HTTP/1.1 301 Moved Permanently", true, 301);
   } else {
     http_response_code( $_GET['status'] );
   }
}
header("Location: $location");
//exit;
?>
