
## no critic (ProhibitMultiplePackages, RequireFilenameMatchesPackage, RequireUseWArnings, RequireUseStrict, RequireExplicitPackage)

=head1 NAME

OAuthomatic::Types - few helper types to make code more readable and less error-prone

=head1 DESCRIPTION

Types below are defined to make code a bit more readable and less error prone.

=cut

=head1 OAuthomatic::Types::StructBase

Role composed into types defined below. Handles a few common
conventions.

=head2 METHODS

=head3 new

Adds two conventions to usual parameter handling:

=over 4

=item *

Any empty or undef'ed values given to the constructor are dropped as
if they were not specified at all.

=item *

If args C<data> and C<remap> are given to the constructor, they are
used to translate field names, for example:

    Something->new(data=>{aaa=>'x', bbb=>'y'},
                   remap=>{aaa=>'token', 'bbb'=>'secret');

is equivalent to:

    Something->new(token=>'x', secret=>'y');

Partial replacements are possible too:

    Something->new(data=>{token=>'x', bbb=>'y'},
                   remap=>{'bbb'=>'secret');

=back

=head3 Class->of_my_type(obj)

Checks whether given object is of given structure type. Returns 1 if so, 0 if it is undef,
throws if it is of another type.

=head2 Class->equal(obj1, obj2)

Compares two objects, allowing undef-s but raises on wrong type.

=cut

{
    package OAuthomatic::Types::StructBase;
    use Moose::Role;
    use OAuthomatic::Error;
    use Scalar::Util qw(blessed);
    use namespace::sweep;

    around BUILDARGS => sub {
        my $orig  = shift;
        my $class = shift;
        my $ret = $class->$orig(@_);

        # Drop empty values  (FIXME: this is close to MooseX::UndefTolerant)
        foreach my $key (keys %$ret) {
            my $val = $ret->{$key};
            unless(defined($val) && $val =~ /./x) {
                delete $ret->{$key};
            }
        }

        # Remap names
        if(exists $ret->{remap}) {
            my $remap = $ret->{remap};
            my $data = $ret->{data} or 
              OAuthomatic::Error::Generic->throw(
                  ident => "Bad call",
                  extra => "No data given in spite remap is specified");
            delete $ret->{remap};
            delete $ret->{data};
            my %data_unconsumed = %$data;  # To delete consumed keys
            foreach my $mapped (keys %$remap) {
                my $mapped_to = $remap->{$mapped};
                my $value = $data->{$mapped}
                  or OAuthomatic::Error::Generic->throw(
                      ident => "Missing parameter",
                      extra => "Missing $mapped (while constructing $class). Known keys: ") . join(", ", keys %$data) . "\n";
                delete $data_unconsumed{$mapped};
                $ret->{$mapped_to} = $value;
            }
            # Copy unmapped data verbatim
            while (my ($k, $v) = each %data_unconsumed) {
                $ret->{$k} = $v;
            }
        }
        return $ret;
    };

    sub of_my_type {
        my ($class, $obj) = @_;
        return '' if ! defined($obj);
        my $pkg = blessed($obj);
        unless( $pkg ) {
            OAuthomatic::Error::Generic->throw(
                ident => "Bad parameter", extra => "Wrong object type (expected $class, got non-blessed scalar)");
        }
        return 1 if $obj->isa($class);
        return OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter", extra => "Wrong object type (expected $class, got $pkg)");
    }
};

=head1 OAuthomatic::Types::ClientCred

Client (application) credentials. Fixed key and secret allocated manually
using server web interface (usually after filling some form with various
details) which identify the application.

=head2 ATTRIBUTES

=over 4

=item key

Client key - the application identifier.

=item secret

Client secret - confidential value used to sign requests, to prove key
is valid.

=back

=cut

{
    package OAuthomatic::Types::ClientCred;
    use Moose;
    with 'OAuthomatic::Types::StructBase';

    has 'key' => (is => 'ro', isa => 'Str', required => 1);
    has 'secret' => (is => 'ro', isa => 'Str', required => 1);

    sub as_hash {
        my ($self, $prefix) = @_;
        return (
           $prefix . '_key'     => $self->key,
           $prefix . '_secret' => $self->secret,
          );
    }

    sub equal {
        my ($class, $left, $right) = @_;
        # Croaks of mismatches, false on undefs
        return '' unless $class->of_my_type($left) && $class->of_my_type($right);
        # Compare all fields
        return ($left->key eq $right->key) && ($left->secret eq $right->secret);
    }

};

# Common implementation for two classes below
{
    package OAuthomatic::Types::GenericTokenCred;
    use Moose;
    with 'OAuthomatic::Types::StructBase';

    has 'token' => (is => 'ro', isa => 'Str', required => 1);
    has 'secret' => (is => 'ro', isa => 'Str', required => 1);

    sub as_hash {
        my $self = shift;
        return (
           token => $self->token,
           token_secret => $self->secret,
          );
    }

    sub equal {
        my ($class, $left, $right) = @_;
        # Croaks of mismatches, 0 on undefs
        return '' unless $class->of_my_type($left) && $class->of_my_type($right);
        # Compare all fields
        return ($left->token eq $right->token) && ($left->secret eq $right->secret);
    }
};

=head1 OAuthomatic::Types::TemporaryCred

Temporary (request) credentials. Used during process of allocating
token credentials.

=head2 ATTRIBUTES

=over 4

=item token

Actual token - identifier quoted in requests.

=item secret

Associated secret - confidential value used to sign requests, to prove they
are valid.

=item authorize_page

Full URL of the page end user should use to spend this temporary credential
and generate access token. Already contains the token.

=back

=cut
{
    package OAuthomatic::Types::TemporaryCred;
    use Moose;
    extends 'OAuthomatic::Types::GenericTokenCred';

    # This is rw and not required as we append it after initial object creation
    has 'authorize_page' => (is => 'rw', isa => 'URI', required => 0);
};


=head1 OAuthomatic::Types::TokenCred

Token (access) credentials. Those are used to sign actual API calls.

=cut

{
    package OAuthomatic::Types::TokenCred;
    use Moose;
    extends 'OAuthomatic::Types::GenericTokenCred';
};

=head1 OAuthomatic::Types::Verifier

Verifier info, returned from authorization.

=cut

{
    package OAuthomatic::Types::Verifier;
    use Moose;
    with 'OAuthomatic::Types::StructBase';

    has 'token' => (is => 'ro', isa => 'Str', required => 1);
    has 'verifier' => (is => 'ro', isa => 'Str', required => 1);

    sub equal {
        my ($class, $left, $right) = @_;
        # Croaks of mismatches, 0 on undefs
        return '' unless $class->of_my_type($left) && $class->of_my_type($right);
        # Compare all fields
        return ($left->token eq $right->token) && ($left->verifier eq $right->verifier);
    }
};

1;
