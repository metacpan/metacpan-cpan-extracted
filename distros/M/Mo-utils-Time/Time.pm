package Mo::utils::Time;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_time_24hhmm check_time_24hhmmss);

our $VERSION = 0.01;

sub check_time_24hhmm {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^(\d{2})\:(\d{2})$/ms) {
		err "Parameter '".$key."' doesn't contain valid time in HH:MM format.",
			'Value', $self->{$key},
		;
	}
	my ($hour, $min) = ($1, $2);
	if ($hour > 23) {
		err "Parameter '".$key."' doesn't contain valid hour in HH:MM time format.",
			'Value', $self->{$key},
		;
	}
	if ($min > 59) {
		err "Parameter '".$key."' doesn't contain valid minute in HH:MM time format.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_time_24hhmmss {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^(\d{2})\:(\d{2})\:(\d{2})$/ms) {
		err "Parameter '".$key."' doesn't contain valid time in HH:MM:SS format.",
			'Value', $self->{$key},
		;
	}
	my ($hour, $min, $sec) = ($1, $2, $3);
	if ($hour > 23) {
		err "Parameter '".$key."' doesn't contain valid hour in HH:MM:SS time format.",
			'Value', $self->{$key},
		;
	}
	if ($min > 59) {
		err "Parameter '".$key."' doesn't contain valid minute in HH:MM:SS time format.",
			'Value', $self->{$key},
		;
	}
	if ($sec > 59) {
		err "Parameter '".$key."' doesn't contain valid second in HH:MM:SS time format.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub _check_key {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		return 1;
	}

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Time - Mo time utilities.

=head1 SYNOPSIS

 use Mo::utils::Time qw(check_time_24hhmm check_time_24hhmmss);

 check_time_24hhmm($self, $key);
 check_time_24hhmmss($self, $key);

=head1 DESCRIPTION

Mo time utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_time_24hhmm>

 check_time_24hhmm($self, $key);

Check parameter defined by C<$key> if it's time in HH:MM format.
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_time_24hhmmss>

 check_time_24hhmmss($self, $key);

Check parameter defined by C<$key> if it's time in HH:MM:SS format.
Value could be undefined or doesn't exist.

Returns undef.

=head1 ERRORS

 check_time_24hhmm():
         Parameter '%s' doesn't contain valid hour in HH:MM time format.
                 Value: %s
         Parameter '%s' doesn't contain valid minute in HH:MM time format.
                 Value: %s
         Parameter '%s' doesn't contain valid time in HH:MM format.
                 Value: %s

 check_time_24hhmmss():
         Parameter '%s' doesn't contain valid hour in HH:MM:SS time format.
                 Value: %s
         Parameter '%s' doesn't contain valid minute in HH:MM:SS time format.
                 Value: %s
         Parameter '%s' doesn't contain valid second in HH:MM:SS time format.
                 Value: %s
         Parameter '%s' doesn't contain valid time in HH:MM:SS format.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_time_24hhmm_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Time qw(check_time_24hhmm);

 my $self = {
         'key' => '12:32',
 };
 check_time_24hhmm($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_time_24hhmm_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Time qw(check_time_24hhmm);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xx',
 };
 check_time_24hhmm($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid time in HH:MM format.

=head1 EXAMPLE3

=for comment filename=check_time_24hhmmss_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Time qw(check_time_24hhmmss);

 my $self = {
         'key' => '12:30:30',
 };
 check_time_24hhmmss($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_time_24hhmmss_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Time qw(check_time_24hhmmss);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad',
 };
 check_time_24hhmmss($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid time in HH:MM:SS format.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Time>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
