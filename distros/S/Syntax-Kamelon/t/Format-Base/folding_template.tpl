<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<head>
<script type="text/javascript" language="JavaScript"><!--
function block_expand(b, e) {
	var marker_e = b.concat('e');
	var marker_f = b.concat('f');
	document.getElementById(marker_e).style.display="none";
	document.getElementById(marker_f).style.display="inline";
	for (i = Number(b) + 1; i <= Number(e); ++i) {
		document.getElementById(i).style.display="inline";
		var im_e = i.toString().concat('e');
		var im_f = i.toString().concat('f');
		if (document.getElementById(im_f) !== null) {
			document.getElementById(im_e).style.display="none";
			document.getElementById(im_f).style.display="inline";
		}
	}
}
function block_fold(b, e) {
	var marker_e = b.concat('e');
	var marker_f = b.concat('f');
	document.getElementById(marker_e).style.display="inline";
	document.getElementById(marker_f).style.display="none";
	for (i = Number(b) + 1; i <= Number(e); ++i) {
		document.getElementById(i).style.display="none";
	}
}
//--></script>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile template file with code folding</title>
</head>
<body>
[% linenum = 1 ~%]
[% FOREACH line = content ~%]
	<div id="[% linenum %]" class="line">
	[%~ IF folds.exists(linenum) ~%]
		[% node = folds.$linenum ~%]
		<div id="[% linenum %]f" class="fold" onclick="block_fold('[% linenum %]', '[% node.end %]')">-</div><div id="[% linenum %]e" class="fold" onclick="block_expand('[% linenum %]', '[% node.end %]')" style="display:none;">+</div>
	[% ELSE ~%]
		<div class="fold">&nbsp;</div>
	[%~ END ~%]
	[%~ FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
			[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br></div>
	[%~ linenum = linenum + 1 %]
[% END ~%]
</body>
</html>

