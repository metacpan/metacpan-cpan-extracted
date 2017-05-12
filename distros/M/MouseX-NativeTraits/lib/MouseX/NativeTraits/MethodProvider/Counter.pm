package MouseX::NativeTraits::MethodProvider::Counter;
use Mouse;

extends qw(MouseX::NativeTraits::MethodProvider);

sub generate_reset {
    my($self)   = @_;
    my $attr    = $self->attr;
    my $writer  = $self->writer;
    my $builder;
    my $default;

    if($attr->has_builder){
        $builder = $attr->builder;
    }
    else {
        $default = $attr->default;
        if(ref $default){
            $builder = $default;
        }
    }

    if(ref $builder){
        return sub {
            my($instance) = @_;
            if(@_ != 1) {
                $self->argument_error('reset', 1, 1, scalar @_);
            }
            $writer->($instance, $instance->$builder());
        };
    }
    else{
        return sub {
            my($instance) = @_;
            if(@_ != 1) {
                $self->argument_error('reset', 1, 1, scalar @_);
            }
            $writer->($instance, $default);
        };
    }
}

sub generate_set{
    my($self)  = @_;
    my $writer = $self->writer;
    return sub {
        if(@_ != 2) {
            $self->argument_error('set', 2, 2, scalar @_);
        }
        $writer->( $_[0], $_[1] )
    };
}

sub generate_inc {
    my($self) = @_;

    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;
    my $name       = $self->attr->name;

    my $optimized_inc = ( $constraint->name eq 'Int'
                            && !$self->attr->trigger );
    return sub {
        my($instance, $value) = @_;
        if(@_ == 1){
            if($optimized_inc) {
                return ++$instance->{$name};
            }
            else {
                $value = 1;
            }
        }
        elsif(@_ == 2){
            $constraint->assert_valid($value);
        }
        else {
            $self->argument_error('inc', 1, 2, scalar @_);
        }
        $instance->$writer($instance->$reader() + $value);
    };
}

sub generate_dec {
    my($self) = @_;

    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;

    return sub {
        my($instance, $value) = @_;
        if(@_ == 1){
            $value = 1;
        }
        elsif(@_ == 2){
            $constraint->assert_valid($value);
        }
        else {
            $self->argument_error('dec', 1, 2, scalar @_);
        }
        $writer->($instance, $reader->($instance) - $value);
    };
}

no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

MouseX::NativeTraits::MethodProvider::Counter - Provides methods for Counter

=head1 DESCRIPTION

This class provides method generators for the C<Counter> trait.
See L<Mouse::Meta::Attribute::Custom::Trait::Counter> for details.

=head1 METHOD GENERATORS

=over 4

=item generate_reset

=item generate_set

=item generate_inc

=item generate_dec

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>

=cut
