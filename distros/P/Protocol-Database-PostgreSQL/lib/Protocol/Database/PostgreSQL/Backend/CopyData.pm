package Protocol::Database::PostgreSQL::Backend::CopyData;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::CopyData

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub type { 'copy_data' }

sub rows { shift->{rows}->@* }

my %_charmap = reverse(
    "\\"   => "\\\\",
    "\x08" => "\\b",
    "\x09" => "\\t",
    "\x0A" => "\\r",
    "\x0C" => "\\f",
    "\x0D" => "\\n",
);

sub new_from_message {
    my ($class, $msg) = @_;
    my $data = substr $msg, 5;
    $log->tracef('COPY data is %s', $data);
    my @rows = map {
        [
            map {
                $_ eq '\N'
                ? undef
                : s/(\\[\\btrfn])/$_charmap{$1}/ger
            } split /\t/
        ]
    } split /\n/, $data;
    return $class->new(
        rows => \@rows,
#        data_format => $data_format,
#        count       => $count,
#        formats     => \@formats
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

