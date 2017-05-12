# See copyright, etc in below POD section.
######################################################################

package SVN::S4::Config;
require 5.006_001;

use SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

use strict;
use Carp;
use Config::Tiny;
use vars qw($AUTOLOAD);

our $VERSION = '1.064';

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

sub _config_filenames {
    # Files where config may live
    our @out;
    push @out, "/etc/subversion/config";
    push @out, $ENV{S4_CONFIG_SITE} if $ENV{S4_CONFIG_SITE};
    push @out, "$ENV{HOME}/.subversion/config" if $ENV{HOME};
    push @out, $ENV{S4_CONFIG} if $ENV{S4_CONFIG};
    return @out;
}

sub _config_read {
    my $self = shift;
    return if $self->{_config};

    $self->{_config} ||= {};
    foreach my $filename ($self->_config_filenames) {
	DEBUG "s4: _config_read $filename\n" if $self->debug;
	if (-e $filename) {
	    my $cfg = Config::Tiny->read($filename);
	    foreach my $sec (keys %$cfg) {
		foreach my $key (keys %{$cfg->{$sec}}) {
		    $self->{_config}{$sec}{$key} = $cfg->{$sec}{$key};
		}
	    }
	}
	#print Dumper($self->{_config});
    }
}

sub config_get {
    my $self = shift;
    my $sec = shift;
    my $key = shift;
    $self->_config_read;
    my $val = $self->{_config}{$sec}{$key};
    return $val;
}

sub config_get_bool {
    my $self = shift;
    my $val = $self->config_get(@_);
    return undef if !defined $val;
    return 1 if ($val && $val !~ /^no$/i);
    return 0;
}

sub config_glob_to_regexp {
    my $self = shift;
    my $glob = shift;
    my $re = '(';
    foreach my $ch (split //, $glob) {
	if ($ch eq ' ') {
	    $re .= '|' unless $re =~ /[|]$/;
	} elsif ($ch eq '*') {
	    $re .= '.*';
	} elsif ($ch =~ /[a-z0-9A-Z?]/) {
	    $re .= $ch;
	} else {
	    $re .= "\\".$ch;
	}
    }
    $re .= ')$';
}

######################################################################
### Package return
package SVN::S4::Config;
1;
__END__

=pod

=head1 NAME

SVN::S4::Config - Get subversion config values

=head1 SYNOPSIS

Scripts:
  use SVN::S4;
  # See below

=head1 DESCRIPTION

SVN::S4::Config reads the user .subversion config files.

=head1 METHODS ADDED TO SVN::S4

The following methods extend to the global SVN::S4 class.

=over 4

=item $s4->config_get(<section>,<key>)

Return the config value for the given section and key.

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
