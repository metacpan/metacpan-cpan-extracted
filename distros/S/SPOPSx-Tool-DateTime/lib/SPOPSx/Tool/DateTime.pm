package SPOPSx::Tool::DateTime;

use strict;
use warnings;

use Log::Log4perl;
my $log = Log::Log4perl->get_logger(__PACKAGE__);

our $VERSION = '0.02';

=head1 NAME

SPOPSx::Tool::DateTime - SPOPS extension for arbitrarily formatted DateTime fields

=head1 SYNOPSIS

  %conf = (
      table_alias => {
          # ...
          datetime_format => {
              atime => 'DateTime::Format::MySQL',
              mtime => 'DateTime::Format::Baby',
              ctime => DateTime::Format::Strptime->new(pattern => '%D %T'),
          },
          # ...
      }
  );

=head1 DESCRIPTION

This module allows for L<DateTime> objects to be stored to and loaded from a database field. This module differs from the L<SPOPS::Tool::DateConvert> tool that is distributed with SPOPS in that it allows for the use of arbitrary L<DateTime> format objects. (See L<http://datetime.perl.org/> for details on DateTime and formatting.)

=cut

sub ruleset_factory {
	my ($class, $rstab) = @_;
	push @{ $rstab->{post_fetch_action} }, \&convert_to_date;
	push @{ $rstab->{pre_save_action} }, \&convert_to_string;
	push @{ $rstab->{post_save_action} }, \&convert_to_date;
	$log->is_info &&
		$log->info("DateTime ruleset added post_fetch, pre/post_save rules to [$class]");
	return __PACKAGE__;
}

sub _require_format {
	my $class = shift;
	my $format = shift;
	$format =~ /^[\w:]+$/ 
		or die "Bad format package $format for $class.";
	eval "require $format";
	warn "Possible error including $format: $@" if $@;
	$log->is_info &&
		$log->info("DateTime ruleset required $format.");
}

sub convert_to_date {
	my $self = shift;
	my $config = $self->CONFIG;

	while (my ($field, $format) = each %{ $config->{datetime_format} }) {
		defined $self->{$field} or next;

		$log->debug("Converting $self->{$field} to datetime.");

		unless (ref $format) {
			_require_format($config->{class}, $format);
			$config->{datetime_format}{$field} = $format = $format->new;
		}
		
		$self->{$field} = $format->parse_datetime($self->{$field});
	}

	return __PACKAGE__;
}

sub convert_to_string {
	my $self = shift;
	my $config = $self->CONFIG;

	while (my ($field, $format) = each %{ $config->{datetime_format} }) {
		defined $self->{$field} or next;

		$log->debug("Converting $self->{$field} to string.");

		unless (ref $format) {
			_require_format($config->{class}, $format);
			$config->{datetime_format}{$field} = $format = $format->new;
		}
	
		$self->{$field} = $format->format_datetime($self->{$field});
	}

	return __PACKAGE__;
}

=head1 INSTALLATION

Typical:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

or:

  perl Makefile.PL
  make
  make test
  make install

=head1 SEE ALSO

L<SPOPS>, L<DateTime>, L<http://datetime.perl.org/>, L<SPOPS::Tool::DateConvert>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

This library is distributed and licensed under the same terms as Perl itself.

=cut

1
