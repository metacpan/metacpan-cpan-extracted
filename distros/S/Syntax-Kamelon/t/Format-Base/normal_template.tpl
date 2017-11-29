<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile template file without additional options</title>
</head>
<body>
[% FOREACH line = content ~%]
	[% FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
		[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br>
[% END ~%]
</body>
</html>
