# See copyright, etc in below POD section.
######################################################################

package SVN::S4::WorkProp;
require 5.006_001;

use strict;
use Carp;
use Config::Tiny;
use Cwd qw(getcwd);
use vars qw($AUTOLOAD);

use SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

our $VERSION = '1.064';

# Legal characters in keys/values.
# Overly strict; INI format doesn't allow []; or whitespace
our $_Prop_Regexp = qr/^[---+a-zA-Z0-9_.,\/]+$/;

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

sub _workprop_read {
    my $self = shift;
    return if $self->{_workcfg};
    if (!$self->{_workcfg_filename}) {
	my $dir = Cwd::getcwd();
	if (!$self->dir_uses_svn($dir)) {
	    die "s4: %Error: s4 workprop*: Not currently inside a work area\n";
	}
	$dir = $self->dir_top_svn($dir);
	$self->{_workcfg_filename} = "$dir/.svn/workprops";
    }

    DEBUG "s4: _workprop_read $self->{_workcfg_filename}\n" if $self->debug;
    if (-e $self->{_workcfg_filename}) {
	$self->{_workcfg} = Config::Tiny->read($self->{_workcfg_filename});
    } elsif (!$self->{_workcfg}) {
	$self->{_workcfg} = Config::Tiny->new;
    }
    $self->{_workcfg}{workprops} ||= {};
}

sub _workprop_write {
    my $self = shift;
    $self->{_workcfg_filename} or die "s4: Internal-%Error: never _workprop_read";
    DEBUG "s4: _workprop_write $self->{_workcfg_filename}\n" if $self->debug;
    $self->{_workcfg}->write($self->{_workcfg_filename});
    die $self->{_workcfg}->errstr,"\n" if $self->{_workcfg}->errstr;
}

sub workpropdel {
    my $self = shift;
    my %params = (propname=>undef,
		  @_);
    $self->_workprop_read;
    delete $self->{_workcfg}{workprops}{$params{propname}};
    $self->_workprop_write;
}

sub workpropset {
    my $self = shift;
    my %params = (propname=>undef,
		  value=>undef,
		  @_);
    $params{propname} =~ /$_Prop_Regexp/
	or die "s4: %Error: workprop name has illegal characters; non [a-zA-Z0-9_-+,/]: $params{propname}\n";
    $params{value} =~ /$_Prop_Regexp/
	or die "s4: %Error: workprop value has illegal characters; non [a-zA-Z0-9_-+,/]: $params{propname}\n";
    $self->_workprop_read;
    $self->{_workcfg}{workprops}{$params{propname}} = $params{value};
    $self->_workprop_write;
}

sub workpropget {
    my $self = shift;
    my %params = (propname=>undef,
		  xml=>undef,
		  print=>0,
		  @_);
    $self->_workprop_read;
    my $val = $self->{_workcfg}{workprops}{$params{propname}};
    if ($params{print}) {
	if (defined $val) { print "$val\n"; }
    }
    return $val;
}

sub workproplist {
    my $self = shift;
    my %params = (#verbose=>1,   # Always verbose, for now
		  xml=>undef,
		  @_);
    $self->_workprop_read;
    if ($params{print}) {
	if ($params{xml}) {
	    print "<?xml version \"1.0\"?>\n";
	    print "<workprops>\n";
	} else {
	    print "Work Properties:\n";
	}
	foreach my $key (sort keys %{$self->{_workcfg}{workprops}}) {
	    my $val = $self->{_workcfg}{workprops}{$key};
	    if ($params{xml}) {
		print "<workprop name=\"$key\">\n";
		if (defined $val) { print "$val\n"; }
		print "</workprop>\n";
	    } else {
		print "  $key\n";
		if (defined $val) { print "    $val\n"; }
		else { print "\n"; }
	    }
	}
	if ($params{xml}) {
	    print "</workprops>\n";
	}
    }
}

######################################################################
### Package return
package SVN::S4::WorkProp;
1;
__END__

=pod

=head1 NAME

SVN::S4::WorkProp - Work area properties

=head1 SYNOPSIS

Shell:
  s4 workpropdel PROPNAME
  s4 workpropget PROPNAME
  s4 workproplist [-v --xml]
  s4 workpropset PROPNAME PROPVAL

Scripts:
  use SVN::S4;
  # See below

=head1 DESCRIPTION

SVN::S4::WorkProp provides utilities for work area properties.

=head1 METHODS

=over 4

=item workpropdel(name=>I<name>)

Delete the property.

=item workpropget(name=>I<name>, print=>1)

Return or print value of given property.

=item workpropset(name=>I<name>, value=>I<value>)

Set the property.

=item workproplist(verbose=>1, xml=>1)

Return value of given property.

=back

=head1 METHODS ADDED TO SVN::S4

The following methods extend to the global SVN::S4 class.

=over 4

=item $s4->fixprops

Recurse the specified files, searching for .cvsignore, .gitignore or
keywords that need repair.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2005-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut
