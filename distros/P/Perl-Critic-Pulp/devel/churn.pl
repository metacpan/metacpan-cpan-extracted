#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


# Usage: churn.pl [--const] [--not] [--diag] [directories...]
#
# Run the pulp tests over all files under the given directories, or by
# default over /usr/share/perl (core and add-ons).
#
# The options select just one of the policies.
#

use 5.006;
use strict;
use warnings;
use Getopt::Long;

use lib 'lib','devel/lib';

use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

my @option_policies;
my $option_t_files = 0;

GetOptions
  (require_order => 1,
   t => \$option_t_files,
   F => sub {
     push @option_policies, 'Documentation::RequireFilenameMarkup$';
   },
   paracomma => sub {
     push @option_policies, 'Documentation::ProhibitParagraphEndComma$';
   },
   duphead => sub {
     push @option_policies, 'Documentation::ProhibitDuplicateHeadings';
   },
   ifif => sub {
     push @option_policies, 'CodeLayout::ProhibitIfIfSameLine';
   },
   duphashkeys => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitDuplicateHashKeys';
   },
   linkself => sub {
     push @option_policies, 'Documentation::ProhibitLinkSelf$';
   },
   unbal => sub {
     push @option_policies, 'Documentation::inprogressProhibitUnbalancedParens';
   },
   aref => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitArrayAssignAref';
   },
   const => sub {
     push @option_policies, 'ValuesAndExpressions::ConstantBeforeLt';
   },
   not => sub {
     push @option_policies, 'ValuesAndExpressions::NotWithCompare';
   },
   null => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitNullStatements';
   },
   literals => sub {
     push @option_policies, 'ValuesAndExpressions::UnexpandedSpecialLiteral';
   },
   commas => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitEmptyCommas';
   },
   lastpod => sub {
     push @option_policies, 'Documentation::RequireEndBeforeLastPod';
   },
   consthash => sub {
     push @option_policies, 'Compatibility::ConstantPragmaHash';
   },
   gtk2 => sub {
     push @option_policies, 'Modules::Gtk2Version';
   },
   podmin => sub {
     push @option_policies, 'Compatibility::PodMinimumVersion';
   },
   posix => sub {
     push @option_policies, 'Modules::ProhibitPOSIXimport';
   },
   usever => sub {
     push @option_policies, 'Modules::ProhibitUseQuotedVersion';
   },
   apropos => sub {
     push @option_policies, 'Documentation::ProhibitBadAproposMarkup';
   },
   backslash => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitUnknownBackslash';
   },
   semicolon => sub {
     push @option_policies, 'CodeLayout::RequireFinalSemicolon';
   },
   verb => sub {
     push @option_policies, 'Documentation::ProhibitVerbatimMarkup$';
   },
   shebang => sub {
     push @option_policies, 'Modules::ProhibitModuleShebang$';
   },
   numver => sub {
     push @option_policies, 'ValuesAndExpressions::RequireNumericVersion';
   },

   # coming soon ...
   fatnewline => sub {
     push @option_policies, 'ProhibitFatCommaAfterNewline';
   },
   testprint => sub {
     push @option_policies, 'TestingAndDebugging::ProhibitTestPrint';
   },
   trailing => sub {
     push @option_policies, 'CodeLayout::RequireTrailingCommaAtNewline';
   },
  );

my @files;
if ($option_t_files) {
  require File::Locate;
  @files = File::Locate::locate ('*.t', '/var/cache/locate/locatedb');
} else {
  my @dirs = @ARGV;
  if (! @dirs) {
    @dirs = (
             '/usr/share/perl5',
             '/usr/bin',
             '/bin',
             glob('/usr/share/perl/*.*.*'),
            );
  }
  print "Directories:\n";
  foreach (@dirs) {
    print "  ",$_,"\n";
  }
  @files = map { -d $_ ? Perl::Critic::Utils::all_perl_files($_) : $_ } @dirs;
}

@files = uniq_by_func (\&stat_dev_ino, @files);
print "Files: ",scalar(@files),"\n";

# @list = uniq_by_func ($func, @list)
sub uniq_by_func {
  my $func = shift;
  my %seen;
  return grep { my $key = $func->($_);
                defined $key && $seen{$key}++ == 0
              } @_;
}
sub stat_dev_ino {
  my ($filename) = @_;
  my ($dev, $ino) = stat ($filename);
  return if ! defined $dev;
  return "$dev,$ino";
}


my $critic;
if (@option_policies) {
  $critic = Perl::Critic->new ('-profile' => '',
                               '-single-policy' => shift @option_policies);
  foreach my $policy (@option_policies) {
    $critic->add_policy (-policy => $policy);
  }
} else {
  $critic = Perl::Critic->new ('-profile' => '',
                               '-theme' => 'pulp');
}
#   $critic->add_policy
#     (-policy => 'ValuesAndExpressions::ProhibitNullStatements',
#      -params => { allow_perl4_semihash => 1 });

print "Policies:\n";
foreach my $p ($critic->policies) {
  print "  ",$p->get_short_name,"\n";
}


# "%f:%l:%c:" is good for emacs compilation-mode
Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n %r\n");

foreach my $file (@files) {
  print "$file\n";
  my @violations;
  if (! eval { @violations = $critic->critique ($file); 1 }) {
    print "Died in \"$file\": $@\n";
    next;
  }
  print @violations;
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$file\": $exception\n";
  }
}

exit 0;
