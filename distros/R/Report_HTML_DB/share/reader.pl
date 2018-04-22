#/usr/bin/perl
use warnings;
use strict;
#use XML::Simple qw(:strict);
if($ARGV[0])
{
	###
	#
	#	VAI DAR BOSTA, VER OUTRO FORMATO DE LINGUAGEM DE MARCAÇÃO
	#	Possibilidade de não dar certo por reconhecer as tags HTML como se fossem tags XML(não é o objetivo)
	#	Objetivo: Criar regex que pegue as tags no inicio da linha, pege o valor delas
	#
	#
	###
	open my $FILEHANDLER, "<", $ARGV[0];
	my $content = do { local $/; <$FILEHANDLER> };
	my $sql = "";
	while($content =~ /^\t"([\w\-\_]*)"\s*:\s*"([\w\s<>\/@.\-:+(),'=&ããõáéíóúàâêẽ;#|]*)"/gm)
	{
		my $tag = $1;
		my $value = $2;
		$sql .= <<SQL;
			INSERT INTO TEXTS(tag, value) VALUES ("$tag", "$value");
SQL
	}
	print $sql;
	print "\nDONE\n";
	
#	my $ref = XMLin('example.xml');
#	foreach my $key(keys %$ref)
#	{
#		
#	}
}