package MouseX::NativeTraits::MethodProvider::Num;
use Mouse;

extends qw(MouseX::NativeTraits::MethodProvider);

sub generate_add {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('add', 2, 2, scalar @_);
        }
        $constraint->assert_valid($value);
        $writer->( $instance, $reader->( $instance ) + $value );
    };
}

sub generate_sub {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('sub', 2, 2, scalar @_);
        }
        $constraint->assert_valid($value);
        $writer->( $instance, $reader->( $instance ) - $value );
    };
}

sub generate_mul {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('mul', 2, 2, scalar @_);
        }
        $constraint->assert_valid($value);
        $writer->( $instance, $reader->( $instance ) * $value );
    };
}

sub generate_div {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('div', 2, 2, scalar @_);
        }
        $constraint->assert_valid($value);
        $writer->( $instance, $reader->( $instance ) / $value );
    };
}

sub generate_mod {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;
    my $constraint = $self->attr->type_constraint;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('mod', 2, 2, scalar @_);
        }
        $constraint->assert_valid($value);
        $writer->( $instance, $reader->( $instance ) % $value );
    };
}


sub generate_abs {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance) = @_;
        if(@_ != 1) {
            $self->argument_error('abs', 1, 1, scalar @_);
        }
        $writer->( $instance, abs( $reader->( $instance ) ) );
    };
}

no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

MouseX::NativeTraits::MethodProvider::Num - Provides methods for Num

=head1 DESCRIPTION

This class provides method generators for the C<Number> trait.
See L<Mouse::Meta::Attribute::Custom::Trait::Number> for details.

=head1 METHOD GENERATORS

=over 4

=item generate_add

=item generate_sub

=item generate_mul

=item generate_div

=item generate_mod

=item generate_abs

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>.

=cut

