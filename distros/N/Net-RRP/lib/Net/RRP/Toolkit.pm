package Net::RRP::Toolkit;

use strict;
use Errno;
use Fcntl ':flock';
require Exporter;

@Net::RRP::Toolkit::ISA = qw(Exporter);
@Net::RRP::Toolkit::EXPORT_OK = qw(decodeTilde safeCall safeCopy lowerKeys pathSubtract);
$Net::RRP::Toolkit::VERSION = (split " ", '# 	$Id: Toolkit.pm,v 1.3 2000/10/04 08:05:37 mkul Exp $	')[3];

sub decodeTilde
{
    my $path = shift || return undef;
    $path =~ s/^~([^\/]*)/$1 ? (getpwnam($1))[7] : (getpwuid($>))[7]/e;
    $path;
}

sub safeCall
{
    my $codeRef = shift;
    my $result  = &$codeRef;
    while ( ( $! == Errno::EINTR ) && ( ! $result ) )
    {
	$result  = &$codeRef;
    }
    $result;
}

sub safeWrite
{
    my ( $handler, $buffer, $length ) = @_;
    $handler         || raise ZError 'MISSING_MANDATORY_PARAM', { name => 'hander' };
    defined $buffer  || raise ZError 'MISSING_MANDATORY_PARAM', { name => 'buffer' };
    $length ||= length ( $buffer );

    my ( $origLength, $itemLength ) = ( $length );

    while ( $length )
    {
	$itemLength = Net::RRP::Toolkit::safeCall ( sub { $handler->syswrite ( $buffer, $length ) } );
	last unless $itemLength;
	$length -= $itemLength;
	$buffer  = substr ( $buffer, $itemLength ) if $length;
    }

    defined $itemLength ? $origLength : undef;
}

sub safeRead
{
    my ( $handler, $buffer, $length ) = @_;
    $handler         || raise ZError 'MISSING_MANDATORY_PARAM', { name => 'hander' };
    defined $buffer  || raise ZError 'MISSING_MANDATORY_PARAM', { name => 'buffer' };
    $length ||= length ( $buffer );
    $$buffer  = '';

    my ( $origLength, $itemLength ) = ( $length );
    my $subBuffer;

    while ( $length )
    {
	$itemLength = Net::RRP::Toolkit::safeCall ( sub { $handler->sysread ( $subBuffer, $length ) } );
	last unless $itemLength;
	$length  -= $itemLength;
	$$buffer .= $subBuffer;
    }

    defined $itemLength ? $origLength : undef;
}

sub safeCopy
{
    my $fromName   = $_{srcFile}    || die "safeCopy(): srcFile required";
    my $toName     = $_{dstFile}    || die "safeCopy(): dstFile required";

    my $bufferSize = $_{bufferSize} || 128;
    my $tmpMask    = $_{tmpMask}    || "$toName.$$.\%s";
    
    local ( *FROMFILE, *TOFILE ) = ( undef, undef );
    my ( $fromFileNum, $toFileNum, $tmpToName ) = ( 0, 0, '' );
    
    eval 
    {
	die "sysopen ( $fromName, \"r\" ): $!" 
	    unless safeCall sub { sysopen ( FROMFILE, $fromName, "r" ) };
	
	$fromFileNum = fileno ( FROMFILE );
	
	die "flock ( $fromFileNum ): $!" unless flock ( FROMFILE, LOCK_SH );
	
	my @stat;
	die "stat ( $fromFileNum ): $!" unless ( @stat = safeCall sub { stat ( FROMFILE ) } );
	
	my $i = 0; while ( 1 ) { last unless -f ( $tmpToName = sprintf ( $tmpMask, $i++ ) ); }  # ATT! XXX EINTR && -f ??? 
				 
	die "sysopen ( $tmpToName, \"w\", $stat[2] ): $!"
	    unless safeCall sub { sysopen ( TOFILE, "$tmpToName", "w", $stat[2] ) };
	
	$toFileNum = fileno ( TOFILE );
	
        my ( $n, $buffer );
	
	while ( 1 )
	{
	    die "sysread ( $fromFileNum, buffer, $bufferSize): $!"
		unless defined ( $n = safeCall sub { sysread ( FROMFILE, $buffer, $bufferSize ) } );
	    
	    last unless $n;
	    
	    die "syswrite ( $toFileNum, buffer, $n): $!"	    
		unless safeCall sub { syswrite ( TOFILE, $buffer, $n ) };
	}
    };
    
    if ( *FROMFILE )
    {
	warn "close ( $fromFileNum ): $!" unless safeCall sub { close ( FROMFILE ) };	
    }
    
    if ( *TOFILE )
    {
	warn "close ( $toFileNum ): $!" unless safeCall sub { close ( TOFILE ) };
	if ( $@ )
	{
	    warn "unlink( $tmpToName ): $!" unless safeCall sub { unlink ( $tmpToName ) };
	}
    }
    
    die $@ if $@;
    
    die "rename ( $tmpToName, $toName ): $!"
	unless rename ( $tmpToName, $toName );
    
    1;
}

sub lowerKeys
{
    my $record = shift;
    my $lcRecord;
    foreach ( keys %$record ) 
    {
	$lcRecord->{ lc ( $_ ) } = $record->{ $_ };
    }
    $lcRecord;
}

sub pathSubtract
{
    my @s1 = split '/', shift;    my @s2 = split '/', shift;
    my $i = 0;  for ( ; $s1 [ $i ] eq $s2 [ $i ] ; $i++ ) {}
    "../" x ( $#s1 - $i + 1 ) . join '/', @s2 [ $i .. $#s2 ];
}

sub strip
{
    my $line = shift;
    return undef unless defined $line;
    return $line unless $line;
    study $line;
    $line =~ s/^ +//g;
    $line =~ s/ +$//g;
    $line =~ s/^\t+//g;
    $line =~ s/\t+$//g;
    $line;
}

sub decodeQueueCommand
{
    my $command = shift;
    my @params = map { my @result = split /=/, $_;
		       $result[0] = '' unless defined $result[0];
		       $result[1] = '' if ( ( m/=/ ) && ( ! defined $result[1] ) );
		       @result; } split /:/, $command;
    @params;
}

1;

__END__

=head1 NAME

Net::RRP::Toolkit - big hole of usefull methods :)

=head1 DESCRIPTION

Net::RRP::Toolkit - big hole of usefull methods :)
By default, methods not exported to caller namespape. You can export same methods to your namespace using

 use Net::RRP::Toolkit qw(method_list);

in your code;

=head2 decodeTilde($)

Decode leading tilde (~) in file path.

Example:

 use Net::RRP::Toolkit; 
 my $path = '~mkul/dvp/Classes'; 
 my $fullPath = Net::RRP::Toolkit::decodeTilde($path); 

OR

 use Net::RRP::Toolkit qw(decodeTilde);
 my $fullPath = decodeTilde('~mkul/dvp/Classes');

=head2 safeCall($)

safe call syscalls with repeat at EINTR errors

 use Net::RRP::Toolkit;
 my $result = Net::RRP::Toolkit::safeCall ( sub { open "qwa" } );
 die $! unless $result;

=head2 safeCopy(@)

safe copy files. 
1) copy source file to temporary file 
2) rename temporary file to destanation file

 input parameters: hash
   keys      =>    values
 Required parameters
   srcFile        source file name
   dstFile        destanation file name
 This parameters can be omited
   bufferSize     size of copy buffer, default is 128
   tmpMask        mask for temporary file name.
                  Default if "$toFileName.$$.$counter"

Permission of destanation file is equal of source file
Source file is locked (lockf) by LOCK_SH
Temporary destanation file locked by LOCK_EX

Return true if ok or die if errors.

example:
 use Net::RRP::Toolkit;
 Net::RRP::Toolkit::safeCopy ( srcFile => 'temp.passwd',
                     dstFile => '/etc/passwd' );

=head2 lowerKeys($)

Lower all first level keys in hash

Input: hash reference.

Output: hash rerefence with lower keys

example:
 use Net::RRP::Toolkit;
 my $hash = { KEY1 => 1,
              KEY2 => { KEY3 => 3 }};
 print Data::Dumper->Dump ( [ Net::RRP::Toolkit::lowerKeys ( $hash ) ] ) . "\n";
 
 output:
  { key1 => 1,
    key2 => { KEY3 => 3} }

=head2 pathSubtract($$)

Path subscraction routine

input: two _absolute_ directory paths

output: reletive path of first path concerning of second path

example:
 use Net::RRP::Toolkit;
 print Net::RRP::Toolkit::pathSubtract ( "/var/1", "/var/2" );
 
 output:
 ../2

=cut
