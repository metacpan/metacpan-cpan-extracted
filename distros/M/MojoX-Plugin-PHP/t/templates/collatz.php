<?php

$nsteps = 0;
$n = $_GET['n'];
while ($n > 1) {
    if ($n % 2 == 0) {
        $n = $n / 2;
    } else {
        global $collatz_result;
        header("X-collatz: {\"n\":$n,\"result\":\"collatz_result\"}");
        $n = $collatz_result;
    }
    $nsteps++;
}
?>

number of Collatz steps is <?php echo $nsteps; ?>



