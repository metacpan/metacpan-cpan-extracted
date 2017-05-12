<?php

$private_key = '12345';
$public_id = 'mcrawfor';

$content = '';

$host = "http://inkey.eplt.washington.edu";
$url = "/tools/rest/webq/v1/";
$method = "PUT";


//Build auth key
$date = time();
if($content)
    $content_sha1 = sha1($content);
$to_sign = "$private_key\n$method\n$url\n$date\n$content_sha1";
$auth_key = "SolAuth $public_id:".sha1($to_sign);

//Build Headers
$headers = array();
array_push($headers, "Date: $date");
if($content)
    array_push($headers, "Content-SHA1: $content_sha1");
array_push($headers, "Authorization: $auth_key");

//HTTP work
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $host.$url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);
echo $response;
?> 
