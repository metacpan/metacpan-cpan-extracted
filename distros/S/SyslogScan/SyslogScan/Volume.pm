package SyslogScan::Volume;

# For documentation, see the SyslogScan::Usage module

$VERSION = 0.20;
sub Version { $VERSION };

use strict;

# index values; we use array instead of hash for efficiency
my $MESSAGES = 0;
my $BYTES = 1;

sub new
{
    my $type = shift;
    my $self = [0,0];  # Messages, Bytes
    bless ($self,$type);
    return $self;
}

sub addSize
{
    my $self = shift;
    my $size = shift;
    
    $$self[$MESSAGES]++;
    $$self[$BYTES] += $size;
}

sub addVolume
{
    my $self = shift;
    my $other = shift;

    $$self[$MESSAGES] += $$other[$MESSAGES];
    $$self[$BYTES] += $$other[$BYTES];
}

sub dump
{
    my $self = shift;
    return $$self[$MESSAGES].','.$$self[$BYTES];
}

sub getMessageCount
{
    my $self = shift;
    return $$self[$MESSAGES];
}

sub getByteCount
{
    my $self = shift;
    return $$self[$BYTES];
}

sub persist
{
    my $self = shift;
    my $outFH = shift;

    print $outFH $$self[$MESSAGES].','.$$self[$BYTES], "\n";
}

sub restore
{
    my $type = shift;
    my $inFH = shift;

    defined($inFH) or die("no filehandle defined");

    my $volumeLine = <$inFH>;
    if (! ($volumeLine =~ /^(\d+)\,(\d+)$/))
    {
	die "illegal volume line: $volumeLine";
    }
    
    my $self = [$1, $2];  # messages, bytes
    bless ($self,$type);
    return $self;
}

sub deepCopy
{
    my $self = shift;

    my $copy = [$$self[$MESSAGES],$$self[$BYTES]];
    bless($copy,ref($self));
    return $copy;
}

1;

__END__

See SyslogScan::Usage for documentation.
