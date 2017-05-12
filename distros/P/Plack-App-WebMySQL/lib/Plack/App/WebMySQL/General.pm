#the dumb terminal webmysql module
#mt 16/11/2003 2.4	added parseFragmentToString
package Plack::App::WebMySQL::General;
BEGIN {
   use Exporter();
	use Plack::App::WebMySQL;
	@ISA = qw(Exporter);
   @EXPORT = qw(getData replace parsePage parseFragmentToString);
}
###############################################################################################################
sub getData{	#gets cgi form data into a hash
	#foreach (keys %ENV){print STDERR "$_ = $ENV{$_}\n";}
	my $cgi = CGI::new();
	%form = ();	#empty first as PSGI will keep globals set until the server is killed.
	foreach($cgi -> param()){
		$form{$_} = $cgi -> param($_);
		#print STDERR "$_ = $form{$_}\n";
	}
	return 1;
}
###############################################################################################################
sub replace{	#make sure we dont get any undefined values when replacing template placeholders
	if(defined($form{$_[0]})){return $form{$_[0]};}	#return hash value
	else{
		print STDERR "$0: $_[0] is undefined in placeholder replace\n";
		return "";	#return nothing
	}
}
###############################################################################################################
sub parsePage{	#displays a html page
	my $page = shift;
	my $ignoreError = shift;
	if($error && !$ignoreError){	#an error has not been encountered and we are not ignoring it
		$page = "error";
		print STDERR "$0: $error\n";	#log this error too
	}
	if(open(TEMPLATE, "<templates/$page.html")){
		while(<TEMPLATE>){	#read the file a line at a time
			$_ =~ s/<html>/<html>\n\t<!-- Template: $page.html -->/;
			$_ =~ s/<!--self-->/$ENV{'SCRIPT_NAME'}/g;	#replace the name for this script
			$_ =~ s/<!--server-->/$ENV{'HTTP_HOST'}/g;	#replace webserver name
			$_ =~ s/<!--error-->/$error/g;	#replace the error message
			$_ =~ s/<!--version-->/$VERSION/g;	#replace version number
			$_ =~ s/<!--(\w+)-->/&replace($1)/eg;	#replace the placeholders in the template
         $_ =~ s|</body>|<br><br>\n<div align="center"><font size="2">&copy; <a href="http://www.thedumbterminal.co.uk" target="_blank">Dumb Terminal Creations</a></font></div>\n</body>|;
			print;
		}
		close(TEMPLATE);
	}
	else{
		print << "(NO TEMPLATE)";
<html>
	<body>
		Could not open HTML template: webmysql/templates/$page.html
	</body>
</html>
(NO TEMPLATE)
	}
}
###############################################################################################################
sub parseFragmentToString{	#save a html fragment to a string
	my $page = shift;
	my $string = "<!-- Template: $page.html -->\n";
	if(open(TEMPLATE, "<templates/$page.html")){
		while(<TEMPLATE>){	#read the file a line at a time
			$_ =~ s/<!--self-->/$ENV{'SCRIPT_NAME'}/g;	#replace the name for this script
			$_ =~ s/<!--server-->/$ENV{'HTTP_HOST'}/g;	#replace webserver name
			$_ =~ s/<!--error-->/$error/g;	#replace the error message
			$_ =~ s/<!--version-->/$VERSION/g;	#replace version number
			$_ =~ s/<!--(\w+)-->/&replace($1)/eg;	#replace the placeholders in the template
			$string .= $_
		}
		close(TEMPLATE);
	}
	else{$error = "Cant open HTML fragment: $page";}
	return $string;
}
###############################################################################
return 1;
END {}

