#!/usr/bin/perl -w

use lib qw(./blib/lib ./blib/arch);
use Moot;
use JSON;
use Getopt::Long;
use File::Basename qw(basename);
use Pod::Usage;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our $outfile = '-';

our $ifmt_request = '';
our $ifmt_default = Moot::tiofText();

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'input-format|ifmt|format|fmt|I=s' => \$ifmt_request,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##------------------------------------------------------------------------------
## MAIN

push(@ARGV,'-') if (!@ARGV);
foreach my $file (@ARGV) {
  my $tr = Moot::TokenIO::file_reader($file, $ifmt_request, 0, $ifmt_default)
    or die("$0: file_reader() failed for $file: $!");

  print "%% FILE=$file : FORMAT=", Moot::TokenIO::format_canonical_string($tr->format), "\n";
  my ($w);
  while (defined($w=$tr->get_token)) {
    $w->{type} .= ' '.$Moot::TokType[$w->{type}];
    print to_json($w, {utf8=>1,pretty=>0,canonical=>1}), "\n";
  }
}

__END__

=pod

=head1 NAME

  moot-scan.perl - scan moot input file(s) into a stream of JSON objects

=head1 SYNOPSIS

 moot-scan.perl [OPTIONS] INPUT_FILE(s)...

 Options:
  -help                     # this help message
  -input-format FORMAT	    # request a specific input format

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

not yet written.

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

not yet written.

=cut


##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
