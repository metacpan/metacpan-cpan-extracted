<?php

  # Stupid page to test CronIO functionality

  $s = file_get_contents("./counter.txt");
  $counter = intval($s);
  $counter++;

  echo "<HTML><HEAD></HEAD><BODY><H1>This page has been visited $counter times!</H1><ul>";
  echo file_get_contents("./visitors.txt");
  echo "</ul></BODY></HTML>";

  file_put_contents("./counter.txt", $counter);
  file_put_contents("./visitors.txt", "<li>". $_ENV['REMOTE_ADDR']. "</li>\n", FILE_APPEND);

?>

