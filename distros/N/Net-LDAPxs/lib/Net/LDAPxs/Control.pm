#
# Copyright (c) 2008-2009 Pan Yu (xiaocong@vip.163.com). 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package Net::LDAPxs::Control;

use 5.006;
use strict;
use vars qw($VERSION);
use vars qw( $DEFAULT_CONTROL_CRITICAL
			 $LDAP_CONTROL_SORTREQUEST
		);

$VERSION = '1.00';

$DEFAULT_CONTROL_CRITICAL = 0;
$LDAP_CONTROL_SORTREQUEST = '1.2.840.113556.1.4.473';

my $error = {
		'die'	=> sub { require Carp; Carp::croak(@_); },
		'warn'	=> sub { require Carp; Carp::carp(@_); }
};

my %controls = (
		$LDAP_CONTROL_SORTREQUEST => 1
);

sub _error {
	my $error_code = shift;
	my $error_msg = shift;

	$error->{$error_code}($error_msg);
}

sub _check_options {
	my $arg_ref = shift;

	if (grep { /^-/ } keys %$arg_ref) {
		_error('die', "Leading - for options is NOT supported");
	}
	if (exists $arg_ref->{'type'}) {
		if (exists $controls{$arg_ref->{type}}) {
			$arg_ref->{'type'} = $controls{$arg_ref->{type}};
		}else{
			_error('die', "The control type $arg_ref->{type} is currently not supported");	
		}
	}else{
		_error('die', "Control type option is required");
	}
	if (!exists $arg_ref->{'value'}) {
		_error('die', "Control value option is required");
	}
	$arg_ref->{'critical'} = $arg_ref->{'critical'} || $DEFAULT_CONTROL_CRITICAL;
}

sub new {
	my $class = shift;
	my $type = ref($class) || $class;
	my $arg_ref = { @_ };

	_check_options($arg_ref);

	$arg_ref;
}


1;

__END__


=head1 NAME

Net::LDAPxs::Control - LDAPv3 control extension

=head1 SYNOPSIS

  use Net::LDAPxs::Control;

  $ctrl = Net::LDAPxs::Control->new(
          type  => '1.2.840.113556.1.4.473',
          value => 'sn -cn',
          critical => 0
          );

  $msg = $ldap->search( base    => $base,
                        control => $ctrl );
  
=head1 DESCRIPTION

The C<Net::LDAPxs::Control> is for LDAPv3 control extension.

=head1 CONSTRUCTORS

=over 4

=item new ( ARGS )

ARGS is a list of name/value pairs, valid arguments are:

=item type

A dotted-decimal representation of an OBJECT IDENTIFIER which
uniquely identifies the control. This prevents conflicts between
control names.

=item value

Optional information associated with the control. It's format is specific
to the particular control.

=item critical

A boolean value, if TRUE and the control is unrecognized by the server or
is inappropriate for the requested operation then the server will return
an error and the operation will not be performed.

If FALSE and the control is unrecognized by the server or
is inappropriate for the requested operation then the server will ignore
the control and perform the requested operation as if the control was
not given.

If absent, FALSE is assumed.

=back

=head1 ACKNOWLEDGEMENTS

This document is based on the document of L<Net::LDAP::Control>

=head1 AUTHOR

Pan Yu <xiaocong@vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
