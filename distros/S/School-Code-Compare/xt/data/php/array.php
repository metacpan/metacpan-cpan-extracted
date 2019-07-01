
<?php
// SOURCE: http://php.net/manual/de/language.types.array.php
// Alle Fehler anzeigen
error_reporting(E_ALL);

$arr = array('fruit' => 'apple', 'veggie' => 'carrot');

// Korrekt
print $arr['fruit'];  // apple
print $arr['veggie']; // carrot

// Inkorrekt. Dies Funktioniert, aber PHP wirft einen Fehler der Stufe
// E_NOTICE, da eine undefinierte Konstante namens fruit verwendet wird
// 
// Notice: Use of undefined constant fruit - assumed 'fruit' in...
print $arr[fruit];    // apple

// Dies definiert eine Konstante, um darzustellen was hier passiert. Der Wert
// 'veggie' wird einer Konstanten namens fruit zugewiesen
define('fruit', 'veggie');

// Beachten Sie nun den Unterschied
print $arr['fruit'];  // apple
print $arr[fruit];    // carrot

// Hier ist es in Ordnung, da dies innerhalb eines String ist. Innerhalb eines
// Strings wird nicht nach Konstanten gesucht, weshalb kein E_NOTICE auftritt
print "Hello $arr[fruit]";      // Hello apple

// Mit einer Ausnahme: Klammern um ein Array sorgen dafür, dass Konstanten
// interpretiert werden
print "Hello {$arr[fruit]}";    // Hello carrot
print "Hello {$arr['fruit']}";  // Hello apple

// Dies wird nicht funktionieren und zu einem Parser Fehler führen:
// Parse error: parse error, expecting T_STRING' or T_VARIABLE' or T_NUM_STRING'
// Dies gilt natürlich ebenso für superglobale Werte innerhalb von Strings
print "Hello $arr['fruit']";
print "Hello $_GET['foo']";

// Konkatenation ist eine weitere Möglichkeit
print "Hello " . $arr['fruit']; // Hello apple
?>

