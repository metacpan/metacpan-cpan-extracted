#!/usr/bin/perl

use warnings;
use strict;

use lib "/home/eric/code/openthought2/lib";

use CGI();
use OpenThought();

my $q  = CGI->new();
my $OT = OpenThought->new();

if ($q->param('do_ajaxy_stuff')) {

    my ( $fields, $html, $javascript );

    $fields->{my_text_box} = "";

    $html->{my_html_id_tag} = "<h3>You typed: " . $q->param('my_text_box') . "</h3>";

    $javascript = "alert('Hello, the HTML has been updated with your response')";

    print $q->header();

    $OT->param($fields);
    $OT->param($html);
    $OT->javascript($javascript);

    print $OT->response();
}
else {

    print $q->header();
    print << "EOT"
<html>
<head>
  <script src="/OpenThought.js"></script>
</head>
<body>
<span id="my_html_id_tag">HTML was here<br/></span>
<form name="my_form">
  <input type="text" name="my_text_box"><br/>
  <input type="button" value="Send!"
         onClick="OpenThought.CallUrl('index.pl', 'do_ajaxy_stuff=1', 'my_text_box')">
</form>
EOT

}
