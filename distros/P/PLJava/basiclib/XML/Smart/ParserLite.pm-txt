#############################################################################
## Name:        ParserLite.pm
## Purpose:     XML::Smart::ParserLite
## Author:      Paul Kulchenko (paulclinger@yahoo.com)
## Modified by: Graciliano M. P.
## Created:     10/05/2003
## RCS-ID:      
## Copyright:   2000-2001 Paul Kulchenko
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
##
## This module is actualy XML::Parser::Lite. It's just here for convenience.
## See original code at CPAN for full source and POD.
##
## This module will be used when XML::Simple is not installed.
#############################################################################

# ======================================================================
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: Lite.pm,v 1.4 2001/10/15 21:25:05 paulk Exp $
#
# ======================================================================

package XML::Smart::ParserLite ;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%s", map {s/_//g; $_} q$Name: release-0_55-public $ =~ /-(\d+)_([\d_]+)/);

sub new { 
  my $self = shift;
  my $class = ref($self) || $self;
  return $self if ref $self;

  $self = bless {} => $class;
  my %parameters = @_;
  $self->setHandlers(); # clear first 
  $self->setHandlers(%{$parameters{Handlers} || {}});
  return $self;
}

sub setHandlers {
  my $self = shift; 
  no strict 'refs'; local $^W;
  unless (@_) { foreach (qw(Start End Char Final Init)) { *$_ = sub {} } }
  while (@_) { my($name => $func) = splice(@_, 0, 2); *$name = defined $func ? $func : sub {} }
  return $self;
}

sub regexp {
  my $patch = shift || '';
  my $package = __PACKAGE__;

  my $TextSE = "[^<]+";
  my $UntilHyphen = "[^-]*-";
  my $Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
  my $CommentCE = "$Until2Hyphens>?";
  my $UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
  my $CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
  my $S = "[ \\n\\t\\r]+";
  my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
  my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
  my $Name = "(?:$NameStrt)(?:$NameChar)*";
  my $QuoteSE = "\"[^\"]*\"|'[^']*'";
  my $DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
  my $MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
  my $S1 = "[\\n\\r\\t ]";
  my $UntilQMs = "[^?]*\\?+";
  my $PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
  my $DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
  my $DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
  my $DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
  my $PI_CE = "$Name(?:$PI_Tail)?";

  my $EndTagCE = "($Name)(?{${package}::end(\$2)})(?:$S)?>";
  my $AttValSE = "\"([^<\"]*)\"|'([^<']*)'";
  my $ElemTagCE = "($Name)(?:$S($Name)(?:$S)?=(?:$S)?(?:$AttValSE)(?{[\@{\$^R||[]},\$4=>defined\$5?\$5:\$6]}))*(?:$S)?(/)?>(?{${package}::start(\$3,\@{\$^R||[]})})(?{\${7} and ${package}::end(\$3)})";
  my $MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|/(?:$EndTagCE)?|(?:$ElemTagCE)?)";

  "(?:($TextSE)(?{${package}::char(\$1)}))$patch|$MarkupSPE";
}

sub compile { local $^W; 
  foreach (regexp(), regexp('??')) {
    eval qq{sub parse_re { use re "eval"; 1 while \$_[0] =~ m{$_}go }; 1} or die;
    last if eval { parse_re('<foo>bar</foo>'); 1 }
  };

  *compile = sub {};
}

setHandlers();
compile();

sub parse { 
  init(); 
  parse_re($_[1]);
  final(); 
}

my(@stack, $level);

sub init { 
  @stack = (); $level = 0;
  Init(__PACKAGE__, @_);  
}

sub final { 
  die "not properly closed tag '$stack[-1]'\n" if @stack;
  die "no element found\n" unless $level;
  Final(__PACKAGE__, @_) 
} 

sub start { 
  die "multiple roots, wrong element '$_[0]'\n" if $level++ && !@stack;
  push(@stack, $_[0]);
  Start(__PACKAGE__, @_); 
}

sub char { 
  Char(__PACKAGE__, $_[0]), return if @stack;

  for (my $i=0; $i < length $_[0]; $i++) {
    die "junk '$_[0]' @{[$level ? 'after' : 'before']} XML element\n"
      if index("\n\r\t ", substr($_[0],$i,1)) < 0; # or should '< $[' be there
  }
}

sub end { 
  pop(@stack) eq $_[0] or die "mismatched tag '$_[0]'\n";
  End(__PACKAGE__, $_[0]);
}

# ======================================================================

1;

