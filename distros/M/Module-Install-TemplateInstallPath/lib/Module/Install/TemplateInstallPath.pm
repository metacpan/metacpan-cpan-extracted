# --8<--8<--8<--8<--
#
# Copyright (C) 2011 Smithsonian Astrophysical Observatory
#
# This file is part of Module::Install::TemplateInstallPath
#
# Module::Install::TemplateInstallPath is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Module::Install::TemplateInstallPath;

use strict;
use warnings;
use Carp;

our $VERSION = '0.03';

use base 'Module::Install::Base';

use File::Spec::Functions qw[ catdir ];

my %Tokens = (

	      '%n' => sub { $_[0]->name },
	      '%v' => sub { $_[0]->version  },
);


sub _fill_template {

    my $self = shift;
    my ( $tpl, $tokens ) = @_;

    my ( $token, $value );

    while ( ( $token, $value ) = each %$tokens )
    {
	next unless defined $value;
	my $value = 'CODE' eq ref $value ? $value->($self) : $value;

	$tpl =~ s/$token/$value/g;
    }
    return $tpl;
}

sub template_install_path {

    my $self = shift;
    my %arg = ( template => undef,
		catdir => 1,
		tokens => {},
		@_ );

    my %tokens = ( %Tokens, %{$arg{tokens}} );

    for my $argv ( @ARGV )
    {
	next unless $argv =~ /^(INSTALL_BASE|PREFIX|LIB)=(.*)/i;

	die ( "$1: no value specified\n" )
	  unless defined $2;
	my $var  = $1;
	my $base = $2;

	my $nbase = $self->_fill_template( $base, \%tokens );

	if ( $nbase eq $base && defined $arg{template} )
	{
	    $nbase = $self->_fill_template( $arg{template}, \%tokens );
	    $nbase = catdir( $base, $nbase )
	      if $arg{catdir};
	}

	$argv = "\U$var\E=$nbase";
    }

    return;
}
1;

__END__

=head1 NAME

Module::Install::TemplateInstallPath - templatize installation paths


=head1 SYNOPSIS

    use inc::Module::Install;

    name 'Your-Module';
    all_from 'lib/Your/Modulepm';

    template_install_path( \%options );

=head1 DESCRIPTION

This B<Module::Install> plugin rewrites command line arguments of the form

  <variable>=<template>

where C<< <variable> >> is one of

  INSTALL_BASE PREFIX LIB

(case is not significant and C<< <variable> >> is rewritten in upper
case).

Any of the following tokens found in C<< <template> >> is replaced by
its associated value:

=over

=item C<%n>

The name of the module

=item C<%v>

The version of the module

=back

The recognized tokens may be augmented or overridden.



=head1 Functions

=over

=item template_install_path

  template_install_path( \%options );

This function will process the command line.  It should be run I<after>
information about the module is provided to B<Module::Install> (e.g. via
C<name()> or C<version()>, etc), but before C<WriteAll> (or equivalent).

The following options are recognized:

=over

=item template I<template>

This specifies a template to be used if the value passed on the
command line is unchanged after processing (implying it contained no
template tokens).

If the B<catdir> option is true, the results of filling in this
template are appended to the value on the commandline using
B<File::Spec::Functions::catdir>.

=item catdir I<boolean>

See B<template> for what this does.  It defaults to true.

=item tokens I<hashref>

This specifies a hash containing tokens and their values.  Tokens
must be the exact string which will be replaced.  Token values may be
a scalar or a code reference.  In the latter case they will be
passed a reference to the B<Module::Install> object.  For example,
here is how the default tokens are specified:

  {
      '%n' => sub { $_[0]->name },
      '%v' => sub { $_[0]->version  },
  }


To override a token, just provide a new value for it.  To delete a token,
set it to the undefined value.

=back

=back


=head1 DIAGNOSTICS

=over

=item C<< %s: no value specified >>

The named variableC was specified without a value.

=back

=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-install-graft@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-TemplateInstallPath>.

=head1 SEE ALSO

L<Module::Install>

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 The Smithsonian Astrophysical Observatory

Module::Install::TemplateInstallPath is free software: you can
redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>
