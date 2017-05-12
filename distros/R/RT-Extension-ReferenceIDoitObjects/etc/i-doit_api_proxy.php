<?php

/**
 * i-doit
 *
 * API Proxy: Act like a HTTP proxy to avoid browsers' same orgin policy.
 *
 * @package i-doit
 * @subpackage API
 * @author Benjamin Heisig <bheisig@synetics.de>
 * @version 0.2
 * @copyright synetics GmbH
 * @license http://www.gnu.org/licenses/agpl.txt GNU Affero General Public License
 */

// URL to i-doit's API:
$l_url = 'http://example.org/i-doit/index.php?api=jsonrpc';

$l_content_type = 'application/json';
$l_header = array(
    'Content-Type: ' . $l_content_type
);

$l_curl_handle = curl_init($l_url);
curl_setopt($l_curl_handle, CURLOPT_POST, 1);
curl_setopt($l_curl_handle, CURLOPT_POSTFIELDS, file_get_contents('php://input'));
curl_setopt($l_curl_handle, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($l_curl_handle, CURLOPT_USERAGENT, 'i-doit API Proxy');
curl_setopt($l_curl_handle, CURLOPT_HTTPHEADER, $l_header);

$l_content = curl_exec($l_curl_handle);
curl_close($l_curl_handle);

header('Content-Type: ' . $l_content_type);
echo $l_content;

?>
