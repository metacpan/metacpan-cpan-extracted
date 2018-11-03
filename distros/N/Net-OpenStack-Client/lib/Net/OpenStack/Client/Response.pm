package Net::OpenStack::Client::Response;
$Net::OpenStack::Client::Response::VERSION = '0.1.4';
use strict;
use warnings;

use base qw(Exporter);

use Net::OpenStack::Client::Error;

our @EXPORT = qw(mkresponse);

use overload bool => '_boolean';

use Readonly;

Readonly my $RESULT_PATH => '/';

=head1 NAME

Net::OpenStack::Client::Response is an response class for Net::OpenStack.

Boolean logic is overloaded using C<_boolean> method (as inverse of C<is_error>).

=head2 Public methods

=over

=item mkresponse

A C<Net::OpenStack::Client::Response> factory

=cut

sub mkresponse
{
    return Net::OpenStack::Client::Response->new(@_);
}


=item new

Create new response instance.

Options

=over

=item data: (first) response content, possibly decoded

=item headers: hashref with reponse headers

=item error: an error (passed to C<mkerror>).

=item result_path: passed to C<set_result> to set the result attribute.

=back

=cut

sub new
{
    my ($this, %opts) = @_;
    my $class = ref($this) || $this;
    my $self = {
        data => $opts{data} || {},
        headers => $opts{headers} || {},
    };
    bless $self, $class;

    # First error
    $self->set_error($opts{error});

    # Then result
    $self->set_result($opts{result_path});

    return $self;
};

=item set_error

Set and return the error attribute using C<mkerror>.

=cut

sub set_error
{
    my $self = shift;
    $self->{error} = mkerror(@_);
    return $self->{error};
}

=item set_result

Set and return the result attribute based on the C<result_path>.

The C<result_path> is either

=over

=item (absolute, starting with C</>) path-like string, indicating which subtree of the answer
should be set as result attribute (default C</>).

=item anything else is considered a header (from the response headers).

=back

=cut

sub set_result
{
    my ($self, $result_path) = @_;

    my $res;

    if (! $self->is_error()) {
        $result_path = $RESULT_PATH if ! defined($result_path);

        $res = $self->{data};

        if ($result_path =~ m#^/#) {
            # remove any "empty" paths
            foreach my $subpath (grep {$_} split('/', $result_path)) {
                $res = $res->{$subpath} if (defined($res));
            };
        } else {
            # a header
            $res = $self->{headers}->{$result_path};
        }
    };

    $self->{result} = $res;

    return $self->{result};
};

=item result

Return the result attribute.

If C<result_path> is passed (and defined),
(re)set the result attribute first.
(The default result path cannot be (re)set this way.
Use C<set_result> method for that).

=cut

sub result
{
    my ($self, $result_path) = @_;

    $self->set_result($result_path) if defined($result_path);

    return $self->{result};
}

=item is_error

Test if this is an error or not (based on error attribute).

=cut

sub is_error
{
    my $self = shift;
    return $self->{error} ? 1 : 0;
}

# Overloaded boolean, inverse of is_error
sub _boolean
{
    my $self = shift;
    return ! $self->is_error();
}

=pod

=back

=cut

1;
