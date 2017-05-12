package Protocol::SPDY::Test;
$Protocol::SPDY::Test::VERSION = '1.001';
use strict;
use warnings;
use Protocol::SPDY::Constants ':all';
use Protocol::SPDY::Frame;
use Exporter qw(import);
use Test::More;
use Try::Tiny;

=head1 NAME

Protocol::SPDY::Test - helper functions for testing things

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use Protocol::SPDY::Test qw(:all);

=head1 DESCRIPTION

Provides a few functions that may help when trying to debug
implementations. Not intended for use in production code.

=cut

our @EXPORT_OK = qw(control_frame_ok);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK
);

my %frame_test = (
	SYN_STREAM => sub {
		my $frame = shift;
		my $spec = shift || {};
		subtest "SYN_STREAM" => sub {
			plan tests => 5 + keys %$spec;
			try {
				cmp_ok($frame->length, '>=', 10, 'length must be >= 12');
				ok($frame->stream_id, 'have a stream identifier');
				is($frame->stream_id, 0+$frame->stream_id, 'identifier is numeric');
				cmp_ok($frame->priority, '>=', 0, 'priority >= 0');
				cmp_ok($frame->priority, '<=', 3, 'priority <= 3');
				is($frame->$_, $spec->{$_}, $_ . ' matches') for grep exists $spec->{$_}, qw(stream_id priority associated_stream_id);
			} catch {
				fail('Had exception during subtest: ' . $_);
			};
			done_testing;
		};
	}
);

=head2 control_frame_ok

Tests whether the given frame is valid.

Takes the following parameters:

=over 4

=item * $frame - the L<Protocol::SPDY::Frame> object to test

=item * $spec - the spec to test against, default empty

=item * $msg - message to display in test notes

=back

=cut

sub control_frame_ok($;$$) {
	my $frame = shift;
	my $spec = shift || {};
	my $msg = shift || '';
	subtest "Frame validation - " . $msg => sub {
		try {
			isa_ok($frame, 'Protocol::SPDY::Frame::Control');
			can_ok($frame, qw(is_control is_data length type));
			ok($frame->is_control, 'is_control returns true');
			ok(!$frame->is_data, 'is_data returns false');
			cmp_ok($frame->length, '>=', 0, 'length is nonzero');
			ok(my $type = $frame->type_string, 'have a frame type');
			note 'type is ' . $type;
			try {
				$frame_test{$type}->($frame, $spec)
			} catch {
				fail('Had exception during subtest: ' . $_);
			} if exists $frame_test{$type};
		} catch {
			fail('Had exception during subtest: ' . $_);
		};
		done_testing;
	};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
