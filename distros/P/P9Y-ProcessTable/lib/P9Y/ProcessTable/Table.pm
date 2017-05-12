package P9Y::ProcessTable::Table;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.08'; # VERSION

#############################################################################
# Modules

use strict;
use warnings;

use Module::Runtime ();
use Path::Class ();

use Moo;

# Figure out which OS role we should consume
my %OS_TRANSLATE = (
   cygwin => 'MSWin32',
);

my $role_base = 'P9Y::ProcessTable::Role::Table::';
my $role      = 'OS::'.($OS_TRANSLATE{$^O} || $^O);

$@ = '';
my $has_os_role = eval { Module::Runtime::require_module($role_base.$role) };
die $@ if $@ and $@ !~ /^Can't locate /;

unless ($has_os_role) {
   # let's hope they have /proc
   if ( -d '/proc' and @{[ glob('/proc/*') ]} ) { $role = 'ProcFS'; }
   # ...or that Proc::ProcessTable can handle it
   else                                         { $role = 'PPT'; }
}

# This here first, so that it gets overloaded
extends 'P9Y::ProcessTable::Table::Base';

with $role_base.$role;

use P9Y::ProcessTable::Process;

42;
