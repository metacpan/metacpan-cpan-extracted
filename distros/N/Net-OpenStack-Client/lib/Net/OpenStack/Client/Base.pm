package Net::OpenStack::Client::Base;
$Net::OpenStack::Client::Base::VERSION = '0.1.4';
use strict;
use warnings;


=head1 NAME

Net::OpenStack::Client::Base provides basic class structure for Net::OpenStack::Client

=head2 Public methods

=over

=item new

=cut

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        versions => {},
        services => {},
    }; # here, it gives a reference on a hash
    bless $self, $class;

    return $self->_initialize(@_) ? $self : undef;
};

=item error, warn, info, debug

Convenience methods to access the log instance that might
be passed during initialisation and set to $self->{log}.

=cut

no strict 'refs';
foreach my $i (qw(error warn info debug)) {
    *{$i} = sub {
        my ($self, @args) = @_;
        if ($self->{log}) {
            return $self->{log}->$i(@args);
        } else {
            return;
        }
    }
}
use strict 'refs';

=item verbose

Convenience method to access verbose method of log instance if it exists.
When absent, this is an alias for debug.

=cut

sub verbose
{
    my ($self, @args) = @_;
    if ($self->{log}) {
        my $method = $self->{log}->can('verbose') ? 'verbose' : 'debug';
        return $self->{log}->$method(@args);
    } else {
        return;
    }
}


=pod

=back

=cut

1;
