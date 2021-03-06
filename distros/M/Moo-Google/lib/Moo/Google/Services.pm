package Moo::Google::Services;
$Moo::Google::Services::VERSION = '0.03';

# ABSTRACT: generate classes, attributes and methods for appropriate API methods using Moose::Meta::Class

use Moose;

# because of:
# class must be not immutable
# use Mouse::Meta::Class;
# use Mouse::Meta::Attribute;

use Data::Dumper;
use Data::Printer;

has 'debug' => ( is => 'rw', default => 0, lazy => 1 );

# has 'client' => ( is => 'ro', default => sub { require Moo::Google::Client; Moo::Google::Client->new(); }, handles => [qw(api_query)], lazy => 1);

# has 'util' => ( is => 'ro', default => sub { require Moo::Google::Util; Moo::Google::Util->new(); }, handles => [qw(substitute_placeholders)], lazy => 1);

has 'discovery' => (
    is      => 'ro',
    default => sub {
        require Moo::Google::Discovery;
        Moo::Google::Discovery->new( debug => shift->debug );
    },
    lazy => 1
);

# use Moo::Google::Discovery;
# my $self->discovery = Moo::Google::Discovery->new(debug=>shift->debug);

# extends 'Moo::Google::Client';


sub generate_one {
    my ( $self, $object, $p ) = @_;    # $p = parameter(s)

    warn Dumper ref($p) if ( $self->debug );

    my $api;
    my $version;

    if ($p) {
        $api = $p;
    }
    elsif ( ref($p) eq 'HASH' ) {
        $api = $p->{api};
    }
    else {
        die "Wrong parameters type. Supported are HASH or SCALAR";
    }

    warn $api if ( $self->debug );

    if ( $self->discovery->exists($api) ) {
        $version = $self->discovery->latestStableVersion($api);
    }
    else {
        die
"No such service or its currently unsupported by Google API discovery";
    }

    #my $base_class = 'Moo::Google::';  # $object
    warn "Generating Resources for " . ref($object) . " class"
      if ( $self->debug );
    my $base_class         = ref($object);    # $object
    my $service_name       = $api;
    my $service_class_name = ucfirst $api;

    # warn $service_name;
    # # warn $s->{version}[0];
    my $service_class = Moose::Meta::Class->create(
        join( '::', $base_class, $service_class_name ) );    # Calendar
    my $service_description = $self->discovery->getRest(
        { api => $service_name, version => $version } );
    warn $service_name
      . " resources :"
      . Dumper $service_description->{resources}
      if ( $self->debug );

    my @resources = keys %{ $service_description->{resources} };

    for my $resource_name (@resources) {
        my $resource_class_name = ucfirst $resource_name;
        my $resource_class      = Moose::Meta::Class->create(
            join(
                '::', $base_class, $service_class_name, $resource_class_name
            )
        );    # Calendar:Events

        $service_class->add_attribute(
            $resource_class_name => {
                is      => 'ro',
                default => sub { $resource_class->new_object },
                lazy    => 1
            }
        );

        my $methods_hash =
          $service_description->{resources}{$resource_name}{methods}
          ; # return like { 'get' => 'HASH(0x3deeb48)', 'list' => 'HASH(0x3e18698)', ... }
            # warn Dumper $methods_hash;

        my @methods = keys %$methods_hash;

        for my $method_name (@methods) {
            $resource_class->add_method(
                $method_name => sub {
                    my ( $self, $params ) = @_;
                    $object->request(
                        join( '::',
                            $base_class,          $service_class_name,
                            $resource_class_name, $method_name ),
                        $params
                    );
                }
            );
        }

    }

    ## add attributes to this class

    # adding to Moo::Google::Services

    # $self->meta->add_attribute(

    $object->meta->add_attribute(
        $service_class_name => {
            is      => 'ro',
            default => sub { $service_class->new_object },
            lazy    => 1
        }
    );

}


sub generate_all {
    my $self     = shift;
    my $services = $self->discovery->availableAPIs();

    # warn "All services: ".Dumper $services;

    for my $s (@$services) {
        $self->generate_one( $s->{name} );
    }

}

# sub request {
#   my ($self, $caller, $params) = @_;
#   # my $caller = (caller(0))[3];
#   warn "Caller: ".$caller;
#   my $api_q_data = $self->discovery->getMethodMeta($caller);
#   $api_q_data->{options} = $params->{options};
#   delete $params->{options};
#   $api_q_data->{path} = $self->substitute_placeholders($api_q_data->{path}, $params);
#   warn Dumper $api_q_data;
#   $self->api_query($api_q_data); # path, httpMethod
# };

sub substitute_placeholders {
    my ( $self, $string, $parameters ) = @_;

    # find all parameters in string
    my @matches = $string =~ /{([a-zA-Z_]+)}/g;
    for my $prm (@matches) {

        # warn $prm;
        if ( defined $parameters->{$prm} ) {
            my $s = $parameters->{$prm};
            warn "Value of " . $prm . " took from passed parameters: " . $s;
            $string =~ s/{$prm}/$s/g;
        }
        elsif ( defined $self->$prm ) {
            my $s = $self->$prm;
            warn "Value of " . $prm . " took from class attributes: " . $s;
            $string =~ s/{$prm}/$s/g;
        }
        else {
            die "cant replace " . $prm . " placeholder: no source";
        }
    }
    return $string;
}

# has 'Calendar' => ( is => 'ro', default => sub {
#   require Moo::Google::Calendar;
#   Moo::Google::Calendar->new;
# });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Google::Services - generate classes, attributes and methods for appropriate API methods using Moose::Meta::Class

=head1 VERSION

version 0.03

=head1 METHODS

=head2 generate_one

 generate method-chained classes for particular api

   $self->generate_one('calendar');

 or

  $self->generate_one({ api => 'calendar', version => 'v3' });

=head2 generate_all

 generate method-chained classes for all APIs

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
