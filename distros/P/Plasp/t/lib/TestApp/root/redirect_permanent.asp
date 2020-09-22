<%
$Response->{Status} = 301;
$Response->AddHeader( 'Location', '/welcome.asp' );
%>
