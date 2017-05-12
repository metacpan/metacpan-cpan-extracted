package MouseX::NativeTraits::MethodProvider::Str;
use Mouse;
use Mouse::Util::TypeConstraints ();

extends qw(MouseX::NativeTraits::MethodProvider);

sub generate_append {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('append', 2, 2, scalar @_);
        }
        defined($value) or $self->meta->throw_error(
            "The argument passed to append must be a string");
        $writer->( $instance, $reader->( $instance ) . $value );
    };
}

sub generate_prepend {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, $value) = @_;
        if(@_ != 2) {
            $self->argument_error('prepend', 2, 2, scalar @_);
        }
        defined($value) or $self->meta->throw_error(
            "The argument passed to prepend must be a string");
        $writer->( $instance, $value . $reader->( $instance ) );
    };
}

sub generate_replace {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my( $instance, $regexp, $replacement ) = @_;
        if(@_ != 3) {
            $self->argument_error('replace', 3, 3, scalar @_);
        }
        ( Mouse::Util::TypeConstraints::Str($regexp)
            || Mouse::Util::TypeConstraints::RegexpRef($regexp) )
            or $self->meta->throw_error(
                "The first argument passed to replace must be a string"
                . " or regexp reference");
        my $v = $reader->( $instance );

        if ( ref($replacement) eq 'CODE' ) {
            $v =~ s/$regexp/$replacement->()/e;
        }
        else {
            Mouse::Util::TypeConstraints::Str($replacement)
                or $self->meta->throw_error(
                    "The second argument passed to replace must be a string"
                    . " or code reference");
            $v =~ s/$regexp/$replacement/;
        }

        $writer->( $instance, $v );
    };
}

sub generate_replace_globally {
    my($self) = @_;
    my $reader = $self->reader;
    my $writer = $self->writer;

    return sub {
        my( $instance, $regexp, $replacement ) = @_;
        if(@_ != 3) {
            $self->argument_error('replace_globally', 3, 3, scalar @_);
        }
        ( Mouse::Util::TypeConstraints::Str($regexp)
            || Mouse::Util::TypeConstraints::RegexpRef($regexp) )
            or $self->meta->throw_error(
                "The first argument passed to replace_globally must be a string"
                . " or regexp reference");
        my $v = $reader->( $instance );

        if ( ref($replacement) eq 'CODE' ) {
            $v =~ s/$regexp/$replacement->()/eg;
        }
        else {
            Mouse::Util::TypeConstraints::Str($replacement)
                or $self->meta->throw_error(
                    "The second argument passed to replace must be a string"
                    . " or code reference");
            $v =~ s/$regexp/$replacement/g;
        }

        $writer->( $instance, $v );
    };
}

sub generate_match {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my($instance, $regexp) = @_;
        if(@_ != 2) {
            $self->argument_error('match', 2, 2, scalar @_);
        }
        ( Mouse::Util::TypeConstraints::Str($regexp)
            || Mouse::Util::TypeConstraints::RegexpRef($regexp) )
            or $self->meta->throw_error(
                "The argument passed to match must be a string"
                . " or regexp reference");
        $reader->( $instance ) =~ $regexp;
    };
}

sub generate_chop {
    my($self) = @_;
    my $reader = $self->reader;
    my $writer = $self->writer;

    return sub {
        my($instance) = @_;
        if(@_ != 1) {
            $self->argument_error('chop', 1, 1, scalar @_);
        }
        my $v = $reader->( $instance );
        my $r = chop($v);
        $writer->( $instance, $v );
        return $r;
    };
}

sub generate_chomp {
    my($self) = @_;
    my $reader = $self->reader;
    my $writer = $self->writer;

    return sub {
        my($instance) = @_;
        if(@_ != 1) {
            $self->argument_error('chomp', 1, 1, scalar @_);
        }
        my $v = $reader->( $instance );
        my $r = chomp($v);
        $writer->( $instance, $v );
        return $r;
    };
}

sub generate_inc {
    my($self) = @_;
    my $reader = $self->reader;
    my $writer = $self->writer;

    return sub {
        my($instance) = @_;
        if(@_ != 1) {
            $self->argument_error('inc', 1, 1, scalar @_);
        }
        my $v = $reader->( $instance );
        $v++;
        $writer->( $instance, $v );
    };
}

sub generate_clear {
    my($self) = @_;
    my $writer = $self->writer;

    return sub {
        my($instance) = @_;
        if(@_ != 1) {
            $self->argument_error('clear', 1, 1, scalar @_);
        }
        $writer->( $instance, '' );
    };
}

sub generate_length {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('length', 1, 1, scalar @_);
        }
        return length( $reader->($_[0]) );
    };
}

sub generate_substr {
    my($self) = @_;
    my $reader = $self->reader;
    my $writer = $self->writer;

    return sub {
        my($instance, $offset, $length, $replacement) = @_;
        if(@_ < 2 or @_ > 4) {
            $self->argument_error('substr', 2, 4, scalar @_);
        }

        my $v = $reader->($instance);

        Mouse::Util::TypeConstraints::Int($offset)
            or $self->meta->throw_error(
                "The first argument passed to substr must be an integer");

        if(defined $length) {
            Mouse::Util::TypeConstraints::Int($length)
                or $self->meta->throw_error(
                    "The second argument passed to substr must be an integer");
        }
        else {
            $length = length($v);
        }

        my $ret;
        if ( defined $replacement ) {
            Mouse::Util::TypeConstraints::Str($replacement)
                or $self->meta->throw_error(
                    "The third argument passed to substr must be a string");
            $ret = substr( $v, $offset, $length, $replacement );
            $writer->( $instance, $v );
        }
        else {
            $ret = substr( $v, $offset, $length );
        }

        return $ret;
    };
}

no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

MouseX::NativeTraits::MethodProvider::Str - Provides methods for Str

=head1 DESCRIPTION

This class provides method generators for the C<String> trait.
See L<Mouse::Meta::Attribute::Custom::Trait::String> for details.

=head1 METHOD GENERATORS

=over 4

=item generate_append

=item generate_prepend

=item generate_replace

=item generate_replace_globally

=item generate_match

=item generate_chop

=item generate_chomp

=item generate_inc

=item generate_clear

=item generate_length

=item generate_substr

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>.

=cut

