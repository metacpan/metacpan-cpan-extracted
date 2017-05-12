<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html><!-- #BeginTemplate "/Templates/circa.dwt" -->
<head>
<!-- #BeginEditable "doctitle" -->
<?

/**
 * Circa configuration
 */
if (!$idr) {$idr=1;}
include "circaLib.php3";
$database="circa";
$prefix="circa_";
$conn = mysql_pconnect("localhost","alian","");
$categories =get_liste_categorie($idr);

if ($url)
	{
	addSite($url,$categorie);
	mail("alian", "Inscription sur l'annuaire", "$url");
	$titre="Votre site a bien été ajouté !";
	}

?>

<title>Resultat avec Circa</title>
<!-- #EndEditable -->
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<style type="text/css">
<!--
body {
  font-family: sans-serif;
  color: black;
  background: white;
  margin-left : 0;
  margin-top : 0;
}
th, td { /* ns 4 */
  font-family: sans-serif;
}
a {font: bold; color:Navy;}
h1 { text-align: center }
h2, h3, h4, h5, h6 { text-align: left }
h1, h2, h3 { color: #005A9C; }
h1 { font: bold 100% }
h2 { margin:1em; font: bold 95% }
h3 { font: 90%  }
h4 { font: bold 85% }
h5 { font: italic 85%  }
h6 { text-align: right }
ul,p { font: 80%;}
p { text-align:justify; margin:1em;}
.p-liens {text-align:right;}
TH {background :  Navy; color :  White;}
TD {}
.td-bord {background :  Navy; color :  White;}
.small {font:70%; }
.h2-sans-marge {margin:0; text-align:center;}
-->
</style>
</head>

<body bgcolor="#FFFFFF">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
  <tr>
    <td width="8%" class="td-bord">&nbsp;</td>
    <td width="22%"><img src="images/circa_logo1.gif" width="70" height="70"><img src="images/circa_logo2.gif" width="110" height="50">
    </td>
    <td width="62%"><!-- #BeginEditable "titre" -->
      <h1>Inscription sur l'annuaire </h1>
      <h1><? echo $titre ?></h1>
      <!-- #EndEditable --></td>
    <td width="8%" class="td-bord">&nbsp;</td>
  </tr>
  <tr>
    <td width="8%" class="td-bord">&nbsp;</td>
    <td colspan="2">&nbsp;</td>
    <td width="8%" class="td-bord">&nbsp;</td>
  </tr>
  <tr>
    <td width="8%" class="td-bord">&nbsp;</td>
    <td colspan="2"><!-- #BeginEditable "corps" --> 
      <h2>Ajouter votre site :</h2>
      <form method="post" action="">
        <p>Url : 
          <input type="text" name="url">
          <br>
          Cat&eacute;gorie :<select name="categorie"><? echo $categories ?></select><br>
          <input type="submit" name="Submit" value="Submit">
        </p>
      </form>
      <h2>&nbsp;</h2>
      <p>&nbsp;</p>
      <!-- #EndEditable --></td>
    <td width="8%" class="td-bord">&nbsp;</td>
  </tr>
  <tr>
    <td width="8%" class="td-bord">&nbsp;</td>
    <td colspan="2"><!-- #BeginEditable "bas_page" -->
      <table width="100%">
        <tr> 
          <td width="50%">&nbsp;</td>
          <td width="50%">&nbsp;</td>
        </tr>
      </table>
      <!-- #EndEditable --></td>
    <td width="8%" class="td-bord">&nbsp;</td>
  </tr>
  <tr>
    <td width="8%" class="td-bord">&nbsp;</td>
    <td colspan="2">
      <h6>&nbsp;</h6>
      <h6>Powered by <a href="http://www.alianwebserver.com/circa" target="_blank">AlianWebServer</a>
      </h6>
    </td>
    <td width="8%" class="td-bord">&nbsp;</td>
  </tr>
</table>
</body>
<!-- #EndTemplate --></html>
