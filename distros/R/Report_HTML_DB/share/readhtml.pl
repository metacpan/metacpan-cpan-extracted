#/usr/bin/perl
use strict;
use warnings;

if($ARGV[0])
{
	my $htmlFile =$ARGV[0];
	open(my $FILEHANDLER, "<", $htmlFile); 
	my $content = do { local $/; <$FILEHANDLER> };
	my $sql = "";
	while($content =~ /class="(\w+)" id="([\w\-]*)">([\w\d\s\@\.\(\)\-\+\,\;\:\=\'\<\>\~ã\/\#&|]*)<\/\w*>/g)
	{
		my $tempTag = "";
		if($2)
		{
			$tempTag = $1."-".$2;
		}
		else
		{
			$tempTag = $1;
		}
		my $tempContent = $3;
		$tempContent =~ s/<\/div>|<\/li>|<\/ul>|<\/h4>|<\/p>|<\/a>|<\/span>|<\/teste>$//g;
		$sql .= <<SQL;
			INSERT INTO TEXTS(tag, value) VALUES ("$tempTag", "$tempContent");
SQL
		
	}
	print $sql;
}

print "done";