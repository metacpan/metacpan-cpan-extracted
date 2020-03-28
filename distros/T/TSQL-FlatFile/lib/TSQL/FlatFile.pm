package TSQL::FlatFile;

use 5.010;
use strict;
use warnings;

use Text::CSV;


=head1 NAME

TSQL::FlatFile - secret module by Ded MedVed

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


use Data::Dumper ;
use Carp ;

sub new {

    local $_ = undef ;

#warn Dumper @_;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {}, $class ;
   
    $self->_init(@elems) ;
    return $self ;
}


sub _init {

    local $_ = undef ;

#warn Dumper @_;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    my $ref = shift or croak "no arg";

#print Dumper $ref ;

    return ;
    
}

sub processLine {
  
    my $self       = shift or croak 'no self';
    
    my $afile       = shift || croak 'no ascii file';
    my $cfile       = shift || croak 'no csv file'; 

    my $filepos     = shift || croak 'no file position given' ;


my $li=0;

my %csv_row;
my $ascii_row;

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $csvfile or die "csvfile: $!";
$cfile->header($fh);
while ((my $row = $csv->getline_hr  ($fh)) && ($li++ < $linenumber)) {
#    warn Dumper $row;
    %csv_row = %$row;
    }
#warn Dumper %csv_row;
#warn Dumper keys %csv_row;
my @vals = sort { length($csv_row{$b}) <=> length($csv_row{$a}) } keys %csv_row;
 
close $fh;


$li=0;
open(my $afile, "<", $asciifile)  or die "Could not open file $!";
#skip header
my $row = <$afile>;
while (defined(my $row = <$afile> ) && ($li++ < $linenumber)) {
    chomp $row;
    $ascii_row = $row;
}
#warn Dumper $ascii_row;    
#print "done\n";

#find where vals in csv match ascii

#say $ascii_row;
my %positions ;
foreach my $v (@vals){
    my $val = $csv_row{$v}." *";
#    warn Dumper $val;
    
    $ascii_row  =~ m/(?>$val)/;
    $positions{$v} = [@-,@+];
#warn Dumper @-, @+;

    $ascii_row = $`. "^"x length($&) . $';
 #say $ascii_row;          
 #   warn Dumper $$_[0][0],$$_[1][0],$$_[2][0],$$_[3],$$_[4] for exhaustive($ascii_row => qr/(?>$val)/, qw[ @- $^R @+ $` $']); 
}

my @sortedkeys = sort { $positions{$a}[0] <=> $positions{$b}[0]} keys %positions;
{
  my $i=1;
  foreach my $k (@sortedkeys) {
    if ($debug) { say $k,"\t"x((55-length($k))/8), $positions{$k}[0],"\t", $positions{$k}[1]};
    $i++;
  }
}
if (!$debug) {say "12.0"};
if (!$debug) {say scalar(@sortedkeys)};
{
  my $i=1;
  foreach my $k (@sortedkeys) {
    if (!$debug) {say $i,"\t","SQLCHAR","\t","0","\t",$positions{$k}[1]-$positions{$k}[0],"\t",($i == scalar(@sortedkeys)) ? '"\r\n"':'""',"\t", $i,"\t", $k,"\t"x((55-length($k))/8),"SQL_Latin1_general_CP1_CI_AS"};
    $i++;
  }
}








    
}





sub commentifyPreTestAction {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->preTestAction()]}
            ${commentChars}
EOF
}

sub commentifyTestAction {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->testAction()]}
            ${commentChars}
EOF
}

sub commentifyPostTestAction {
    my $self            = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->postTestAction()]}
            ${commentChars}
EOF
}

sub commentifyActionDataName {
    my $self    = shift;
    my $commentChars    = shift or croak 'No Chars' ;
    return <<"EOF";
            ${commentChars}
            ${commentChars}@{[$self->testActionDataName()]}
            ${commentChars}
EOF
}

sub preTest_conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        my @conditions      = @$conditions ;
        $self->{PRETEST_TESTCONDITIONS} = \@conditions ;
    }
    return $self->{PRETEST_TESTCONDITIONS} ;
}

sub test_conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        my @conditions      = @$conditions ;
        $self->{TEST_TESTCONDITIONS} = \@conditions ;
    }
    return $self->{TEST_TESTCONDITIONS} ;
}

sub postTest_conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
        my @conditions      = @$conditions ;
        $self->{POSTTEST_TESTCONDITIONS} = \@conditions ;
    }
    return $self->{POSTTEST_TESTCONDITIONS} ;
}

sub conditions {
    my $self            = shift or croak 'no self';
    my $conditions ;
    $conditions         = shift if @_;
    if ( defined $conditions ) {
croak 'obsoleted method' ;  
    }
    my $preTestConditions  = $self->preTest_conditions() ;
    my $testConditions     = $self->test_conditions() ;
    my $postTestConditions = $self->postTest_conditions() ;
    my @Conditions =  flatten ([@$preTestConditions,@$testConditions,@$postTestConditions]);
    
    return \@Conditions ;
}

sub preTestAction {
    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    # normalise
    if ( defined $action ) {
        $action = 'null' if $action =~ m{^null|nothing$}ix ;
        $self->{PRETESTACTION} = $action ;
    }
    return $self->{PRETESTACTION} ;

}
sub testAction {
    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    # normalise
    if ( defined $action ) {
        $action = 'null' if $action =~ m{^null|nothing$}ix ;
        $self->{TESTACTION} = $action ;
    }
    return $self->{TESTACTION} ;

} 
sub postTestAction {
    my $self        = shift or croak 'no self';
    my $action ;
    $action         = shift if @_;
    # normalise
    if ( defined $action ) {
        $action = 'null' if $action =~ m{^null|nothing$}ix ;
        $self->{POSTTESTACTION} = $action ;
    }
    return $self->{POSTTESTACTION} ;

}


sub flatten { return map { @$_} @_ } ;

sub DESTROY {}

1 ;

__DATA__


