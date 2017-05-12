#===============================================================================
#
#         FILE:  Translate.pm
#
#  DESCRIPTION:  Gettext wrapper
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  03.08.2009 13:34:51 UTC
#===============================================================================

=head1 NAME

NetSDS::Translate - simple API to gettext

=head1 SYNOPSIS

	use NetSDS::Translate;

	my $trans = NetSDS::Translate->new(
		lang => 'ru',
		domain => 'NetSDS-IVR',
	);

	print $trans->translate("Detect CallerID");

=head1 DESCRIPTION

C<NetSDS::Translate> module provides API to gettext translation subsystem

=cut

package NetSDS::Translate;

use 5.8.0;
use strict;
use warnings;

use POSIX;
use Locale::gettext;
use NetSDS::Const;

use base 'NetSDS::Class::Abstract';

use version; our $VERSION = '1.301';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

    my $trans = NetSDS::Translate->new(
		lang => 'ru',
		domain => 'NetSDS-IVR',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# FIXME - this should be configurable option
	my %locale = (
		ru => 'ru_RU.UTF-8',
		en => 'en_US.UTF-8',
		ua => 'ua_UK.UTF-8',
	);

	my $self = $class->SUPER::new(
		lang   => DEFAULT_LANG,
		domain => 'NetSDS',
		%params,
	);

	# Initialize proper locale
	setlocale( LC_MESSAGES, $locale{$self->{lang}} );
	$self->{translator} = Locale::gettext->domain($self->{domain});

	return $self;

}

#***********************************************************************

=item B<translate($string)> - translate string

Return translated string.

	print $trans->translate("All ok");

=cut

#-----------------------------------------------------------------------

sub translate {

	my ( $self, $str ) = @_;

	return $self->{translator}->get($str);

}

1;

__END__

=back

=head1 TODO

1. Make configurable language to locale conversion in constructor.

2. Implement placeholders support provided by gettext.

=head1 SEE ALSO

L<Locale::gettext>

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


