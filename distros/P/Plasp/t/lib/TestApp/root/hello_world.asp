<html>
<head>
<title>Hello World!</title>
</head>
<body>
  <h1><%= join('', qw(H e l l o)) . ' ' . join('', qw(W o r l d !)) %></h1>
  <pre style="display: none;">
    $Request->Cookies( 'gotcha' ) => <%= $Request->Cookies( 'gotcha' ) %>
    $Request->Cookies( 'another', 'gotcha' ) => <%= $Request->Cookies( 'another', 'gotcha' ) %>
  </pre>
</body>
</html>
<%
$Response->Expires( 600 );
$Response->{Charset} = 'ISO-LATIN-1';
$Response->{ContentType} = 'TeXt/HTml';
$Response->Cookies( gotcha => 'yup!' );
$Response->Cookies( another => gotcha => 'yup!' );

# This should save response body and stop processing
$Response->Flush();
$Response->End();
%>
extra content should not be seen!!
