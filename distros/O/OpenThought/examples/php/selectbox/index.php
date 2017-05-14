<?php

$my_path = "/home/eric/code/openthought2/php";
ini_set('include_path',ini_get('include_path').":$my_path:");
include_once "OpenThought.php";

$OT = new OpenThought;

if ($_REQUEST['add_item']) {

    $name  = $_REQUEST['name'];
    $value = $_REQUEST['value'];

    if ($name != "" and $value != "") {
        $selectlist[my_select_list] = array( $name => $value );

        print $OT->fields($selectlist);
    }
    else {
        $javascript = "alert('You should enter both a name and a value!')";

        print $OT->javascript($javascript);
    }
}
elseif (isset($_REQUEST['my_select_list'])) {

    $html[item_value] = $_REQUEST['my_select_list'];
    print $OT->fields($html);

}
else {

    print <<<EOT
<html>
<head>
  <script src="/OpenThought.js"></script>
</head>
<body>
<h3>Selectbox Demo</h3>
<form name="my_form">
  <select name="my_select_list" size="5"
    onChange="OpenThought.CallUrl('index.php', 'my_select_list')">
  </select><br/><br/>
  <p>You clicked the item with a value of: <span id="item_value"> </span></p>
  <p><b>Add a name and value to the select list</b></p>
  Item Name: <input type="text" name="name"><br/>
  Item Value: <input type="text" name="value"><br/>
  <input type="button" value="Send!"
         onClick="OpenThought.CallUrl('index.php', 'name', 'value', 'add_item=1')">
</form>
EOT;

}

?>
