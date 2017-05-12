<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html><!-- #BeginTemplate "/Templates/circa.dwt" -->
<head>
<!-- #BeginEditable "doctitle" -->
<?

/**
 * Circa configuration
 */

include "circaLib.php3";
$database="circa";
$prefix="circa_";
$conn = mysql_pconnect("localhost","alian","");

$templateS='$resultat.="
<p>$indiceG - <a href=\"$url\">$titre</a> $description<br>
<font class=\"small\"><b>Url:</b> $url <b>Facteur:</b> $facteur
<b>Last update:</b> $last_update </font></p>

";';
$templateC='$resultat[]= "<p>$nom_complet<br></p>\n";';

/**
 * Circa search
 */

if (($categorie&&$id&&!$word)
        {
        if (!$id) {$id=1;}
        if (!$categorie) {$categorie=0;}
        list ($cates,$titre) = categories_in_categorie($categorie,$id,$templateC);
        $sites = sites_in_categorie($categorie,$id,$templateS);
        if ($cates) {$resultat ="<h2>Catégories</h2>".join('',$cates);}
        if ($sites) {$resultat.="<h2>Sites</h2>".$sites;}
        $titre="<h1>Annuaire</h1>".$titre;
        }
else {list($resultat,$links,$indice) = search($templateS,$word,$first|0,1,'','','','','');$titre = "<h1>Recherche sur $words</h1>";}
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
    <td width="62%"><!-- #BeginEditable "titre" --><? echo $titre; ?><!-- #EndEditable --></td>
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
      <p><? echo $indice ?></p>
      <? echo $resultat ?><!-- #EndEditable --></td>
    <td width="8%" class="td-bord">&nbsp;</td>
  </tr>
  <tr>
    <td width="8%" class="td-bord">&nbsp;</td>
    <td colspan="2"><!-- #BeginEditable "bas_page" -->
      <table width="100%">
        <tr>
          <td width="50%">
            <form>
              <table align=center cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td>
                    <h2 class="h2-sans-marge">Nouvelle recherche </h2>
                  </td>
                </tr>
                <tr>
                  <td>
                    <input type="text" name="word" value="<? echo $words ?>" size="15">
                    <input type="hidden" name="id" value="<? echo $id ?>">
                    <input type="hidden" name="categorie" value="<? echo $categorie ?>">
                    <input type="submit" name=".submit" value="go">
                  </td>
                </tr>
              </table>
            </form>
          </td>
          <td width="50%">
            <p class="p-liens"><? echo $links ?></p>
          </td>
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
