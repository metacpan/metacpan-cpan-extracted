#!/usr/bin/env perl
use strict; use warnings; use feature qw/say/;
STDOUT->autoflush; STDERR->autoflush;

# define "console_in", "console_out", "locals_fs" encodings
use Encode::Locale qw/decode_argv/;
use Encode ();

use FindBin qw($Bin);

use File::Basename qw/basename/;
use DateTime ();
use DateTime::Format::Strptime ();
use Getopt::Long qw/GetOptions/;

use Spreadsheet::Edit qw/read_spreadsheet alias apply sort_rows %crow/;
use Data::Dumper::Interp 6.005 qw/dvis qsh qshlist/;
Data::Dumper::Interp::addrvis_digits(5); # for Author's debugging :-)

use ODF::lpOD;
use ODF::lpOD_Helper;
use ODF::MailMerge 1.000 qw/replace_tokens/;

sub commify_number($) {
  scalar reverse (reverse($_[0]) =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/gr)
}

my ($outpath, $also_pdf, $also_txt, $skelpath, $dbpath, $quiet);
decode_argv( Encode::FB_CROAK );
GetOptions(
  'o|outpath=s'  => \$outpath,
  '--pdf'        => \$also_pdf,
  '--txt'        => \$also_txt,
  's|skelpath=s' => \$skelpath,
  'd|dbpath=s'   => \$dbpath,
  'q|quiet'      => \$quiet,
) or die "bad arguments";

$skelpath //= "$Bin/Ex_Famnames_Skeleton.odt";

$outpath //= "./".basename($skelpath) =~ s/_?Skel[a-z]*//r =~ s/\.odt/_output.odt/r;
die if $outpath eq $skelpath;

$dbpath //= "$Bin/family_names.csv";

#---------------------------------------------------------------

############################
# Load the 'skeleton' document
############################
warn "> Loading $skelpath\n" unless $quiet;
my $doc = odf_get_document($skelpath, read_only => 1) // die "$skelpath : $!";
my $body = $doc->get_body;

############################
# Read the "data base" (just a .csv file)
############################
warn "> Reading $dbpath\n" unless $quiet;
read_spreadsheet($dbpath);

# Make alias identifiers for column titles matched by regular expressions.
# This is so we don't have to know the exact text of column titles here.
# The alias names will be keys in the row hashes.  See Spreadsheet::Edit .
alias Name => qr/name/i;
alias Rank => qr/rank/i;
alias Origin => qr/origin/i;
alias Population => qr/pop/i;

my $highest_Rank = 0;
# "apply" visits all spreadsheet data rows (i.e. rows after the title row),
# executing the specified code block.  %crow is a tied hash which maps
# column titles *and aliases* to the corresponding data value in
# the "current row" being visited.
apply { $highest_Rank = $crow{Rank} if $crow{Rank} > $highest_Rank; };

########################################
# Generate the table showing data alphabetized by Name
########################################
sort_rows { $a->{Name} cmp $b->{Name} };

# Visit all the data rows and create an entry in the document for each
{ my $engine = ODF::MailMerge::Engine->new(
                        context => $body, proto_tag => "{ByName_Proto}");
  apply {
    my $hash = {  # massage the data before displaying
      Name       => $crow{Name},
      Rank       => $crow{Rank},
      Origin     => $crow{Origin},
      Population => commify_number($crow{Population}),
    };
    $engine->add_record($hash);
  };
  $engine->finish();
}

########################################
# Generate the by-popularity table
########################################
sort_rows { $a->{Rank} <=> $b->{Rank} };
{ my $engine = ODF::MailMerge::Engine->new(
                        context => $body, proto_tag => "{ByPop_Proto}");
  apply {
    $engine->add_record(\%crow);
  };
  $engine->finish();
}

########################################
# Generate the by-origin table using a separate row for each name
# For brevity, origins including English are omitted.
########################################
{ my %Origin_to_Names;
  apply {
    push @{ $Origin_to_Names{$crow{Origin}} }, $crow{Name}
      if $crow{Origin} !~ /English/;
  };
  { my $engine = ODF::MailMerge::Engine->new(
                context => $body, proto_tag => "{ByOriginNonEng_Proto}");
    foreach my $origin (sort keys %Origin_to_Names) {
      my $namelist = $Origin_to_Names{$origin};
      my $hash = {
        Origin => $origin,
        Names  => $namelist,
      };
      $engine->add_record($hash);
    }
    $engine->finish();
  }
}

########################################
# Generate the complete by-origin table, using a comma-separated
# list of names for each origin.
#
# There are two {Name} tags with different conditionals, each in its own
# frame; one conditional matches the the last item in the list, the other
# matches all items before the last and includes a ", " after the token
# in it's frame.  The result is like "name1, name2, ..., nameLast" when
# the substituted values are strung together.
#
# When a multi-valued {token} is encapsulated in a frame, the frame is
# replicated instead of a whole table row; this is what allows multiple
# values to end up on the same line in the result (the frames are
# anchored "as Character" in the same paragraph).
#
# See the Ex_Famnames_Skeleton.odt document for how this is set up.
########################################
{ my %Origin_to_Names;
  apply {
    push @{ $Origin_to_Names{$crow{Origin}} }, $crow{Name};
  };
  { my $engine = ODF::MailMerge::Engine->new(
                        context => $body, proto_tag => "{ByOrigin2_Proto}");
    foreach my $origin (sort keys %Origin_to_Names) {
      my $namelist = $Origin_to_Names{$origin};
      my $hash = {
        Origin => $origin,
        Names  => $namelist,
      };
      $engine->add_record($hash, debug => 0);
    }
    $engine->finish();
  }
}

########################################
# Replace "{Database Date}" with the modification time of the data file
########################################
my $dbpath_mt_unixtime = (stat($dbpath))[9];
my $dbpath_mt_dt = DateTime->from_epoch(epoch => $dbpath_mt_unixtime);
my $dbpath_mt_string = $dbpath_mt_dt->strftime("%Y-%m-%d");
replace_tokens($body, { "Database Date" => $dbpath_mt_string })
 == 1 or die "Did not find {Database Date}";

########################################
# Write out the result
########################################
warn "> Writing $outpath\n" unless $quiet;
$doc->save(target => $outpath);

if ($also_pdf) {
  my @cmd = ("libreoffice", "--convert-to", "pdf", $outpath);
  warn "> ", qshlist(@cmd),"\n" unless $quiet;
  system @cmd;
}
if ($also_txt) {
  # C.F. https://help.libreoffice.org/latest/en-US/text/shared/guide/convertfilters.html
  my @cmd = ("libreoffice", "--convert-to", "txt:Text (encoded):UTF8", $outpath);
  warn "> ", qshlist(@cmd),"\n" unless $quiet;
  system @cmd;
}

exit 0;
