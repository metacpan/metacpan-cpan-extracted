# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Logger;
use strict;
use warnings;

use SVK::Version;  our $VERSION = $SVK::VERSION;

if (eval {
        require Log::Log4perl;
        Log::Log4perl->import(':levels');
        1;
    } ) {
    my $level = lc($ENV{SVKLOGLEVEL} || "info");
    $level = { map { $_ => uc $_ } qw( debug info warn error fatal ) }
        ->{ $level } || 'INFO';

    my $conf_file = $ENV{SVKLOGCONFFILE};
    my $conf;
    if ( defined($conf_file) and -e $conf_file ) {
	my $fh;
	open $fh, $conf_file or die $!;
	local $/;
	$conf = <$fh>;
	close $fh;
    }
    #warn $conf unless $Log::Log4perl::Logger::INITIALIZED;
    $conf ||= qq{
  log4perl.rootLogger=$level, Screen
  log4perl.appender.Screen = Log::Log4perl::Appender::Screen
  log4perl.appender.Screen.stderr = 0
  log4perl.appender.Screen.layout = PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = %m%n
  };

    # ... passed as a reference to init()
    Log::Log4perl::init( \$conf ) unless Log::Log4perl->initialized;
    *get_logger = sub { Log::Log4perl->get_logger(@_) };
}
else {
    *get_logger = sub { 'SVK::Logger::Compat' };
}

sub import {
  my $class = shift;
  my $var = shift || 'logger';
  
  # it's ok if people add a sigil; we can get rid of that.
  $var =~ s/^\$*//;
  
  # Find out which package we'll export into.
  my $caller = caller() . '';

  (my $name = $caller) =~ s/::/./g;
  my $logger = get_logger(lc($name));
  {
    # As long as we don't use a package variable, each module we export
    # into will get their own object. Also, this allows us to decide on 
    # the exported variable name. Hope it isn't too bad form...
    no strict 'refs';
    *{ $caller . "::$var" } = \$logger;
  }
}

package SVK::Logger::Compat;
require Carp;

my $current_level;
my $level;

BEGIN {
my $i;
$level = { map { $_ => ++$i } reverse qw( debug info warn error fatal ) };
$current_level = $level->{lc($ENV{SVKLOGLEVEL} || "info")} || $level->{info};

my $ignore  = sub { return };
my $warn = sub {
    shift;
    my $s = join "", @_;
    chomp $s;
    print "$s\n";
};
my $die     = sub { shift; die $_[0]."\n"; };
my $carp    = sub { shift; goto \&Carp::carp };
my $confess = sub { shift; goto \&Carp::confess };
my $croak   = sub { shift; goto \&Carp::croak };

*debug      = $current_level >= $level->{debug} ? $warn : $ignore;
*info       = $current_level >= $level->{info}  ? $warn : $ignore;
*warn       = $current_level >= $level->{warn}  ? $warn : $ignore;
*error      = $current_level >= $level->{warn}  ? $warn : $ignore;
*fatal      = $die;
*logconfess = $confess;
*logdie     = $die;
*logcarp    = $carp;
*logcroak   = $croak;

}

sub is_debug { $current_level >= $level->{debug} }

1;

__END__

=head1 NAME

SVK::Logger - logging framework for SVK

=head1 SYNOPSIS

  use SVK::Logger;
  
  $logger->warn('foo');
  $logger->info('bar');
  
or 

  use SVK::Logger '$foo';
  
  $foo->error('bad thingimajig');

=head2 DESCRIPTION

SVK::Logger is a wrapper around Log::Log4perl. When using the module, it
imports into your namespace a variable called $logger (or you can pass a
variable name to import to decide what the variable should be) with a
category based on the name of the calling module.

=head1 MOTIVATION

Ideally, for support requests, if something is not going the way it
should be we should be able to tell people: "rerun the command with the
SVKLOGLEVEL environment variable set to DEBUG and mail the output to
$SUPPORTADDRESS". On Unix, this could be accomplished in one command like so:

  env SVKLOGLEVEL=DEBUG svk <command that failed> 2>&1 | mail $SUPPORTADDRESS

