package SyslogScan::SendmailLineTrans;

$VERSION = 0.23;
sub Version { $VERSION };
@ISA = qw ( SyslogScan::SendmailLine );

use SyslogScan::SendmailLineFrom;
use SyslogScan::SendmailLineTo;
use SyslogScan::SendmailLineClone;

use strict;

# pUnbalancedParen: pointer to static function to check if there are
# different ('s than )'s in a given string.
my $pUnbalancedParen = sub {
    my($stringToCheck) = @_;
    my($left, $right) = (0,0);
    my @eachChar;
    
    # short-circuit for efficiency
    return '' unless $stringToCheck =~ /[\(\)]/;
    
    @eachChar = split(/ */, $stringToCheck);
    grep($_ eq '(' && $left++,@eachChar);
    grep($_ eq ')' && $right++,@eachChar);
    return 't' if $left != $right;
    '';
};

# TODO: change attrHash to toHash or fromHash

# parseFromOrTo:  parse a message like:
# to=bar@foo.org,baz@foo.org, delay=03:50:20, mailer=smtp,
# relay=relay.uthbar.com [128.206.5.3],
# stat=Sent (May, have (embedded, commas)), or even, from=line

# or

# stat=Deferred: 451 collect: unexpected close, from=<foo@bar.com>: Host down

sub parseContent
{
    my($self) = @_;
    my($attr) = $$self{"attrListString"};
    undef $$self{"attrListString"};
    my($clonedFrom);

    # check if this is a clone line
    if ($attr =~ /^clone ([^,]+), (.+)/)
    {
	$clonedFrom = $1;
	$attr = $2;	
    }

    # clear out trailing stat line:
    my $stat;
    if ($attr =~ s/, (stat=.+, [^\)]+)$//)
    {
	$stat = $1;
	print STDERR "interpreting $1 as a single stat attribute\n"
	    unless $::gbQuiet;
    }

    my(@attrList) = split(', ',$attr);
    push(@attrList,$stat) if defined $stat;

    # Suppose $attr was "foo=bar, uth=(bar, baz)"

    # @attrList will be
    #          ("foo=bar", "uth=(bar", "baz)")
    # which is not what we want.

    # @completeAttrList will be
    #          ("foo=bar", "uth=(bar, baz)")
    # which is how we want to parse sendmail log lines.

    my ($attribute, @completeAttrList);
    while ($attribute = shift @attrList)
    {
	while (&$pUnbalancedParen($attribute))
	{
	    die "unbalanced parens in $attribute" unless @attrList;
	    $attribute .= (", " . shift @attrList);
	}
	unshift @completeAttrList, $attribute;
    }

    my (%attrHash);
    eval {%attrHash = _listToHash $self @completeAttrList};
    if ($@)
    {
	die $@ unless $@ =~ /equals not found/;
	undef $@;
	return;  # generic SendmailTrans line
    }
    
    $$self{"attrHash"} = \%attrHash;

    if (defined $clonedFrom)
    {
	$$self{clonedFrom} = $clonedFrom;
    	bless ($self, "SyslogScan::SendmailLineClone");
	return $self -> SyslogScan::SendmailLineClone::parseContent;
    }

    if (defined $attrHash{"from"})
    {
	bless($self, "SyslogScan::SendmailLineFrom");
	return $self -> SyslogScan::SendmailLineFrom::parseContent;
    }

    if (defined $attrHash{"to"})
    {
	bless($self, "SyslogScan::SendmailLineTo");
	return $self -> SyslogScan::SendmailLineTo::parseContent;
    }

    return;  #generic unsupported line with message ID
}

# _listToHash: transforms list of equations like
#    ("foo=bar", "uth=fod=baz")
# into perl hash table like
#    ("foo" => "bar", "uth" => "fod=baz")

sub _listToHash
{
    my ($self, @list) = @_;
    my (%hash);
    foreach (@list)
    {
	s/\'/\"/g;  # TODO: remove this eroot-compatibility hack
	die "equals not found in $_" unless /([^=]+)=(.+)/;
	$hash{$1} = $2;
    }
    %hash;
}
