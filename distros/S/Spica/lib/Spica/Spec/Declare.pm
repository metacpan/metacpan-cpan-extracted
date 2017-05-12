package Spica::Spec::Declare;
use strict;
use warnings;
use Exporter::Lite;

use Spica::Spec;
use Spica::Client;

our @EXPORT = qw(
    spec 
    name
    endpoint
    client
    columns
    receiver
    row_class
    base_row_class
    inflate
    deflate
    trigger
    filter
);

our $CURRENT_SCHEMA_CACHE;

sub spec (&;$) {
    my ($code, $schme_class) = @_;
    local $CURRENT_SCHEMA_CACHE = $schme_class;
    $code->();
    _current_spec();
}

sub base_row_class ($) {
    my $current = _current_spec();
    $current->{__base_row_class} = $_[0];
}

sub row_namespace ($) {
    my $client_name = shift;
    (my $caller = caller(1)) =~ s/::Spec$//;
    join '::' => $caller, 'Row', Spica::Spec::camelize($client_name);
}

sub _current_spec {
    my $class = __PACKAGE__;
    my $spec_class;

    if ($CURRENT_SCHEMA_CACHE) {
        $spec_class = $CURRENT_SCHEMA_CACHE;
    } else {
        my $i = 1;
        while ( $spec_class = caller($i++) ) {
            last unless $spec_class->isa( $class );
        }
    }

    unless ($spec_class) {
        Carp::confess("PANIC: cannot find a package naem this is not ISA ${class}");
    }

    no warnings 'once';
    if (!$spec_class->isa('Spica::Spec')) {
        no strict 'refs'; ## no critic
        push @{"${spec_class}::ISA"} => 'Spica::Spec';

        my $spec = $spec_class->new();
        $spec_class->set_default_instance( $spec );
    }

    return $spec_class->instance;
}

sub _generate_filter_init_builder {
    my (@attributes) = @_;

    return sub {
        my ($spica, $builder) = @_;

        my @attrs = @attributes;

        my %param = %{ $builder->param };
        for my $attr (@attrs) {
            next unless exists $param{$attr->{name}};
            $param{$attr->{origin}} = delete $param{$attr->{name}};
        }

        $builder->param(\%param);

        return $builder;
    };
}

sub _generate_filter_init_row_class {
    my (@attributes) = @_;

    return sub {
        my ($spica, $data) = @_;
        my %data =  map { $_->{name} => $data->{$_->{origin}} }
                   grep { !$_->{no_row_accessor} }
                   @attributes;
        return \%data;
    };
}

sub columns (@);
sub name ($);
sub endpoint ($$@);
sub receiver ($);
sub row_class ($);
sub inflate ($&);
sub deflate ($&);
sub trigger ($&);
sub filter ($&);
sub client (&) {
    my $code = shift;
    my $current = _current_spec();

    my (
        $client_name,
        @client_columns,
        %endpoint,
        @inflate,
        @deflate,
        %trigger,
        %filter,
        $row_class,
        $receiver,
    );

    my $dest_class = caller();

    my $_name = sub ($) {
        $client_name = shift;
        $row_class = row_namespace($client_name);
        $receiver = 'Spica::Receiver::Iterator';
    };
    my $_columns = sub (@) { @client_columns = @_ };
    my $_receiver = sub ($) { $receiver = $_[0] };
    my $_row_class = sub ($) { $row_class = $_[0] };
    my $_endpoint = sub ($$@) {
        my $name = shift;
        my ($method, $path_base, $requires) = @_;
        if (@_ == 1) {
            $method    = $_[0]{method};
            $path_base = $_[0]{path};
            $requires  = $_[0]{requires};
        } else {
            $method = 'GET';
            ($path_base, $requires) = @_;
        }
        if (!$method or !$path_base or !$requires) {
            Carp::croak('Invalid args endpoint.');
        }
        $endpoint{$name} = +{
            method   => $method,
            path     => $path_base,
            requires => $requires,
        };
    };
    my $_inflate = sub ($@) {
        my ($rule, $code) = @_;
        $rule = qr/^\Q$rule\E$/ if ref $rule ne 'Regexp';
        push @inflate => ($rule, $code);
    };
    my $_deflate = sub ($@) {
        my ($rule, $code) = @_;
        $rule = qr/^\Q$rule\E$/ if ref $rule ne 'Regexp';
        push @deflate => ($rule, $code);
    };
    my $_trigger = sub ($@) {
        my ($name, $code) = @_;
        push @{ ($trigger{$name} ||= []) } => $code;
    };
    my $_filter = sub ($@) {
        my ($name, $code) = @_;
        push @{ ($filter{$name} ||= []) } => $code;
    };

    no strict 'refs'; ## no critic;
    no warnings 'once';
    no warnings 'redefine';

    local *{"${dest_class}::name"}      = $_name;
    local *{"${dest_class}::columns"}   = $_columns;
    local *{"${dest_class}::receiver"}  = $_receiver;
    local *{"${dest_class}::row_class"} = $_row_class;
    local *{"${dest_class}::endpoint"}  = $_endpoint;
    local *{"${dest_class}::inflate"}   = $_inflate;
    local *{"${dest_class}::deflate"}   = $_deflate;
    local *{"${dest_class}::trigger"}   = $_trigger;
    local *{"${dest_class}::filter"}    = $_filter;

    $code->();

    my (@accessor_names, @attributes);
    while (@client_columns) {
        my $column_name = shift @client_columns;
        my $option = ref $client_columns[0] ? shift @client_columns : +{};

        push @accessor_names => $column_name if !$option->{no_row_accessor};
        push @attributes => +{
            name   => $column_name,
            origin => ($option->{from} || $column_name),
            no_row_accessor => $option->{no_row_accessor},
        };
    }

    push @{ $filter{init_builder}   } => _generate_filter_init_builder   @attributes;
    push @{ $filter{init_row_class} } => _generate_filter_init_row_class @attributes;

    my $client = Spica::Client->new(
        columns   => \@accessor_names,
        name      => $client_name,
        endpoint  => \%endpoint,
        inflators => \@inflate,
        deflators => \@deflate,
        receiver  => $receiver,
        row_class => $row_class,
        ($current->{__base_row_class} ? (base_row_class => $current->{__base_row_class}) : ()),
    );

    for my $name (keys %trigger) {
        $client->add_trigger($name => $_) for @{ $trigger{$name} };
    }
    for my $name (keys %filter) {
        $client->add_filter($name => $_) for @{ $filter{$name} };
    }

    $current->add_client($client);
}

1;
__END__

=encoding utf-8

=head1 NAME

Spica::Spec::Declare

=head1 SYNOPSIS

    package Your::Spec;
    use Spica::Spec::Declare;

    client {
        name 'example';
        endpoint 'search' => '/examples' => [qw(access_token)];
        columns (
            'access_token' => +{from => 'accessToken', no_row_accessor => 1},
            'id'           => +{from => 'exampleId'},
            'name'         => +{from => 'exampleName'},
            'status',
        );
    };

=head1 DESCRIPTIOM

=head1 FUNCTIONS

=head2 client(\&callback)

C<client> defines the specification of the API.
C<client> In C<Spica> is a power that defines the structure of each data, not URI.

    client {
        .. client's settings ..
    };

=head2 name($client_name)

C<name> defines the name of the C<client>. C<name> fields are required.

    client {
        name 'client_name';
    };

on fetch calling:

    $spica->fetch('client_name', ...);

=head2 endpoint

C<endpoint> defines the path and requires param.
C<endpoint> it is possible to define more than one against C<client> one.

=over

=item endpoint($endpoin_name, $path, \@requires)

Make the request using the GET method as the initial value in this definition. If you want to specify the HTTP method, please refer to the matter.

    client {
        name 'client_name';
        endpoint 'endpoint_name' => '/path/to' => [qw(id)];
    };

on fetch:
    
    $spica->fetch('client_name', 'endpoint_name', \%param);

If you specify a string of C<default> to C<$endpoint_name>, you can omit the C<$endpoint_name> when you use the Spica->fetch.

    client {
        name 'client_name';
        endpoint 'default' => '/path/to' => [qw(id)];
    };

on fetch:
    
    $spica->fetch('client_name', \%param);

=item endpoint(\%settings)

C<endpoint> defines the path and request method and requires param.

    client {
        name 'client_name';
        endpoint 'default' => +{
            method   => 'POST',
            path     => '/path/to',
            requires => [qw(id)],
        };
    };

=back

=head2 receiver

Specify an Iterator class.
C<Spica::Receiver::Iterator> Is used by default.

    client {
        ...
        receiver 'Your::Iterator';
    };

=head2 row_class

Specify an Row class.
C<Spica::Receiver::Row::*> Is used by default.

    client {
        ...
        row_class 'Your::Row::Example';
    };

=head2 hooks

=over

=item trigger($hook_point_name, \&code);

=item filter($hook_point_name, \&code);

=back

=head1 SEE ALSO

L<Spica>

=cut
