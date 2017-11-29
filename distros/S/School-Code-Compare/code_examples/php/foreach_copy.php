<?php
// SOURCE: http://php.net/manual/de/control-structures.foreach.php

/* foreach Beispiel 1: Nur Werte */

$a = array(1, 2, 3, 17);

foreach ($a as $v) {
    echo "Aktueller Wert von \$a: $v.\n";
}

/* foreach Beispiel 2: Werte (mit Schreibweise für Zugriff zur Veranschaulichung) */

$a = array(1, 2, 3, 17);

$i = 0; /* nur zur Veranschaulichung */

foreach ($a as $v) {
    echo "\$a[$i] => $v.\n";
    $i++;
}

/* foreach Beispiel 3: Schlüssel und Wert */

$a = array(
    "eins" => 1,
    "zwei" => 2,
    "drei" => 3,
    "siebzehn" => 17
);

foreach ($a as $k => $v) {
    echo "\$a[$k] => $v.\n";
}

/* foreach Beispiel 4: Mehrdimensionale Arrays */
$a = array();
$a[0][0] = "a";
$a[0][1] = "b";
$a[1][0] = "y";
$a[1][1] = "z";

foreach ($a as $v1) {
    foreach ($v1 as $v2) {
        echo "$v2\n";
    }
}

/* foreach Beispiel 5: Dynamische Arrays */

foreach (array(1, 2, 3, 4, 5) as $v) {
    echo "$v\n";
}
?>
