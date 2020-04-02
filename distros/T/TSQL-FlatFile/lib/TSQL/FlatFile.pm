package TSQL::FlatFile;

use 5.010;
use strict;
use warnings;

use Text::CSV;


=head1 NAME

TSQL::FlatFile - secret module by Ded MedVed

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';


use Data::Dumper ;
use Carp ;

sub new {

    local $_ = undef ;
    
#warn Dumper @_;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {crlf => "\r\n" }, $class ;
   
#    $self->_init(@elems) ;
    return $self ;
}

sub crlf {
    my $self = shift;
    return $self->{crlf};
    
}
sub processLine {
#warn Dumper @_;  
    my $self                    = shift or croak 'no self';
                
    my $asciifile               = shift || croak 'no ascii file name';
    my $cfile                   = shift || croak 'no csv file'; 
    my $cfile_fh                = shift || croak 'no csv file handle'; 
            
    my $filepos                 = shift || croak 'no file position given' ;
    my $incrementalsearch       = shift ;
    if (!defined $incrementalsearch) {
        croak 'no incrementalsearch flag given' ;
    }    my $debug                   = shift ;

    if (!defined $debug) {
        croak 'no debug flag given' ;
    }
    
    my $li=0;
    
    my %csv_row;
    my $ascii_row;
    
    $cfile->header($cfile_fh);
    while ((my $row = $cfile->getline_hr  ($cfile_fh)) && ($li++ < $filepos)) {
    #    warn Dumper $row;
        %csv_row = %$row;
    }
    #warn Dumper %csv_row;
    #warn Dumper keys %csv_row;
    my @vals = sort { length($csv_row{$b}) <=> length($csv_row{$a}) } keys %csv_row;
    
    $li=0;
    open(my $afile, "<", $asciifile)  or die "Could not open file $!";
    #skip header
    my $row = <$afile>;
    while (defined(my $row = <$afile> ) && ($li++ < $filepos)) {
        chomp $row;
        $ascii_row = $row;
    }
    
    #say $ascii_row;
    my %positions ;
    foreach my $v (@vals){
        my $val = quotemeta($csv_row{$v})." *";
        $ascii_row  =~ m/(?>$val)/;
        $positions{$v} = [@-,@+];
        $ascii_row = $`. "^"x length($&) . $';
    }
    
    my @sortedkeys = sort { $positions{$a}[0] <=> $positions{$b}[0]} keys %positions;
    #warn of any mismatches
    my $blanklines = "";
    foreach my $k (@sortedkeys) {
        if ($positions{$k}[0] == $positions{$k}[1] ) {
            warn "${k}: hasn't matched data - values ",$positions{$k}[0],":",$positions{$k}[1];
            $blanklines = $self->crlf;
        };
    };
    #warn of any gaps in matching;
    if ( $ascii_row !~ /\A[\^]*\z/igms ) {
        warn $ascii_row;
        $blanklines = $self->crlf unless $blanklines eq "";
    }
    
    warn $blanklines if $blanklines;
    
    my $result = "";   
    if ($debug) {
        my $i=1;
        foreach my $k (@sortedkeys) {
            if ($debug) { $result .= ($k . ("\t"x((55-length($k))/8)) . $positions{$k}[0] . "\t" . $positions{$k}[1]). $self->crlf };
            $i++;
        }
    }
    else {
        $result .= "12.0" . $self->crlf;
        $result .= (scalar(@sortedkeys)) .$self->crlf;
        my $i=1;
        foreach my $k (@sortedkeys) {
            $result .= ($i . "\t" . "SQLCHAR" . "\t" . "0" . "\t" . ($positions{$k}[1]-$positions{$k}[0]) . "\t" . (($i == scalar(@sortedkeys)) ? '"\r\n"':'""') . "\t" .  $i . "\t" .  $k . "\t"x((55-length($k))/8) . "SQL_Latin1_general_CP1_CI_AS") . $self->crlf;
            $i++;
        }
    }
    return $result;
}


sub getLinePositions {
#warn Dumper @_;  
    my $self        = shift or croak 'no self';
    
    my $asciifile   = shift || croak 'no ascii file name';
    my $cfile       = shift || croak 'no csv file'; 
    my $cfile_fh    = shift || croak 'no csv file handle'; 

    my $filepos     = shift || croak 'no file position given' ;
    my $incrementalsearch       = shift ;
    if (!defined $incrementalsearch) {
        croak 'no incrementalsearch flag given' ;
    }    my $debug                   = shift ;

    my $li=0;
    
    my %csv_row;
    my $ascii_row;
    
    $cfile->header($cfile_fh);
    while ((my $row = $cfile->getline_hr  ($cfile_fh)) && ($li++ < $filepos)) {
        %csv_row = %$row;
#say $li, $csv_row{capcode};
    }
#say $li, $csv_row{capcode};
    #warn Dumper keys %csv_row;
    my @vals = sort { length($csv_row{$b}) <=> length($csv_row{$a}) } keys %csv_row;
    
    $li=0;
    open(my $afile, "<", $asciifile)  or die "Could not open file $!";
    #skip header
    my $row = <$afile>;
    while (defined(my $row = <$afile> ) && ($li++ < $filepos)) {
        chomp $row;
        $ascii_row = $row;
#say $li," ", $ascii_row;
    }
#say $li," ", $ascii_row;    
    #say $ascii_row;
    my %positions ;
    foreach my $v (@vals){
        my $val = quotemeta($csv_row{$v})." *";
        $ascii_row  =~ m/(?>$val)/;
        $positions{$v} = [@-,@+];
        $ascii_row = $`. "^"x length($&) . $';
    }
    
    my @sortedkeys = sort { $positions{$a}[0] <=> $positions{$b}[0]} keys %positions;
    my @result = ();
    {
      my $i=0;
      foreach my $k (@sortedkeys) {
        $result[$i] = {key=>$k,start=>$positions{$k}[0],end=>$positions{$k}[1]};
        $i++;
      }
    }

    my $unmatchedcount = 0;
    foreach my $k (@sortedkeys) {
        if ($positions{$k}[0] == $positions{$k}[1] ) {
            $unmatchedcount++;
        };
    };

    my $unmatchedamount = length($ascii_row) - $ascii_row =~ tr/^//;

my @best_result          = @result;
my $best_line            = $filepos; 
my $best_unmatchedcount  = $unmatchedcount; 
my $best_unmatchedamount = $unmatchedamount;

#$li = $filepos;

#exit;

if  ($incrementalsearch && ( $best_unmatchedcount > 0 || $best_unmatchedamount > 0 ) ) {

##    my $readnext = 1;
    
    while ((my $crow = $cfile->getline_hr  ($cfile_fh)) && (defined(my $row = <$afile> )) && ($li++ < $filepos+100 ) && ( $best_unmatchedcount > 0 || $best_unmatchedamount > 0 ) ) {
 
        %csv_row = %$crow;
        
#warn Dumper %csv_row;
#warn Dumper keys %csv_row;
        my @vals = sort { length($csv_row{$b}) <=> length($csv_row{$a}) } keys %csv_row;
        
        
        chomp $row;
        $ascii_row = $row;
    
#        say $li," ", $ascii_row;
#say Dumper %csv_row;
        my %positions ;
        foreach my $v (@vals){
            my $val = quotemeta($csv_row{$v})." *";
            $ascii_row  =~ m/(?>$val)/;
            $positions{$v} = [@-,@+];
#warn Dumper $val  unless defined $` ;        
#warn  $ascii_row unless defined $` ;
    
            $ascii_row = $`. "^"x length($&) . $';
        }
        
        my @sortedkeys = sort { $positions{$a}[0] <=> $positions{$b}[0]} keys %positions;
        my @result = ();
        {
            my $i=0;
            foreach my $k (@sortedkeys) {
                $result[$i] = {key=>$k,start=>$positions{$k}[0],end=>$positions{$k}[1]};
                $i++;
            }
        }
        
        
        my $unmatchedcount = 0;
        foreach my $k (@sortedkeys) {
            if ($positions{$k}[0] == $positions{$k}[1] ) {
                $unmatchedcount++;
            };
        };
    
        my $unmatchedamount = length($ascii_row) - $ascii_row =~ tr/^//;
    
        @best_result          = @result           if $unmatchedcount  < $best_unmatchedcount || $unmatchedamount < $best_unmatchedamount; 
    
        $best_line            = $li               if $unmatchedcount  < $best_unmatchedcount || $unmatchedamount < $best_unmatchedamount; 
        $best_unmatchedcount  = $unmatchedcount   if $unmatchedcount  < $best_unmatchedcount; 
        $best_unmatchedamount = $unmatchedamount  if $unmatchedamount < $best_unmatchedamount; 
        
        @result     = @best_result;
        }
    }
    return \{ positions => \@result, best_line => $best_line, best_unmatchedcount => $best_unmatchedcount, best_unmatchedamount => $best_unmatchedamount }  ;
}


sub flatten { return map { @$_} @_ } ;

sub DESTROY {}

1 ;

__DATA__


