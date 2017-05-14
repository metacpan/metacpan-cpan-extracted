<?php

$my_path = "/home/eric/code/openthought2/php";
ini_set('include_path',ini_get('include_path').":$my_path:");
include_once "OpenThought.php";

$OT = new OpenThought;

if ($_REQUEST['do_ajaxy_stuff']) {

    $fields[my_text_box] = "";

    $html[my_html_id_tag] = "<h3>You said: $_REQUEST[my_text_box]</h3>";

    $javascript = "alert('Hello there, I updated the HTML with what you said!')";

    print $OT->fields($fields);
    print $OT->html($html);
    print $OT->javascript($javascript);
}
else {

    print <<<EOT
<html>
<head>
  <script src="/OpenThought.js"></script>
</head>
<body>
<span id="my_html_id_tag">HTML was here</span><br/>
<form name="my_form">
  Enter some text: <input type="text" name="my_text_box"><br/>
  <input type="button" value="Send!"
         onClick="OpenThought.CallUrl('index.php', 'do_ajaxy_stuff=1', 'my_text_box')">
</form>
EOT;

}

?>
