#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Deflator::Meta::Role::Attribute;
{
  $MooseX::Attribute::Deflator::Meta::Role::Attribute::VERSION = '2.2.2';
}

# ABSTRACT: Attribute meta role to support deflation
use Moose::Role;
use Try::Tiny;
use Eval::Closure;
use Devel::PartialDump;
use MooseX::Attribute::Deflator;
my $REGISTRY = MooseX::Attribute::Deflator->get_registry;
no MooseX::Attribute::Deflator;

has is_deflator_inlined => ( is => 'rw', isa => 'Bool', default => 0 );
has is_inflator_inlined => ( is => 'rw', isa => 'Bool', default => 0 );

sub _inline_deflator {
    my $self = shift;
    my $role = Moose::Meta::Role->create_anon_role;
    foreach my $type (qw(deflator inflator)) {
        my $find        = "find_$type";
        my $method      = $type eq 'deflator' ? 'deflate' : 'inflate';
        my $tc          = $self->type_constraint;
        my $slot_access = $self->_inline_instance_get('$_[1]');
        my $has_value   = $self->_inline_instance_has('$_[1]');
        my @check_lazy  = $self->_inline_check_lazy(
            '$_[1]',          '$type_constraint',
            '$type_coercion', '$type_message',
        );
        my @deflator = $tc
            ? do {
            ( $tc, undef, my $inline ) = $REGISTRY->$find($tc);
            next unless $inline;
            my $find_sub;
            $find_sub = sub {
                my $type_constraint = shift;
                my @tc              = $REGISTRY->$find($type_constraint);
                return join( "\n",
                    'my ($tc, $via) = $registry->find_' 
                        . $type
                        . '(Moose::Util::TypeConstraints::find_type_constraint("'
                        . quotemeta($type_constraint) . '"));',
                    'my ($attr, $obj, @rest) = @_;',
                    '$via->($attr, $tc, sub { $attr->deflate($obj, @rest) });'
                ) unless ( $tc[2] );
                return $tc[2]->( $self, $tc[0], $find_sub );
            };
            $inline->( $self, $tc, $find_sub );
            }
            : '$value';
        @deflator = (
            'my $deflated = eval {',
            @deflator,
            '};',
            'if($@) {',
            'Moose->throw_error("Failed to ' 
                . $method
                . ' value " . Devel::PartialDump->new->dump($value) . " ('
                . $tc->name
                . '): $@");',
            '}',
            'return $deflated;',
        ) if ($tc);
        my @code = ( 'sub {', 'my $value = $_[2];' );
        if ( $type eq 'deflator' ) {
            push( @code,
                'unless(defined $_[2]) {',
                @check_lazy,
                "return undef unless($has_value);",
                '$value = ' . $slot_access . ';', '}', );
        }
        $role->add_method(
            $method => eval_closure(
                environment => {
                    %{ $self->_eval_environment },
                    '$registry' => \$REGISTRY
                },
                source => join( "\n", @code, @deflator, '}' )
            )
        );
        $type eq 'deflator'
            ? $self->is_deflator_inlined(1)
            : $self->is_inflator_inlined(1);
    }
    Moose::Util::apply_all_roles( $self, $role );
}

sub deflate {
    my ( $self, $obj, $value, $constraint, @rest ) = @_;
    $value = $self->get_value($obj) unless ( defined $value );
    return undef unless ( defined $value );
    $constraint ||= $self->type_constraint;
    return $value unless ($constraint);
    return $value
        unless ( ( $constraint, my $via )
        = $REGISTRY->find_deflator($constraint) );
    my $return;
    try {
        $return = $via->(
            $self, $constraint, sub { $self->deflate( $obj, @_ ) },
            $obj, @rest
        ) for ($value);
    }
    catch {
        my $dump = Devel::PartialDump->new->dump($value);
        Moose->throw_error(
            qq{Failed to deflate value $dump (${\($constraint->name)}): $_});
    };
    return $return;
}

sub inflate {
    my ( $self, $obj, $value, $constraint, @rest ) = @_;
    return undef unless ( defined $value );
    $constraint ||= $self->type_constraint;
    return $value unless ($constraint);
    return $value
        unless ( ( $constraint, my $via )
        = $REGISTRY->find_inflator($constraint) );
    my $return;
    try {
        $return = $via->(
            $self, $constraint, sub { $self->inflate( $obj, @_ ) },
            $obj, @rest
        ) for ($value);
    }
    catch {
        die
            qq{Failed to inflate value "$value" (${\($constraint->name)}): $_};
    };
    return $return;
}

sub has_deflator {
    my $self = shift;
    return unless ( $self->has_type_constraint );
    my @tc = $REGISTRY->find_deflator( $self->type_constraint, 'norecurse' );
    return @tc ? 1 : 0;
}

sub has_inflator {
    my $self = shift;
    return unless ( $self->has_type_constraint );
    my @tc = $REGISTRY->find_inflator( $self->type_constraint, 'norecurse' );
    return @tc ? 1 : 0;
}

after install_accessors => \&_inline_deflator if ( $Moose::VERSION >= 1.9 );

1;



=pod

=head1 NAME

MooseX::Attribute::Deflator::Meta::Role::Attribute - Attribute meta role to support deflation

=head1 VERSION

version 2.2.2

=head1 SYNOPSIS

  package Test;

  use Moose;
  use DateTime;

  use MooseX::Attribute::Deflator;

  deflate 'DateTime', via { $_->epoch };
  inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) };

  no MooseX::Attribute::Deflator;

  has now => ( is => 'rw', 
               isa => 'DateTime', 
               required => 1, 
               default => sub { DateTime->now }, 
               traits => ['Deflator'] );

  package main;
  
  my $obj = Test->new;
  my $attr = $obj->meta->get_attribute('now');
  
  my $deflated = $attr->deflate($obj);
  # $deflated is now a number
  
  my inflated = $attr->inflate($obj, $deflated);
  # $inflated is now a DateTime object

=head1 METHODS

These two methods work basically the same. They look up the type constraint 
which is associated with the attribute and try to find an appropriate
deflator/inflator. If there is no deflator/inflator for the exact type
constraint, the method will bubble up the type constraint hierarchy
until it finds one.

=over 4

=item B<< $attr->deflate($instance) >>

Returns the deflated value of the attribute. It does not change the value
of the attribute.

=item B<< $attr->inflate($instance, $string) >>

Inflates a string C<$string>. This method does not set the value of
the attribute to the inflated value.

=item B<< $attr->has_inflator >>
=item B<< $attr->has_deflator >>

=back

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

