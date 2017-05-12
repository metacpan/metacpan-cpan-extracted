package MouseX::NativeTraits::MethodProvider::HashRef;
use Mouse;

extends qw(MouseX::NativeTraits::MethodProvider);

sub generate_keys {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('keys', 1, 1, scalar @_);
        }
        return keys %{ $reader->( $_[0] ) };
    };
}

sub generate_sorted_keys {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('sorted_keys', 1, 1, scalar @_);
        }
        return sort keys %{ $reader->( $_[0] ) };
    };
}

sub generate_values {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('values', 1, 1, scalar @_);
        }
        return values %{ $reader->( $_[0] ) };
    };
}

sub generate_kv {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('kv', 1, 1, scalar @_);
        }
        my $hash_ref = $reader->( $_[0] );
        return map { [ $_ => $hash_ref->{$_} ] } keys %{ $hash_ref };
    };
}

sub generate_elements {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('elements', 1, 1, scalar @_);
        }
        return %{ $reader->( $_[0] ) };
    };
}

sub generate_count {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('count', 1, 1, scalar @_);
        }
        return scalar keys %{ $reader->( $_[0] ) };
    };
}

sub generate_is_empty {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('is_empty', 1, 1, scalar @_);
        }
        return scalar(keys %{ $reader->( $_[0] ) }) == 0;
    };
}

sub generate_exists {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my($instance, $key) = @_;
        if(@_ != 2) {
            $self->argument_error('exists', 2, 2, scalar @_);
        }
        defined($key)
            or $self->meta->throw_error(
                "Hash keys passed to exists must be defined" );
        return exists $reader->( $instance )->{ $key };
    }
}

sub generate_defined {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my($instance, $key) = @_;
        if(@_ != 2) {
            $self->argument_error('defined', 2, 2, scalar @_);
        }
        defined($key)
            or $self->meta->throw_error(
                "Hash keys passed to defined must be defined" );
        return defined $reader->( $instance )->{ $key };
    }
}

__PACKAGE__->meta->add_method(generate_get => \&generate_fetch);
sub generate_fetch {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ < 2) {
            $self->argument_error('get', 2, undef, scalar @_);
        }

        my $instance = shift;
        foreach my $key(@_) {
            defined($key)
                or $self->meta->throw_error(
                    "Hash keys passed to get must be defined" );
        }

        if ( @_ == 1 ) {
            return $reader->( $instance )->{ $_[0] };
        }
        else {
            return @{ $reader->($instance) }{@_};
        }
    };
}


__PACKAGE__->meta->add_method(generate_set => \&generate_store);
sub generate_store {
    my($self) = @_;

    my $reader     = $self->reader;
    my $writer     = $self->writer;

    my $constraint = $self->attr->type_constraint;
    my $trigger    = $self->attr->trigger;

    return sub {
        my ( $instance, @kv ) = @_;
        if(@_ < 2) {
            $self->argument_error('set', 2, undef, scalar @_);
        }

        my $hash_ref   = $reader->($instance);
        my %new_value = %{ $hash_ref }; # make a working copy
        my @ret_value;
        while (my ($key, $value) = splice @kv, 0, 2 ) {
            defined($key)
                or $self->meta->throw_error(
                    "Hash keys passed to set must be defined" );
            push @ret_value, $new_value{$key} = $value; # change
        }

        $constraint->assert_valid(\%new_value) if defined $constraint;

        %{ $hash_ref } = %new_value; # commit
        $trigger->($instance) if defined $trigger;

        return wantarray ? @ret_value : $ret_value[-1];
    };
}

sub generate_accessor {
    my($self) = @_;

    my $reader     = $self->reader;
    my $writer     = $self->writer;

    my $constraint = $self->attr->type_constraint;
    my $trigger    = $self->attr->trigger;

    return sub {
        my($instance, $key, $value) = @_;;

        if ( @_ == 2 ) {    # reader
            defined($key)
                or $self->meta->throw_error(
                    "Hash keys passed to accessor must be defined" );
            return $reader->($instance)->{ $key };
        }
        elsif ( @_ == 3 ) {    # writer
            defined($key) or $self->meta->throw_error(
                    "Hash keys passed to accessor must be defined" );

            my $hash_ref  = $reader->($instance);
            my %new_value = %{ $hash_ref };
            $new_value{$key} = $value;
            $constraint->assert_valid(\%new_value) if defined $constraint;
            %{ $hash_ref } = %new_value;
            $trigger->($instance) if defined $trigger;
        }
        else {
            $self->argument_error('accessor', 2, 3, scalar @_);
        }
    };
}

sub generate_clear {
    my($self) = @_;

    my $reader  = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('clear', 1, 1, scalar @_);
        }
        %{ $reader->( $_[0] ) } = ();
    };
}

sub generate_delete {
    my($self) = @_;

    my $reader  = $self->reader;
    my $trigger = $self->attr->trigger;

    return sub {
        if(@_ < 2) {
            $self->argument_error('delete', 2, undef, scalar @_);
        }
        my $instance = shift;

        my @r = delete @{ $reader->($instance) }{@_};
        $trigger->($instance) if defined $trigger;
        return wantarray ? @r : $r[-1];
    };
}

sub generate_for_each_key {
    my($self) = @_;

    my $reader = $self->reader;

    return sub {
        my($instance, $block) = @_;

        if(@_ != 2) {
            $self->argument_error('for_each_key', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to for_each_key must be a code reference");

        foreach (keys %{$reader->($instance)}) { # intentional use of $_
            $block->($_);
        }

        return $instance;
    };
}

sub generate_for_each_value {
    my($self) = @_;

    my $reader = $self->reader;

    return sub {
        my($instance, $block) = @_;

        if(@_ != 2) {
            $self->argument_error('for_each_value', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to for_each_value must be a code reference");

        foreach (values %{$reader->($instance)}) { # intentional use of $_
            $block->($_);
        }

        return $instance;
    };
}

sub generate_for_each_pair {
    my($self) = @_;

    my $reader     = $self->reader;

    return sub {
        my($instance, $block) = @_;

        if(@_ != 2) {
            $self->argument_error('for_each_pair', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to for_each_pair must be a code reference");

        my $hash_ref = $reader->($instance);
        foreach my $key(keys %{$hash_ref}){
            $block->($key, $hash_ref->{$key});
        }

        return $instance;
    };
}


no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

MouseX::NativeTraits::MethodProvider::HashRef - Provides methods for HashRef

=head1 DESCRIPTION

This class provides method generators for the C<Hash> trait.
See L<Mouse::Meta::Attribute::Custom::Trait::Hash> for details.

=head1 METHOD GENERATORS

=over 4

=item generate_keys

=item generate_sorted_keys

=item generate_values

=item generate_kv

=item generate_elements

=item generate_count

=item generate_is_empty

=item generate_exists

=item generate_defined

=item generate_fetch

=item generate_get

The same as C<generate_fetch>.

=item generate_store

=item generate_set

The same as C<generate_store>.

=item generate_accessor

=item generate_clear

=item generate_delete

=item generate_for_each_key

=item generate_for_each_value

=item generate_for_each_pair

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>

=cut
