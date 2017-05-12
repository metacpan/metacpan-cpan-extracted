package PBS::Output ;

use 5.006 ;
use strict ;
use warnings ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.03' ;

BEGIN
{
	if ($^O eq 'MSWin32')
	{
		eval "use Win32::Console::ANSI;";
	}
};

use Term::ANSIColor qw(:constants) ;
$Term::ANSIColor::AUTORESET = 1 ;

use vars qw($VERSION @ISA @EXPORT) ;

require Exporter;

@ISA     = qw(Exporter AutoLoader) ;
@EXPORT  = qw(
					ERROR WARNING WARNING2 INFO INFO2 USER SHELL DEBUG
					PrintError PrintWarning PrintWarning2 PrintInfo PrintInfo2 PrintUser PrintShell PrintDebug
					GetLineWithContext PrintWithContext PbsDisplayErrorWithContext
				) ;
				
$VERSION = '0.05' ;

our $colorize ;
our $indentation = '   ' ;
our $query_on_warning ;
our $display_error_context ;

our $global_error_escape_code    = '' ;
our $global_warning_escape_code  = '' ;
our $global_warning2_escape_code = '' ;
our $global_info_escape_code     = '' ;
our $global_info2_escape_code    = '' ;
our $global_user_escape_code     = '' ;
our $global_shell_escape_code    = '' ;
our $global_debug_escape_code    = '' ;
our $global_reset_escape_code    = Term::ANSIColor::color('reset') ;

#-------------------------------------------------------------------------------

sub NoColors
{
$global_error_escape_code    = '' ;
$global_warning_escape_code  = '' ;
$global_warning2_escape_code = '' ;
$global_info_escape_code     = '' ;
$global_info2_escape_code    = '' ;
$global_user_escape_code     = '' ;
$global_shell_escape_code    = '' ;
$global_debug_escape_code    = '' ;
$global_reset_escape_code    = '' ;
}

sub SetOutputColor
{
my $switch = shift ;
my $color  = shift ;

my $escape_code = '' ;

eval {$escape_code = Term::ANSIColor::color($color) ;} ;

if($@)
	{
	print "Invalid color definition '$switch: $color', using default color.\n" ;
	}
else
	{
	$global_error_escape_code    = $escape_code if ($switch eq 'ce'  || $switch eq 'color_error') ;
	$global_warning_escape_code  = $escape_code if ($switch eq 'cw'  || $switch eq 'color_warning') ;
	$global_warning2_escape_code = $escape_code if ($switch eq 'cw2' || $switch eq 'color_warning2') ;
	$global_info_escape_code     = $escape_code if ($switch eq 'ci'  || $switch eq 'color_info') ;
	$global_info2_escape_code    = $escape_code if ($switch eq 'ci2' || $switch eq 'color_info2') ;
	$global_user_escape_code     = $escape_code if ($switch eq 'cu'  || $switch eq 'color_user') ;
	$global_shell_escape_code    = $escape_code if ($switch eq 'cs'  || $switch eq 'color_shell') ;
	$global_debug_escape_code    = $escape_code if ($switch eq 'cd'  || $switch eq 'color_debugger') ;
	}
}

sub ERROR
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_error_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub WARNING
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_warning_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub WARNING2
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_warning2_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub INFO
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;

$string =~ s/\n(.)/\n$indent$1/g ;

return $global_info_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub INFO2
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_info2_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub USER
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_user_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub SHELL
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_shell_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub DEBUG
{
my $indent = '' ;
$indent = $PBS::Output::indentation x $PBS::PBS::Pbs_call_depth unless (defined $_[1] && $_[1] == 0) ;

my $string = $indent . (defined $_[0] ? $_[0] : "[PBS::Output received 'undef'!]") ;
$string =~ s/\n(.)/\n$indent$1/g ;

return $global_debug_escape_code . $string . $global_reset_escape_code if (defined $PBS::Output::colorize) ;
return($string) ;
}

sub PrintError 
{
print STDERR ERROR(@_) ;
}

sub PrintWarning 
{
#~ my ($package, undef, $line) = caller() ;
#~ print "Warning from $package:$line\n" ;

print WARNING(@_) ;

if(defined $PBS::Output::query_on_warning)
	{
	print "Continue [return|y|yes]? " ;
	my $answer = <STDIN> ;
	chomp $answer ;
	
	die unless ($answer =~ /^(y(es)*)*$/i) ;
	}
}

sub PrintWarning2
{
print WARNING2(@_) ;

if(defined $PBS::Output::query_on_warning)
	{
	print "Continue [return|y|yes]? " ;
	my $answer = <STDIN> ;
	chomp $answer ;
	
	die unless ($answer =~ /^(y(es)*)*$/i) ;
	}
}

sub PrintInfo
{
print STDOUT INFO(@_) ;
}

sub PrintInfo2
{
print STDOUT INFO2(@_) ;
}

sub PrintUser
{
print STDOUT USER(@_) ;
}

sub PrintShell 
{
print STDOUT SHELL(@_) ;
}

sub PrintDebug
{
print STDERR DEBUG(@_) ;
}

#-------------------------------------------------------------------------------

sub GetLineWithContext
{
my $file_name                   = shift ;
my $number_of_blank_lines       = shift ;
my $number_of_context_lines     = shift ;
my $center_line_index           = shift ;
my $center_line_colorizing_sub  = shift || sub{$_[0]} ;
my $context_colorizing_sub      = shift || sub{$_[0]} ;

open(FILE, '<', $file_name) or die ERROR qq[Can't open $file_name for context display: $!] ;

my $number_of_lines_skip = ($center_line_index - $number_of_context_lines) - 1 ;

my $top_context = $number_of_context_lines ;
$top_context += $number_of_lines_skip if $number_of_lines_skip < 0 ;

my $line_with_context = '' ;

$line_with_context.= "\n" for (1 .. $number_of_blank_lines) ;

<FILE> for (1 .. $number_of_lines_skip) ;

$line_with_context .= INFO("File: '$file_name'\n") ;

for(1 .. $top_context)
	{
	my $text = <FILE> ;
	next unless defined $text ;

	$line_with_context .=  $context_colorizing_sub->("$.- $text") ;
	}
		
my $center_line_text = <FILE> ;
$line_with_context .= $center_line_colorizing_sub->("$.> $center_line_text") if defined $center_line_text ;


for(1 .. $number_of_context_lines)
	{
	my $text = <FILE> ;
	next unless defined $text ;
	
	$line_with_context .= $context_colorizing_sub->("$.- $text") ;
	}

$line_with_context .= "\n" for (1 .. $number_of_blank_lines) ;

close(FILE) ;

return($line_with_context) ;
}

#-------------------------------------------------------------------------------
sub PrintWithContext
{
print GetLineWithContext(@_) ;
}

#-------------------------------------------------------------------------------
sub PbsDisplayErrorWithContext
{
PrintWithContext($_[0], 1, 3, $_[1], \&ERROR, \&INFO) if defined $PBS::Output::display_error_context ;
}

#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Output -

=head1 SYNOPSIS

  use PBS::Information ;
  PrintUser("Hello user\n") ;

=head1 DESCRIPTION

if B<Term::ANSIColor> is installed in your system, the output generated by B<PBS::Output> functions will be colorized.
the colors are controlled through I<SetOutputColor> which is itself (in B<PBS> case) controled through command
line switches.

I<GetLineWithContext> will return a line, from a file, with its context. Not unlike grep -Cn.

=head2 EXPORT

	ERROR WARNING WARNING2 INFO INFO2 USER SHELL DEBUG
	PrintError PrintWarning PrintWarning2 PrintInfo PrintInfo2 PrintUser PrintShell PrintDebug

	GetLineWithContext PrintWithContext PbsDisplayErrorWithContext

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO


=cut
