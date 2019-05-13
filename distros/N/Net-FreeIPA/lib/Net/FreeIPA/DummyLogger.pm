package Net::FreeIPA::DummyLogger;
$Net::FreeIPA::DummyLogger::VERSION = '3.0.3';
use strict;
use warnings;

=head1 NAME

Net::FreeIPA::DummyLogger provides dummy logger with log4perl interface

=head2 Public methods

=over

=item new

=cut

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {}; # here, it gives a reference on a hash
    bless $self, $class;

    return $self;
};

# Mock basic methods of Log4Perl getLogger instance
no strict 'refs'; ## no critic
foreach my $i (qw(error warn info debug)) {
    *{$i} = sub {}
}
use strict 'refs';

=pod

=back

=cut

1;
