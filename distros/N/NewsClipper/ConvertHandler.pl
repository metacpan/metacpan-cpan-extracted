#!/usr/bin/perl

# use perl                                  -*- mode: Perl; -*-

use strict;

my $COMPATIBLE_NEWS_CLIPPER_VERSION = '1.18';
my $VERSION = 0.14;
my $handlerserver = 'handlers.newsclipper.com';
#my $handlerserver = 'localhost';

#-------------------------------------------------------------------------------

die <<EOF
$0 handler1.pm handler2.pm ...

Run this program to modernize handlers built for a version of News Clipper
prior to $COMPATIBLE_NEWS_CLIPPER_VERSION
EOF
  if $#ARGV == -1 || $ARGV[0] =~ /^-/;

DisplayMessage();

foreach my $handler (@ARGV)
{
  print "----> Processing handler $handler...\n";

  open HANDLER, $handler or die "Can't open handler: $!\n";
  my $code = join '',<HANDLER>;
  close HANDLER;

  my $old_code = $code;

  my $old_version = GetNewsClipperVersion($code);

  if (defined $old_version && $old_version >= $COMPATIBLE_NEWS_CLIPPER_VERSION)
  {
    print <<"    EOF";
This handler is for News Clipper version $old_version,
  and this ConvertHandler will update up to version $COMPATIBLE_NEWS_CLIPPER_VERSION.
  No need to update.
    EOF

    next;
  }

  if ($old_version < 1.18)
  {
    $code = CleanTrailingSpacesAndLinefeeds($code);
    print "================\n";
    $code = ConvertComments($code);
    print "================\n";
    $code = ConvertVersion($code);
    print "================\n";
    $code = StripUses($code);
    print "================\n";
    $code = StripDprint($code);
    print "================\n";
    $code = ConvertDefaultHandlers($code);
    print "================\n";
    $code = ConvertOldPatternMatches($code);
    print "================\n";
    CheckGetFunction($code);
    print "================\n";
    CheckErrorMessage($code);
    print "================\n";
    CheckIsa($code);
    print "================\n";
    CheckRef($code);
    print "================\n";
    $code = ConvertFilterTypeFunction($code);
    print "================\n";
    $code = ConvertOutputTypeFunction($code);
    print "================\n";
    $code = ConvertTypeNames($code);
    print "================\n";
    $code = AddComputeURL($code);
    print "================\n";
    $code = AddSetDefaultAttributes($code);
    print "================\n";
    $code = CheckLeftOvers($code);
    print "================\n";
    $code = CleanTrailingSpacesAndLinefeeds($code);
  }

#print $code,"\n";
#next;
  if ($code eq $old_code)
  {
    print "No change to handler -- nothing written\n";
  }
  else
  {
    WriteHandler($handler,$code);
  }
}

#-------------------------------------------------------------------------------

sub GetNewsClipperVersion
{
  my $code = shift;

  my ($for_news_clipper_version) =
    $code =~ /'For_News_Clipper_Version'} *= *'(.*?)' *;/s;

  # Ug. Pre "For_News_Clipper_Version" days...
  if (!defined $for_news_clipper_version)
  {
    return 1.00;
  }
  else
  {
    return $for_news_clipper_version;
  }
}

#-------------------------------------------------------------------------------

sub Pager
{
  my $message = shift;

  my @lines = split /\n/,$message;
  my $count = 0;
  foreach my $line (@lines)
  {
    $count++;
    print "$line\n";
    print "Press enter..." and <STDIN> if $count % 24 == 0;
  }
}

#-------------------------------------------------------------------------------

sub DisplayMessage
{
  my $message =<<'  EOF';
Greetings! This program will convert handlers written for the prior version of
News Clipper. Here are the new things you should know about the new handler
format:

- The comment block has been replaced with a hash, which will help with the
  automated processing of the handler.
- "MAINTAINER_NAME" and "MAINTAINER_EMAIL" fields have been added.
- A "CATEGORY" field says what category the handler belongs. Be careful to
  choose a legal category.
- A "FOR_NEWSCLIPPER_VERSION" field tells what version of News Clipper the
  handler was built for. This helps accidental download of incompatible
  handlers.
- Version numbers have been updated so that you can indicate when a change
  will break people's input files, when a change adds functionality, and when
  a change fixes a bug.
- Types have changed substantially:
  - FilterType and OutputType return a "type signature", like "@($ | %)",
    which means "an array of either scalars or hashes". @($ & %Slashdot) means
    an array of at least one scalar and at least one Slashdot hash.
  - A hunk of data matches a type signature if the structure matches, and any
    subtype relationships hold. For example, a type signature of @($ | %)
    would be matched by a data strcuture whose type signature is @($URL),
    @Myarray(%), and @Myarray($URL & %Slashdot), but not by @(@). 
  - Everything in the data structure is a reference -- even scalars. So you
    can't do this:
      push @grabbedData, {'name' => $name, 'url' => $url}
    Instead, do this:
      push @grabbedData, {'name' => $name, 'url' => $url}
    And when you want to use it, you have to do this:
      print ${$hashref->{'name'}}
  - Bless each new data type, not the whole data structure. Instead of this:
      while ($line =~ /(.*)::(.*)/g)
      {
        my %hash = ('name' => $1,'url' => $2);
        push @data, \%hash;
      }
      MakeSubType('ArrayOfSlashdotHash','ArrayOfHash');
      bless \@data,'ArrayOfSlashdotHash';
    Do this:
      MakeSubType('Slashdot','HASH');
      while ($line =~ /(.*)::(.*)/g)
      {
        my %hash = ('name' => \\$1,'url' => \\$2);
        bless \%hash,'Slashdot';
        push @data, \%hash;
      }
  - Before, you had to bless things as "String", "Array", or "Hash". You don't
    have to do that now.
  - However, any new types you introduce should be related to the others with
    the MakeSubtype function:
      MakeSubtype('Slashdot','HASH');
- There's a new API function called TypesMatch(), which takes a data reference
  and a types signature, and returns 1 if the data matches the signature.
- dprint() can be used to send output as <!-- DEBUG: ... --> messages in debug
  mode.
- error() can be used to output errors about invalid arguments, etc.
- Default handlers are now specified as real News Clipper commands, like this:
    <filter name=map filter=highlight words=linux>
    <output name=array>
- FilterType and OutputType now provide the $data and $attributes as
  arguments, so you can return a different type signature depending on
  parameters such as "style".
- ComputeURL should now be used to compute the URL from the attributes. You'll
  probably need to do this by hand.
- SetDefaultAttributes should now be used to set the default attributes for
  the handler. For example, the "date" handler has a style attribute which
  defaults to "day": <input name="date" style="day">
- You should never have to check the type of $grabbedData -- News Clipper will
  do that for you.
- A RunHandler API function was added, which takes the handler name, type of
  handler, data, and attributes. It will automatically check for correct
  types.
- "use NewsClipper::Handler" automatically pulls in a lot of stuff, so you
  don't have to "use" the Types, HTMLTools, AcquisitionFunctions, DEBUG, 
  dprint, etc.

Nearly all of these will be automatically handled by this program. If
something can not be handled, a message will appear. This program will move
old copies of your handlers to .bak files, but backup your handlers anyway.
  EOF

  Pager $message;
}

#-------------------------------------------------------------------------------

sub CleanTrailingSpacesAndLinefeeds($)
{
  my $code = shift;

  $code =~ s/ +\n/\n/gs;
  $code =~ s/\r//gs;

  return $code;
}

#-------------------------------------------------------------------------------

sub ConvertComments($)
{
  my $code = shift;

  print "- Converting Comments\n";

  $code =~ /\n(#\s*AUTH.*?)\npackage /s;
  my ($commentBlock) = $1;

  print "Couldn't find comment block. Skipping comment conversion...\n" and
    return $code unless defined $commentBlock;
  
  my ($author) = $code =~ /AUTHOR: *(.*?) *\n/s;
  my ($email) = $code =~ /EMAIL: *(.*?) *\n/s;
  my ($description) = $code =~ /DESCRIPTION: *(.*?) *\n/s;
  my ($syntax) = $code =~ /SYNTAX: *(.*?)\n(# [A-Z][A-Z]+:|[^#])/s;
  my ($notes) = $code =~ /NOTES: *(.*?)\n(# [A-Z][A-Z]+:|[^#])/s;
  my ($url) = $code =~ /URL: *(.*?)\n/s;
  my ($license) = $code =~ /LICENSE: *(.*?)\n/s;

  print <<"  EOF"
Comment block couldn't be parsed correctly. Skipping comment conversion...
  EOF
    and return $code unless defined $author && defined $email && 
      defined $description && defined $syntax && defined $notes && 
      defined $url && defined $license;

  $author =~ s/[\n#]//gs;
  $author =~ s/  */ /g;
  $email =~ s/[\n#]//gs;
  $email =~ s/  */ /g;
  $description =~ s/[\n#]//gs;
  $description =~ s/  */ /g;
  $description =~ s/\n\s*$/\n/s;
  $description = '' if $description eq "\n";
  $description .= "\n" if $description ne '' && $description !~ /\n$/s;

  $syntax =~ s/^ *# *\n/\n/s while $syntax =~ /^ *#/s;
  $syntax =~ s/\n *# *$/\n/s while $syntax =~ /\n *# *$/s;
  $syntax =~ s/^\s+//s;
  $syntax =~ s/(^|\n) *#/$1/sg;
  $syntax = dequote ($syntax);
  $syntax =~ s/\n +\n/\n\n/s;
  $syntax =~ s/\n\s*$/\n/s;
  $syntax = '' if $syntax eq "\n";
  $syntax .= "\n" if $syntax ne '' && $syntax !~ /\n$/s;

  $notes =~ s/^ *# *\n//s while $notes =~ /^ *#/s;
  $notes =~ s/\n *# *$/\n/s while $notes =~ /\n *# *$/s;
  $notes =~ s/^\s+//s;
  $notes =~ s/(^|\n) *#/$1/sg;
  $notes = dequote ($notes);
  $notes =~ s/\n +\n/\n\n/s;
  $notes =~ s/\n\s*$/\n/s;
  $notes = '' if $notes eq "\n";
  $notes .= "\n" if $notes ne '' && $notes !~ /\n$/s;

  my $category;

  {
    my ($handler) =
      $code =~ /package NewsClipper::Handler::Acquisition::([^;]+);/;
    $category = GetCategory($handler);
  }

  my $newMetaInfo = <<"  EOF";
\$handlerInfo{'Author_Name'}              = '$author';
\$handlerInfo{'Author_Email'}             = '$email';
\$handlerInfo{'Maintainer_Name'}          = '$author';
\$handlerInfo{'Maintainer_Email'}         = '$email';
\$handlerInfo{'Description'}              = <<'EOF';
${description}EOF
\$handlerInfo{'Category'}                 = '$category';
\$handlerInfo{'URL'}                      = <<'EOF';
$url
EOF
\$handlerInfo{'License'}                  = '$license';
\$handlerInfo{'For_News_Clipper_Version'} = '$COMPATIBLE_NEWS_CLIPPER_VERSION';
\$handlerInfo{'Language'}                 = 'English';
\$handlerInfo{'Notes'}                    = <<'EOF';
${notes}EOF
\$handlerInfo{'Syntax'}                   = <<'EOF';
${syntax}EOF
  EOF

  $code =~ s/\n(#\s*AUTH.*?)\npackage /\n\npackage /s;

  my $use_vars;
  $code =~ s/\b(use vars[^\n]+)\n/$use_vars = $1;''/es;
  $use_vars =~ s/ *\);/ %handlerInfo );/;

  $code =~ s/\n+(package [^\n]+\n)/\n\n$1\n$use_vars\n\n$newMetaInfo/s;

  return $code;
}

#-------------------------------------------------------------------------------

sub GetCategory($)
{
  my $handler = shift;

  print "- Getting handler category\n";

  use LWP::Simple;

  my $info = get("http://$handlerserver/cgi-bin/getinfo?field=Name\&string=$handler\&print=Category");

  if ($info =~ /Category *: (.+)\n/)
  {
    return $1;
  }
  else
  {
    print<<'    EOF';
  - Couldn't locate handler in the database. Please choose a category:
    1) News Clipper
    2) General
    3) Tech
    4) Business
    5) Sports
    6) Science
    7) Weather
    8) Music
    9) Local
    10) Humor
    11) Comics
    12) Linux
    13) Programming
    14) Personal Computers
    15) Miscellaneous
    EOF

    my $choice;
    $choice = <STDIN> until $choice =~ /\d+/s && $choice < 16 && $choice > 0;

    return "News Clipper" if $choice == 1;
    return "General" if $choice == 2;
    return "Tech" if $choice == 3;
    return "Business" if $choice == 4;
    return "Sports" if $choice == 5;
    return "Science" if $choice == 6;
    return "Weather" if $choice == 7;
    return "Music" if $choice == 8;
    return "Local" if $choice == 9;
    return "Humor" if $choice == 10;
    return "Comics" if $choice == 11;
    return "Linux" if $choice == 12;
    return "Programming" if $choice == 13;
    return "Personal Computers" if $choice == 14;
    return "Miscellaneous" if $choice == 15;
  }
}

#-------------------------------------------------------------------------------

sub ConvertVersion($)
{
  my $code = shift;

  print "- Converting Version Number\n";

  my $commentBlock = <<'  EOF';
# - The first number should be incremented when a change is made to the
#   handler that will break people's input files.
# - The second number should be incremented when a change is made that won't
#   break people's input files, but changes the functionality.
# - The third number should be incremented when only a bugfix is applied.
  EOF

  $code =~ s|\n\$VERSION\s*=\s+((?!do).*?);|
$commentBlock
\$VERSION = do {my \@r=('$1.0'=~/\\d+/g);sprintf "\%d."."\%02d"x\$#r,\@r};|sx;

  return $code;
}

#-------------------------------------------------------------------------------

sub StripUses($)
{
  my $code = shift;

  print "- Removing Extra \"use\" Statements\n";

  $code =~ s/use NewsClipper::Types.*?;\n\n?//s;
  $code =~ s/use NewsClipper::HTMLTools.*?;\n\n?//s;
  $code =~ s/use NewsClipper::AcquisitionFunctions.*?;\n\n?//s;
  $code =~ s/use constant DEBUG.*?;\n\n?//s;
  $code =~ s/# DEBUG for this package is the same as the main.\n\n?//s;

  return $code;
}

#-------------------------------------------------------------------------------

sub StripDprint($)
{
  my $code = shift;

  print "- Removing dprint declaration\n";

  $code =~ s/\n*sub dprint;\n*/\n/s;
  $code =~ s/\n*\*dprint.*?;\n*/\n/s;

  return $code;
}

#-------------------------------------------------------------------------------

sub ConvertDefaultHandlers($)
{
  my $code = shift;

  print "- Converting Default Handlers\n";

  if ($code =~ /(sub GetDefaultHandlers\s*{.*?\n}\n)/s)
  {
    my $subCode = $1;
    my $storedSubCode = $subCode;
 
    $subCode =~ s/\n( *)my \@returnVal\s*=\s*\(/\n$1my \@returnVal =<<'$1EOF';/sg;
    $subCode =~ s/(my \@returnVal[^\n]+EOF';.*?)\);/$1EOF/sg;
    $subCode =~ s/my \@returnVal/my \$returnVal/sg;
 
    $subCode =~ s/\n( *)\@returnVal\s*=\s*\(/\n$1\@returnVal =<<'$1EOF';/sg;
    $subCode =~ s/(\@returnVal[^\n]+EOF';.*?)\);/$1EOF/sg;
    $subCode =~ s/\@returnVal/\$returnVal/sg;

    while ($subCode =~ /\n((\s*{'name'.*?},?\n)+)/s)
    {
      my $match = $1;
      my $storedMatch = $match;
      my ($prefix) = $match =~ /^(\s*)/;
      
      $match =~ s/,\s*'(\w+)'\s*=>\s*/ $1=/sg;
      $match =~ s/'(\w+)'\s*=>\s*/$1=/sg;
      $match =~ s/{\s*name/name/sg;
      $match =~ s/},? *\n/\n/sg;
#      $match =~ s/, *'/ /sg;
      $match =~ s/(^|\n)(\s*)(name)/$1$2<filter $3/sg;
      $match =~ s/(\S)(\n\s*<filter|$)/$1>$2/sg;
      $match =~ s/^(.*)<filter /$1<output /s;

      $subCode =~ s/\Q$storedMatch\E/$match/s;
    }

    $code =~ s/\Q$storedSubCode\E/$subCode/s;
  }
  else
  {
    print <<"    EOF"
GetDefaultHandlers subroutine could not be found. Skipping default handler
conversion...
    EOF
      and return $code;
  }

  return $code;
}

#-------------------------------------------------------------------------------

sub ConvertOldPatternMatches($)
{
  my $code = shift;

  print "- Converting old pattern matches to use references.\n";

  $code =~ s/(grep *{\s*)!\//$1\$\$_ !~ \//gs;
  $code =~ s/(grep *{\s*)\//$1\$\$_ =~ \//gs;

  return $code;
}

#-------------------------------------------------------------------------------

sub CheckGetFunction($)
{
  my $code = shift;

  print "- Checking Get Function\n";

  if ($code =~ /MakeSubtype/s)
  {
    print <<'    EOF';
This handler's Get function calls "MakeSubType", which means that you need to
edit the Get function to reflect the new type system. Instead of doing
something like this:

  while ($line =~ /(.*)::(.*)/g)
  {
    push @data, {'name' => $1,'url' => $2};
  }
  MakeSubType('ArrayOfSlashdotHash','ArrayOfHash');
  bless \@data,'ArrayOfSlashdotHash';

you now bless the new data type, and let News Clipper worry about the
structure of the rest of the data:

  MakeSubType('Slashdot','HASH');

  while ($line =~ /(.*)::(.*)/g)
  {
    my %hash = ('name' => $1,'url' => $2);
    bless \%hash,'Slashdot';
    push @data, \%hash;
  }

    EOF
  }
}

#-------------------------------------------------------------------------------

sub CheckErrorMessage($)
{
  my $code = shift;

  print "- Checking use of error messages\n";

  if ($code =~ /\bprint\b/s)
  {
    print <<'    EOF';
This handler calls "print", which means that you need to edit the handler to
use the new error (for errors) or dprint (for debugging) functions instead.
You don't have to check the input types, since News Clipper will check them
for you based on the FilterType and OutputType specifications.

If this is an output handler, be sure to edit your code to deal with
references to scalars instead of scalars. i.e.:

  print $grabbedData->[0];

becomes

  print ${$grabbedData->[0]};

since everything is a reference now.
    EOF
  }
}

#-------------------------------------------------------------------------------

sub CheckRef($)
{
  my $code = shift;

  print "- Checking use of ref\n";

  if ($code =~ /[^\$\%\@]\bref\b/s)
  {
    print <<'    EOF';
This handler calls "ref", which means that you might need to edit the handler.
You can be guaranteed that every item passed into any handler function, and
every item inside data structures is a reference. Conversely, you need to
dereference every reference to a scalar, which you didn't have to do before.
    EOF
  }
}

#-------------------------------------------------------------------------------

sub CheckIsa($)
{
  my $code = shift;

  print "- Checking use of isa\n";

  if ($code =~ /\bisa\b/s)
  {
    print <<'    EOF';
This handler calls "isa", which means that you need to edit the handler to
use the new TypesMatch function instead. For example, instead of doing this:

  if (ref $grabbedData && $grabbedData->isa('HASH'))

do this:

  if (TypesMatch($grabbedData,'%'))
    EOF
  }
}

#-------------------------------------------------------------------------------

sub ConvertFilterTypeFunction($)
{
  my $code = shift;

  print "- Converting FilterType Function\n";

  if ($code =~ /(sub FilterType\s*{\n(.*?return ["'].*?["'];\n)}\n)/s)
  {
    my $subCode = $1;
    my $storedSubCode = $subCode;
    my $body = $2;
    my $storedBody = $2;
 
    $body =~ s/"/'/sg;
    $body =~ s/of([A-Z][a-z]*)/\($1\)/sgi;
    $body =~ s/Array/\@/sg;
    $body =~ s/String/\$/sg;
    $body =~ s/Image/\$Image/sg;
    $body =~ s/Link/\$Link/sg;
    $body =~ s/Table/\@(\@(\$))/sg;
    $body =~ s/Thread/\@(\@(\$\|\@))/sg;
    $body =~ s/Hash/\%/sg;
    $body =~ s/([a-z]+)([\@\$\%])/$2$1/sgi;
    $body =~ s/,/ \| /sg;

    my $preamble =<<'    EOF';
  my $self = shift;
  my $attributes = shift;
  my $grabbedData = shift;

    EOF
    $subCode =~ s/\Q$storedBody\E/$preamble$body/s;

    $code =~ s/\Q$storedSubCode\E/$subCode/s;
  }

  return $code;
}

#-------------------------------------------------------------------------------

sub ConvertOutputTypeFunction($)
{
  my $code = shift;

  print "- Converting OutputType Function\n";

  if ($code =~ /(sub OutputType\s*{\n(.*?return ["'].*?["'];\n)}\n)/s)
  {
    my $subCode = $1;
    my $storedSubCode = $subCode;
    my $body = $2;
    my $storedBody = $2;
 
    $body =~ s/"/'/sg;
    $body =~ s/^(.*)[Oo]f([A-Z][^'"]*)/$1\($2\)/sg
      while $body =~ /[Oo]f[A-Z]/;
    $body =~ s/Array/\@/sg;
    $body =~ s/String/\$/sg;
    $body =~ s/Image/\$Image/sg;
    $body =~ s/Link/\$Link/sg;
    $body =~ s/Table/\@(\@(\$))/sg;
    $body =~ s/Thread/\@(\@(\$\ & \@))/sg;
    $body =~ s/Hash/\%/sg;
    $body =~ s/([a-z]+)([\@\$\%])/$2$1/sgi;
    $body =~ s/,/ \| /sg;

    my $preamble =<<'    EOF';
  my $self = shift;
  my $attributes = shift;
  my $grabbedData = shift;

    EOF

    $subCode =~ s/\Q$storedBody\E/$preamble$body/s;

    $code =~ s/\Q$storedSubCode\E/$subCode/s;
  }

  return $code;
}

#-------------------------------------------------------------------------------

sub ConvertTypeNames()
{
  my $code = shift;

  print "- Converting Array to ARRAY, Hash to HASH, and String to SCALAR.\n";

  $code =~ s/\bString\b/SCALAR/sg;
  $code =~ s/\bHash\b/HASH/sg;
  $code =~ s/\bArray\b/ARRAY/sg;

  return $code;
}

#-------------------------------------------------------------------------------


sub CheckLeftOvers($)
{
  my $code = shift;

  print "- Doing final check.\n";

  print<<"  EOF"
Your handler uses "bless". You can remove it if you're blessing something as a
String, Hash, Array, ArrayOfString, or HashOfString. Also, instead of blessing
the returned data as something like "ArrayOfSlashdotHash", bless each hash
reference as "Slashdot" as you put them in the array, and delare Slashdot to
be a subtype of HASH by calling MakeSubtype('Slashdot','HASH')
  EOF
    if $code =~ /\bbless\b/;

  if ($code =~ /\b((Array|Hash)Of\w+)\b/)
  {
    print<<"    EOF";

Your handler uses "$1"
You need to fix this for the new type system. If your data structure is
something like "HashOfSlashdot", you can just change this to "Slashdot". If
it's a complex structure like "ArrayOfHashOfSlashdot", just bless the hash
references as "Slashdot" as you insert them into the array.
    EOF
  }

  print<<'  EOF'
Your handler appears to use HandlerFactory to call another handler. While this
will work, you should replace it with the new RunHandler technique in order
to take advantage of type checking and other features. For example, replace:

  # Put together some attributes to use when calling the cacheimages handler
  my $newAttributes = { 'maxage' => 15 * 60 * 60 };

  my $handlerFactory = new NewsClipper::HandlerFactory;

  # Ask the HandlerFactory to create a handler for us, based on the name.
  my $handler = $handlerFactory->Create('cacheimages');

  my $cachedimage = $handler->Filter($newAttributes,$links[0]);

with:

  # Put together some attributes to use when calling the cacheimages handler
  my $newAttributes = { 'maxage' => 15 * 60 * 60 };

  my $cachedimage = RunHandler('cacheimages','filter',$links[0],$newAttributes);
  EOF
    if $code =~ /handlerFactory->Create/;

  return $code;
}

#-------------------------------------------------------------------------------

sub WriteHandler($$)
{
  my $handler = shift;
  my $code = shift;

  my $backup = $handler;
  $backup =~ s/.pm$/.bak/i;

  print "\"$backup\" already exists. Handler NOT saved.\n" and return
    if -e $backup;
  rename $handler,$backup or
    warn "Couldn't not rename $handler\n  to $backup. Skipping...\n"
      and return;
  open NEW, ">$handler" or die "Can't open $handler for writing: $!\n";
  print NEW $code;
  close NEW;

  print<<"  EOF";
- Handler $handler
has been converted and saved. Check it to make sure everything look reasonable.
(The old handler was renamed to $backup.)
  EOF
}

#-------------------------------------------------------------------------------

sub AddComputeURL($)
{
  my $code = shift;

  return $code unless $code =~ /Handler::Acquisition/;

  print "- Adding ComputeURL Function\n";

  if ($code =~ /(# *-{70,}[^-]+(?:# This fun[^\n]+\n)?sub Get\s*{.*?\n}\n)/s)
  {
    my $subCode = $1;
    my $storedSubCode = $subCode;

    my $addedCode =<<'    EOF';
# ------------------------------------------------------------------------------

sub ComputeURL
{
  my $self = shift;
  my $attributes = shift;

  my $url = 'INSERT URL HERE';

  return $url;
}

    EOF

    if ($subCode =~ /my \$url = (['"][^'"]+['"])\s*;/s)
    {
      my $url = $1;
      $subCode =~ s/my\s+\$url\s*=\s*.*?;/my \$url = \$self->ComputeURL(\$attributes);/s;
      $addedCode =~ s/'INSERT URL HERE'/$url/s;
    }
    elsif ($subCode =~ /( *)my \$data = [^\(]+Get[^\(]+\((['"][^'"]+['"])/s)
    {
      my $whitespace = $1;
      my $url = $2;
      my $new_line = "my \$url = \$self->ComputeURL(\$attributes);\n\n$whitespace";
      $subCode =~ s/(my \$data = [^\(]+Get[^\(]+\()['"][^'"]+['"]/$new_line$1\$url/s;
      $addedCode =~ s/'INSERT URL HERE'/$url/s;
    }
    else
    {
      print <<'      EOF';
A Get subroutine was found, but your URL code was too complicated to convert
automatically. Move any URL calculation code to ComputeURL, and have your Get
subroutine call it like this:

  my $url = $self->ComputeURL($attributes);
      EOF
    }

    $code =~ s/\Q$storedSubCode\E/$addedCode$subCode/s;
  }
  else
  {
    print <<"    EOF"
Get subroutine could not be found. Skipping addition of ComputeURL
subroutine...
    EOF
      and return $code;
  }

  return $code;
}

#-------------------------------------------------------------------------------

sub AddSetDefaultAttributes($)
{
  my $code = shift;

  return $code unless $code =~ /Handler::Acquisition/;

  print "- Adding SetDefaultAttributes Function\n";

  if ($code =~ /(# *-{70,}[^-]+(?:# This fun[^\n]+\n)?sub Get\s*{.*?\n}\n)/s)
  {
    my $subCode = $1;
    my $storedSubCode = $subCode;

    my $addedCode =<<'    EOF';
# ------------------------------------------------------------------------------

# This subroutine checks the handler's attributes to make sure they are valid,
# and sets any default attributes if necessary.

sub ProcessAttributes
{
  my $self = shift;
  my $attributes = shift;
  my $handlerRole = shift;

  # Set defaults here. You can safely delete this function if your handler has
  # no attributes with default values.

  # $attributes->{'some_attribute'} = 'default_value'
  #   unless defined $attributes->{'some_attribute'};

  # Verify any attributes you need to here. Output an error and return undef
  # if something is wrong.

  # unless ($attributes->{somevalue} > 0)
  # {
  #   error "The \"somevalue\" attribute for handler \"HANDLERNAME\" " .
  #     "should be greater than 0.\n";
  #   return undef;
  # }

  return $attributes;
}

    EOF

    while ($subCode =~
      /\n( *\$attributes->{[^}]+}\s=\s[^;]+\sif !defined[^;]+\$attributes[^;]+;\n)/s)
    {
      my $setdefault = $1;
      $subCode =~ s/\s+\Q$setdefault\E/\n/s;
      $addedCode =~ s/\n(\s+return \$attributes)/\n$setdefault$1/s;
    }

    while ($subCode =~
      /\n( *\$attributes->{[^}]+}\s=\s[^;]+\sunless\sdefined[^;]+\$attributes[^;]+;\n)/s)
    {
      my $setdefault = $1;
      $subCode =~ s/\s+\Q$setdefault\E/\n/s;
      $addedCode =~ s/\n(\s+return \$attributes)/\n$setdefault$1/s;
    }

    $code =~ s/\Q$storedSubCode\E/$addedCode$subCode/s;
  }
  else
  {
    print <<"    EOF"
Get subroutine could not be found. Skipping addition of SetDefaultAttributes
subroutine...
    EOF
      and return $code;
  }

  return $code;
}

#-------------------------------------------------------------------------------

sub dequote
{
  my $prefix;
  $prefix = shift if $#_ == 1;

  local $_ = shift;

  my ($white, $leader);

  if (/^\s*(?:([^\w\s]+)(\s*).*\n)(?:\s*\1\2?.*\n)+$/)
  {
    ($white, $leader) = ($2, quotemeta($1));
  }
  else
  {
    ($white, $leader) = (/^(\s+)/,'');
  }

  s/^\n/$white\n/gm;
  s/^\s*?$leader(?:$white)?//gm;

  # Put the prefix on if one was specified
  $_ =~ s/^/$prefix/gm if $prefix;

  return $_;
}
