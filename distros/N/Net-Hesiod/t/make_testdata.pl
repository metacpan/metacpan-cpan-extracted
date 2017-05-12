#!/usr/local/bin/perl5 -w

#Create some site specific test data for testing the module
#Try to prompt as little as possible
#Give -f flag to overwrite existing t/testdata.pl file

use strict;


my $flag;
my $force;
while ( $flag = shift @ARGV )
{ 	if ( $flag eq '-f' ) { $force=1; last; }
	elsif ( $flag =~ /^[A-Z]+=.*$/ ) { next; #Skip Makefile.PL flags
	} else 
	{ 	warn "Unknown argument $flag. Use -f to overwrite testdata.pl";
	}
}

if ( -f 't/testdata.pl'  && ! $force ) { exit 0; }


sub get_answer_with_default($$)
{	my $prompt = shift;
	my $default=shift;
	print "$prompt  ";
	my $res = <STDIN>;
	chop $res;
	if ( $res eq "undef" ) { return 'UNDEF'; }
	return $res || $default;
}

sub print_array(@)
{	my @tmp = @_;
	if ( ! scalar(@tmp) ) { print "Empty\n"; return; }
	my $tmp;
	foreach $tmp (@tmp)
	{	print "\t$tmp\n";
	}
}

sub read_array()
{	my @tmp;
	my $tmp;
	while ( chop($tmp=<STDIN>) )
	{	push @tmp, $tmp;
	}
	return @tmp;
}


open(FILE,">t/testdata.pl") or die "Unable to open t/testdata.pl for writing";

my $tmp=eval { `hostname`; };
if ($tmp =~ /^[^\.]*.(.*)$/ ) {	$tmp = $1; } else { $tmp = ""; }

my $domain=get_answer_with_default("Enter HESIOD domain [$tmp]: ",$tmp);
my $bindsuff="ns.$domain";
$bindsuff=get_answer_with_default("Enter HESIOD bind suffix [$bindsuff]: ",
	$bindsuff);

print <<EOF;
We now need a valid hesiod query and answer.  Will ask for a name and a type
to produce a query as in
hesinfo \$name \$type
EOF

my $name=get_answer_with_default("Enter name for Hesiod query:","");
my $type=get_answer_with_default("Enter type for Hesiod query:","");

my $res = eval { `hesinfo $name $type`; };
my @res = split /\n/, $res;
print "Based on hesinfo, we get the result of the query to be:\n";
print_array(@res);
my @resolve_answer;
$tmp=get_answer_with_default("Is this correct [y]:  ","y");
if ( $tmp =~ /^[yY]/ )
{	@resolve_answer=@res;
} else
{	print "Enter the correct query result followed by a blank line.\n";
	@resolve_answer=read_array()
}
my $query_answer = join ',' , @resolve_answer;
my @query_answer = split /,/ , $query_answer;


print "\nFor testing purposes, we also want strings which do not match any Hesiod names or queries\n";
my $bogusname=get_answer_with_default("Enter a bogus query name [xxxxxx]:  ",
	"xxxxxx");
my $bogustype=get_answer_with_default("Enter a bogus query type [xxxxxx]:  ",
	"xxxxxx");

print "We also need a valid username for getpwnam and getmailhost checks:\n";
$tmp=eval {`whoami`};
chop $tmp;

my $username=get_answer_with_default("Enter a real username [$tmp]:  ",$tmp);
print "We need the mail service type, mail host, and mailuser for that user\n";
my $mailserv=get_answer_with_default(
	"Enter the mail service for user $username [POP]:  ", "POP");
my $mailhost=get_answer_with_default(
	"Enter the mail domain for user $username [$domain]:  ", $domain);
my $mailuser=get_answer_with_default(
	"Enter the mail user for user $username [$username]:  ", $username);

print "\nFor testing, we also want an invalid username and uid.\n";
my $tmp2;
my $tmp3;
foreach $tmp3 ( "xxxxxx", "yyyyyy", "zzzzzz", "xxxyyy", "xxxzzz", "yyyzzz" )
{	if ( $tmp2 = getpwnam $tmp3 ) {next; }
	$tmp=$tmp3;
	last;
}
my $bogususer=get_answer_with_default("Enter a bogus username [$tmp]:  ",$tmp);
foreach $tmp3 ( 64001, 65001, 63099, 59999, 58999, "" )
{	if ( $tmp2 = getpwuid $tmp3 ) {next; }
	$tmp=$tmp3;
	last;
}
my $bogusuid=get_answer_with_default("Enter a bogus uid [$tmp]:  ",$tmp);

print "\nTo test getservbyname, we need a service and protocol.\n";
my $service=get_answer_with_default("Enter a service name [smtp]:  ","smtp");
my $proto=get_answer_with_default("Enter a protocol name [tcp]:  ","tcp");
print "We also need the result of looking it up\n";
my @servres = getservbyname($service,$proto);
$tmp=$servres[0];
my $resservice=get_answer_with_default("Enter name from lookup [$tmp]:  ",$tmp);
$tmp=$servres[1];
my $alias=get_answer_with_default("Enter aliases from lookup [$tmp]:  ",$tmp);
$tmp=$servres[2];
my $port=get_answer_with_default("Enter port from lookup [$tmp]:  ",$tmp);
$tmp=$servres[3];
my $resproto=get_answer_with_default("Enter proto from lookup [$tmp]:  ",$tmp);

print "Finally, we need a bogus service name and protocol\n";
my $bogusserv=get_answer_with_default("Enter bogus service [xxxxxx]:  ",
	"xxxxxx");
my $bogusproto=get_answer_with_default(
	"Enter bogus protocol [carrier pigeon]:  ", "carrier pigeon");

print FILE <<EOF;
#Domain should be your HESIOD domain name (no .ns. ) while \$bindsuff should
#be ns.\$domain
\$domain="$domain";
\$bindsuff="$bindsuff";

#Name and type should be a valid hesiod query.  Preferably should return
#multiple records with \$mydelim as delimiter to fully test stuff
#\@resolve_answer should be result of the query, one element per DNS record
\$name="$name";
\$type="$type";
\@resolve_answer =qw(@resolve_answer);
\$query_answer = "$query_answer";
\@query_answer = qw(@query_answer);

#These two shold be invalid hesiod name and type, make sure we handle bad
#queries or empty queries gracefully
\$bogusname="$bogusname";
\$bogustype="$bogustype";

#The following should define a valid username
\$username="$username";

#The result of mailhost lookup on the above username
\@poresult=qw($mailserv $mailhost $mailuser );

#We also want an invalid username and uid to check handle those cases
\$bogususer="$bogususer";
\$bogusuid="$bogusuid";

#The following should define a valid service, proto, and what getservbyname
#should return
\$service="$service";
\$proto="$proto";
\@result=qw($resservice $alias  $port  $resproto );

#We also want an invalid service name and proto
\$bogusserv ="$bogusserv";
\$bogusproto ="$bogusproto";
EOF

1;
