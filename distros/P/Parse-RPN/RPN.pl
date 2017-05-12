#!/usr/bin/perl

use Data::Dumper;

use Getopt::Std;
$ENV{TZ}='EST';

my $history_file = glob('~/.RPN.history');
my %option;
getopts( "vhdi:o:r:f:SI:pT:H:", \%option );

my $DEBUG = $option{ d };

my $sep_in = ',';

my %S      = (
    bytesin  => 100,
    bytesout => 222,
    name     => 'eth0',
    mac      => 0xccaabbff,
    extra    => {
        a => 'azerty',
        b => 'test',
        c => 'qwerty'
    },
    extra1 => [ 'azerty1', 'test1' ]
);

my $s1 = 'extra';

my @T = qw( test1 test2 Test3 TEST4 ); 

my $scal = 1.23456789;

sub Test {
   my $a  = shift;
   my $b = shift;
   my $c = $a/$b;
   
   return $c;
}

sub Test1 {
   my $a  = shift;
   return scalar reverse $a;
}

sub Test2 {
   
   return "default_value";
}

my $s = \%S;

if ( !defined $option{ r } && !defined $option{ v } && !defined $option{ f } && !defined $option{ S } )
{
    $option{ h } = 1;
}

$history_file = glob( $option{ H } ) if $option{ H };

if ( $option{ h } )
{
    print "Usage: $0 [options ...]\n\n";
    print "Where options include:\n";
    print "\t -h \t\t this help (what else ?)\n";
    print "\t -v \t\t print version and exit\n";
    print "\t -d \t\t print debuging value\n";
    print "\t -o sep \t use sep as separator for the output\n";
    print "\t -i sep \t use sep as separator for the input\n";
    print "\t -r rpn \t use rpn as string for the RPN test\n";
    print "\t -f file \t use this file for the RPN test\n";
    print "\t -S \t\t shell mode\n";
    print "\t -I path \t path to RPN.pm to use\n";
    print "\t -T tz \t set a specific timezone\n";
    print "\t -H hist \t use this history file in Term mode (default=$history_file)\n";
    print "\t -p \t\t process partial RPN\n";
    exit;
}

if ( $option{ I } )
{    
    require $option{ I }."/RPN.pm" ;
  
    
}else
{
    require Parse::RPN;
}

$ENV{TZ}= $option{ T } if (  $option{ T } );

import Parse::RPN;
#use Module::Reload;

if ( $option{ o } )
{
    rpn_separator_out( $option{ o } );
}
if ( $option{ i } )
{
    rpn_separator_in( $option{ i } );
    $sep_in = $option{ i };
}

if ( $option{ v } )
{
    $ret = $Parse::RPN::VERSION;
}
else
{
    if ( $option{ f } )
    {
        if ( -f $option{ f } )
        {
            local $/;
            open FILE, $option{ f };
            my $buf = <FILE>;
            $ret = rpn( $buf );
            close FILE;
        }
        else
        {
            print "No source file " . $option{ f } . "\n";
        }
    }
    elsif ( $option{ r } )
    {
        my $data = $option{ r };
        if ( $option{ p } )
        {
            $data = partial_rpn( $data );
            print "$ret\n";
        }
        $ret = rpn( $data );
    }
    elsif ( $option{ S } )
    {
        if ( eval { require Term::ReadLine; 1; } ne 1 )
        {
# if module can't load
            print "!!! No module Term::ReadLine fall back to perl readline diamond operator\n\n";

            print "Shell mode\n";
            print "IN separator=" . $option{ i } . "\n"  if ( exists $option{ i } );
            print "OUT separator=" . $option{ o } . "\n" if ( exists $option{ o } );
            local $/ = "\n";
            while ( my $ret = <> )
            {
                chomp $ret;
                print "=" x 50 . "\n";
                print "\n";
                if ( $option{ p } )
                {
                    $ret = partial_rpn( $ret );

                    print "$ret\n";
                    print "\n";
                    print "-" x 50 . "\n";
                }
                $ret = rpn( $ret );

                print "$ret\n\n";
                print "#" x 50 . "\n";
            }
        }
        else
        {
            my $term = new Term::ReadLine 'RPN.pl';
            my $attribs = $term->Attribs();
            $term->using_history();
            $term->read_history($history_file);
            $term->clear_signals();
            my $line;
            while ( defined( $line = $term->readline( 'RPN to evaluate>' ) ) )
            { 
	       
	        reload() ;
                if ( $line =~ /^\\c\s+(\w)(\s*)(.*)$/ )
                {
                    my $cmd = $1;
                    my $arg = $3;

                    if ( $cmd =~ /q/ )
                    {
                        exit;
                    }
                    elsif ( $cmd =~ /o/ )
                    {
                        rpn_separator_out( $arg );
                    }
                    elsif ( $cmd =~ /i/ )
                    {
                        rpn_separator_in( $arg );
                    }
                    elsif ( $cmd =~ /d/ )
                    {
                        $DEBUG ^= 1;
                    }
		    elsif ( $cmd =~ /r/ )
                    {  
                        reload(1) ;
                    }
		    elsif ( $cmd =~ /H/ )
                    {  
                        $history_file =  glob($arg);
                    }
                    elsif ( $cmd =~ /h/ )
                    {
                        print "IN sep=[" . rpn_separator_in() . "]\n";
                        print "OUT sep=[" . rpn_separator_out() . "]\n";
                        print "DEBUG =[$DEBUG]\n";
			print "TZ=[". $ENV{TZ}."]\n";
			print "HIST=[". $history_file."]\n";
	            }
		    elsif ( $cmd =~ /t/i )
                    { 
		        print "<$arg>\n";
                        $ENV{TZ} = $arg;
                    }
                    else
                    {
                        print "possible commands:\n\n";
                        print "\\c o X \t set output separator to X\n";
                        print "\\c i X \t set input separator to X\n";
                        print "\\c h \t display current separators\n";
                        print "\\c d \t toggle debug mode\n";
			print "\\c r \t force reload of module RPN.pm\n";
			print "\\c t X \t set the time zone (TZ) to X\n";
                        print "\\c q \t quit the program\n";
			print "\\c H X \t set the histoty file to X\n";
                        print "\\c X \t any other argument display this help\n";
                    }
                }
		else
		{
		    $term->write_history($history_file);
                    my $res = rpn( $line );
                    print $res, "\n" unless $@;
		}
            }

        }
    }
}
print "$ret\n";

if ( $DEBUG )
{
    print rpn_error() . "\n";
}

sub print1
{

    return shift;
}

sub save
{
    my $file = shift;
    my $data = shift;
    print "save file=$file\tdata=$data\n";
    open FILE, ">/tmp/$file";
    print FILE $data;
    close FILE;
}

sub restore
{
    my $file = shift;

    open FILE, "/tmp/$file";
    my $data = <FILE>;
    close FILE;
    print "restore file=$file\tdata=$data\n";
    return $data;
}

sub partial_rpn
{
    my $data = shift;
    if ( $data =~ /(^|(.*)$sep_in)(\d+)($sep_in)RPN($sep_in(.*)|$)/ )
    {
        my $before = $2;
        my $size   = $3;
        my $after  = $5;
        $before =~ s/((($sep_in)[^$sep_in]*){$size})$//;
        my $tmp = $1;
        my $r   = rpn( $tmp );
        $data = $before . $sep_in . $r . $sep_in . $after;
        $data =~ s/$sep_in+/$sep_in/g;
    }
    return $data;
}

sub substit
{
    my $var = shift;
#print "in substit with <$var>\n";
    return $S{ $var };

}

sub substit2
{
    my $var = shift;
    my $ref = shift;

    print "in substit with <$var> <$ref>\n";

    return "$ref -> $var ";

}

sub reload {
    my $force=shift;
    my $c=0;
    while (my($key,$file) = each %INC) {
        next unless ( $key =~ /RPN\.pm/ );
        local $^W = 0;
        my $mtime = (stat $file)[9];
        $Stat{$file} = $^T
            unless defined $Stat{$file};
        if ($force || $mtime > $Stat{$file}) {
            delete $INC{$key};
            eval { 
                local $SIG{__WARN__} = \&warn;
                require $key;
            };
            if ($@) {
                warn "Reload: error during reload of '$key': $@\n"
            }
            ++$c;
        }
        $Stat{$file} = $mtime;
    }
    $c;
}

