package Mock::Quick::Object::Control;
use strict;
use warnings;
use Mock::Quick::Util;
use Mock::Quick::Object;
use Mock::Quick::Method;

our %META;

sub target { shift->{target} }

sub new {
    my $class = shift;
    my ( $target ) = @_;
    return bless( { target => $target }, $class );
}

sub set_methods {
    my $self = shift;
    my %params = @_;
    for my $key ( keys %params ) {
        $self->target->{$key} = Mock::Quick::Method->new( $params{$key} );
    }
}

sub set_attributes {
    my $self = shift;
    my %params = @_;
    for my $key ( keys %params ) {
        $self->target->{$key} = $params{$key};
    }
}

sub clear {
    my $self = shift;
    for my $field ( @_ ) {
        delete $self->target->{$field};
        delete $self->metrics->{$field};
    }
}

sub strict {
    my $self = shift;
    ($META{$self->target}->{strict}) = @_ if @_;
    return $META{$self->target}->{strict};
}

sub metrics {
    my $self = shift;
    $META{$self->target}->{metrics} ||= {};
    return $META{$self->target}->{metrics};
}

sub _clean {
    my $self = shift;
    delete $META{$self->target};
}

purge_util();

1;

__END__

=head1 NAME

Mock::Quick::Object::Control - Control a mocked object after creation

=head1 DESCRIPTION

Control a mocked object after creation.

=head1 SYNOPSIS

    my $obj = Mock::Quick::Object->new( ... );
    my $control = Mock::Quick::Object::Control->new( $obj );

    $control->set_methods( foo => sub { 'foo' });
    $control->set_attributes( bar => 'baz' );

    # Make an attribute exist so that it can be used for get/set operations.
    $control->set_attributes( empty => undef );

=head1 METHODS

=over 4

=item $control = $CLASS->new( $obj )

=item $control->set_methods( name => sub { ... }, ... )

Set/Create methods

=item $control->set_attributes( name => $val, ... )

Set/Create attributes (simple get/set accessors)

=item $control->clear( $name1, $name2, ... )

Remove attributes/methods.

=item $control->strict( $BOOL )

Enable/Disable strict mode.

=item $data = $control->metrics()

Returns a hash where keys are method names, and values are the number of times
the method has been called. When a method is altered or removed the key is
deleted.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
