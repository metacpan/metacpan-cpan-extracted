<?php

$nsteps = 0;
$n = $_GET['n'];
while ($n > 1) {
    if ($n % 2 == 0) {
        $n = $n / 2;
    } else {
        $n = 3 * $n + 1;
    }
    $nsteps++;
}
?>

num collatz steps is <?php echo $nsteps; ?>



