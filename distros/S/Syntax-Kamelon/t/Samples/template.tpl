<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel="stylesheet" href="defaultstyle.css" type="text/css">
<title>Testfile Template Toolkit</title>
</head>
<body>
<div class="index" width="25%">
</br>
<h2>Index</h2>
[% FOREACH fold IN folds.keys.nsort ~%]
	[% node = folds.$fold ~%]
	[% level = node.depth ~%]
	[% WHILE level > 1 ~%]
		&nbsp;&nbsp;&nbsp;
		[%~ level = level - 1 ~%]
	[% END ~%]
	<a href="#[% fold %]">
	[%~ linktxt = node.line.trim ~%]
		[% linktxt.substr(0, 32) FILTER html FILTER replace('\040', '&nbsp;') FILTER replace('\t', '&nbsp;&nbsp;&nbsp;') ~%]
	</a></br>
[% END ~%]
</div>

<div class="content" width="75%">
<h2>Content</h2>
[% linenum = 0 ~%]
[% FOREACH line = content ~%]
	[% linenum = linenum + 1 ~%]
	[% IF folds.exists(linenum) ~%]
		<a name="[% linenum %]"></a>
	[%~ END ~%]
	[% linenum  FILTER format('%03d') ~%]
	&nbsp;
	[%~ FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
			[%~ snippet.text FILTER html FILTER replace('\040', '&nbsp;') FILTER replace('\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br>
[% END ~%]
</div>
</body>
</html>
