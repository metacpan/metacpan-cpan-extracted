<?
if (isset($_GET['monthno'])) $monthno = $_GET['monthno'];
if (isset($_GET['year'])) $year = $_GET['year'];
if (!isset($monthno)) {
    $monthno=date('n');
}
if (!isset($year)) {
    $year = date('Y');
}

$monthfulltext = date('F', mktime(0, 0, 0, $monthno, 1, $year));
$monthshorttext = date('M', mktime(0, 0, 0, $monthno, 1, $year));

$day_in_mth = date('t', mktime(0, 0, 0, $monthno, 1, $year)) ;
$day_text = date('D', mktime(0, 0, 0, $monthno, 1, $year));


?>
<style type="text/css">

.tdday { font-family: Verdana, Arial, Helvetica, sans-serif;
                  background-color: #0000ff;
                  font-weight: normal;
                  font-size: 9px;
                  width: 26px;
                  line-height: 20px;
                  color: #ffffff;
                  vertical-align: middle;
                  text-align: center;
}
.tdtoday { font-family: Verdana, Arial, Helvetica, sans-serif;
                  background-color: lightgreen;
                  font-weight: bold;
                  font-size: 10px;
                  line-height: 16px;
                  width: 26px;
                  color: #000000;
                  vertical-align: middle;
                  text-align: center;
}

.tdheading { font-family: Verdana, Arial, Helvetica, sans-serif;
                  background-color: #a0a0a0;
                  font-weight: bold;
                  font-size: 10px;
                  line-height: 20px;
                  color: #ffffff;
                  vertical-align: middle;
                  text-align: center;
}
.tddate { font-family: Verdana, Arial, Helvetica, sans-serif;
                  background-color: #f0f0f0;
                  font-weight: normal;
                  font-size: 10px;
                  line-height: 16px;
                  width: 26px;
                  color: #000000;
                  vertical-align: middle;
                  text-align: center;
 }
.caltable { border: #a0a0a0;
                   border-style: solid;
                   border-top-width: 1px;
                   border-right-width: 1px;
                   border-bottom-width: 1px;
                   border-left-width: 1px;
                   margin-bottom: 0px;
                   margin-top: 0px;
                   margin-right: 0px;
                   margin-left: 0px;
                   padding-top: 0px;
                   padding-right: 0px;
                   padding-bottom: 0px;
                   padding-left: 0px
}
</style>

<table class=caltable bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="1" width=97%>
<tr><td colspan=7 class=tdheading><? echo $monthfulltext." ".$year ?></td></tr>
<tr>
<td class=tdday>Sun</td><td class=tdday>Mon</td><td class=tdday>Tue</td><td class=tdday>Wed</td><td class=tdday>Thu</td><td class=tdday>Fri</td>
<td class=tdday>Sat</td>
</tr>
<tr>
<?

$day_of_wk = date('w', mktime(0, 0, 0, $monthno, 1, $year));

if ($day_of_wk <> 0){
   for ($i=0; $i<$day_of_wk; $i++)
   { echo "<td class=tddate>&nbsp;</td>"; }
}

for ($date_of_mth = 1; $date_of_mth <= $day_in_mth; $date_of_mth++) {

    if ($day_of_wk = 0){
   for ($i=0; $i<$day_of_wk; $i++);
   { echo "<tr>"; }
}
    $day_text = date('D', mktime(0, 0, 0, $monthno, $date_of_mth, $year));
    $date_no = date('j', mktime(0, 0, 0, $monthno, $date_of_mth, $year));
    $day_of_wk = date('w', mktime(0, 0, 0, $monthno, $date_of_mth, $year));
   if ( $date_no ==  date('j') &&  $monthno == date('n') )
     {  echo "<td class=tdtoday>".$date_no."</td>"; }
   else{
   echo "<td class=tddate>".$date_no."</td>";  }
   If ( $day_of_wk == 6 ) {  echo "</tr>"; }
   If ( $day_of_wk < 6 && $date_of_mth == $day_in_mth ) {
   for ( $i = $day_of_wk ; $i < 6; $i++ ) {
     echo "<td class=tddate>&nbsp;</td>"; }
      echo "</tr>";
      }
 }
?>
</table>
