<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile template file with line numbers</title>
</head>
<body>
[% linenum = lineoffset ~%]
[% FOREACH line = content ~%]
	[% linenum  FILTER format('%03d ') ~%]
	[% FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
		[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br>
	[%~ linenum = linenum + 1 %]
[% END ~%]
</body>
</html>
