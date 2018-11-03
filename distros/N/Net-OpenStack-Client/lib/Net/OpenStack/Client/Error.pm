package Net::OpenStack::Client::Error;
$Net::OpenStack::Client::Error::VERSION = '0.1.4';
use strict;
use warnings;

use base qw(Exporter);

our @EXPORT = qw(mkerror);

use Readonly;

use overload bool => 'is_error', '==' => '_is_equal', '!=' => '_is_not_equal', '""' => '_stringify';

Readonly::Hash our %ERROR_CODES => {
};

Readonly::Hash our %REVERSE_ERROR_CODES => map {$ERROR_CODES{$_} => $_} keys %ERROR_CODES;

=head1 NAME

Net::OpenStack::Client::Error is an error class for Net::OpenStack::Client.

Boolean logic and (non)-equal operator are overloaded using C<is_error> method.
(Use C<==> and C<!=> also for name/message, not C<eq> / C<ne> operators).

=head2 Public methods

=over

=item mkerror

A C<Net::OpenStack::Client::Error> factory

=cut

sub mkerror
{
    return Net::OpenStack::Client::Error->new(@_);
}


=item new

Create new error instance from options, e.g. from a (decoded dereferenced) JSON response.

Arguments are handled by C<set_error>.

=cut

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        __errattr => [],
    };
    bless $self, $class;

    $self->set_error(@_);

    return $self;
};

=item set_error

Process arguments to error

=over

=item no args/undef: reset the error attribute

=item single argument string: convert to an C<Error> instance with message

=item single argument hasref/Error instance: make a copy

=item single argument/other: set Error message and save original in _orig attribute

=item options (more than one arg): set the options

=back

=cut

sub set_error
{
    my $self = shift;

    my $nrargs = scalar @_;

    my %opts;
    if ($nrargs == 1) {
        my $err = shift;
        my $ref = ref($err);

        if($ref eq 'Net::OpenStack::Client::Error') {
            %opts = map {$_ => $err->{$_}} @{$err->{__errattr}};
        } elsif ($ref eq 'HASH') {
            %opts = %$err;
        } elsif (defined($err) && $ref eq '') {
            $opts{message} = $err;
        } elsif (defined($err)) {
            $opts{message} = "unknown error type $ref, see _orig attribute";
            $opts{_orig} = $err;
        }
    } elsif ($nrargs > 1) {
       %opts = @_;
    }


    # Wipe current state
    # Do this after the %opts are build, to allow copies of itself
    foreach my $key (@{$self->{__errattr}}) {
        delete $self->{$key};
    }
    $self->{__errattr} = [];

    # sort produces sorted __errattr
    foreach my $key (sort keys %opts) {
        $self->{$key} = $opts{$key};
        push(@{$self->{__errattr}}, $key);
    }

    return $self;
}

=item is_error

Test if this is an error or not.

If an optiona l C<type> argument is passed,
test if error name or code is equal to C<type>.

A numerical type is compare to the code, a string is compare to the name or message

For a set of known errorcodes, a automatic reverse lookup is performed.
When e.g. only the error name attribute is set, one can test using a known errorcode.

=cut

sub is_error
{
    my ($self, $type, $reverse_lookup) = @_;

    $reverse_lookup = 1 if ! defined($reverse_lookup);

    my $res;

    if(defined($type)) {
        my $revtype;

        if ($type =~ m/^\d+$/) {
            $revtype = $REVERSE_ERROR_CODES{$type} if (exists($REVERSE_ERROR_CODES{$type}));
            $res = exists($self->{code}) && ($self->{code} == $type);
        } else {
            $revtype = $ERROR_CODES{$type} if (exists($ERROR_CODES{$type}));
            $res = (exists($self->{name}) && ($self->{name} eq $type)) || (exists($self->{message}) && ($self->{message} eq $type));
        }

        # If a reverse known error is found, and it is not yet an error, lookup the reverse
        # Disable the reverse-lookup here to avoid loop
        $res = $self->is_error($revtype, 0) if ($reverse_lookup && defined($revtype) && ! $res);
    } else {
        $res = exists($self->{code}) || exists($self->{name}) || exists($self->{message});
    }

    return $res ? 1 : 0;
}

# is_equal for overloading ==
# handle == undef (otherwise this would be $self->is_error)
sub _is_equal
{
    # Use shift, looks like a 3rd argument (an empty string) is passed
    my $self = shift;
    my $othererror = shift;
    return defined($othererror) && $self->is_error($othererror);
}

# inverse is_equal for overloading !=
sub _is_not_equal
{
    my $self = shift;
    return ! $self->_is_equal(@_);
}

# _stringify create string for stringification
sub _stringify
{
    my $self = shift;

    if ($self->is_error()) {
        my @fields;
        foreach my $attr (qw(method url name code message)) {
            push(@fields, $self->{$attr}) if exists ($self->{$attr});
        }
        return "Error ".join(' / ', @fields);
    } else {
        return  "No error";
    };
}

=pod

=back

=cut

1;
