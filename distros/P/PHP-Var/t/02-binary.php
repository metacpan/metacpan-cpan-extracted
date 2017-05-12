<?php

include($argv[1]);
$fh = fopen($argv[2], 'w');
fputs($fh, $data['bin']);
fclose($fh);
