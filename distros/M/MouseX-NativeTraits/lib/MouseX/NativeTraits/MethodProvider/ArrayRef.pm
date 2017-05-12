package MouseX::NativeTraits::MethodProvider::ArrayRef;
use Mouse;
use Mouse::Util::TypeConstraints ();

use List::Util ();

extends qw(MouseX::NativeTraits::MethodProvider);

sub generate_count {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        if(@_ != 1) {
            $self->argument_error('count', 1, 1, scalar @_);
        }
        return scalar @{ $reader->( $_[0] ) };
    };
}

sub generate_is_empty {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        if(@_ != 1) {
            $self->argument_error('is_empty', 1, 1, scalar @_);
        }
        return scalar(@{ $reader->( $_[0] ) }) == 0;
    };
}

sub generate_first {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ != 2) {
            $self->argument_error('first', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to first must be a code reference");

        return List::Util::first(\&{$block}, @{ $reader->($instance) });
    };
}

sub generate_any {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ != 2) {
            $self->argument_error('any', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to any must be a code reference");

        foreach (@{ $reader->($instance) }){
            if($block->($_)){
                return 1;
            }
        }
        return 0;
    };
}

sub generate_apply {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ != 2) {
            $self->argument_error('apply', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to apply must be a code reference");

        my @values = @{ $reader->($instance) };
        foreach (@values){
            $block->();
        }
        return @values;
    };
}

sub generate_map {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ != 2) {
            $self->argument_error('map', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to map must be a code reference");

        return map { $block->() } @{ $reader->($instance) };
    };
}

sub generate_reduce {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ != 2) {
            $self->argument_error('reduce', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to reduce must be a code reference");

        our ($a, $b);
        return List::Util::reduce { $block->($a, $b) } @{ $reader->($instance) };
    };
}

sub generate_sort {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ < 1 or @_ > 2) {
            $self->argument_error('sort', 1, 2, scalar @_);
        }

        if (defined $block) {
            Mouse::Util::TypeConstraints::CodeRef($block)
                or $instance->meta->throw_error(
                    "The argument passed to sort must be a code reference");

            return sort { $block->( $a, $b ) } @{ $reader->($instance) };
        }
        else {
            return sort @{ $reader->($instance) };
        }
    };
}

sub generate_sort_in_place {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my ( $instance, $block ) = @_;

        if(@_ < 1 or @_ > 2) {
            $self->argument_error('sort_in_place', 1, 2, scalar @_);
        }

        my $array_ref = $reader->($instance);

        if(defined $block){
            Mouse::Util::TypeConstraints::CodeRef($block)
                or $instance->meta->throw_error(
                    "The argument passed to sort_in_place must be a code reference");
            @{$array_ref} = sort { $block->($a, $b) } @{$array_ref};
        }
        else{
            @{$array_ref} = sort @{$array_ref};
        }

        return $instance;
    };
}


# The sort_by algorithm comes from perlfunc/sort
# See also perldoc -f sort and perldoc -q sort

sub generate_sort_by {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block, $compare ) = @_;

        if(@_ < 1 or @_ > 3) {
            $self->argument_error('sort_by', 1, 3, scalar @_);
        }

        my $array_ref = $reader->($instance);
        my @idx;
        foreach (@{$array_ref}){ # intentinal use of $_
            push @idx, scalar $block->($_);
        }

        # NOTE: scalar(@idx)-1 is faster than $#idx
        if($compare){
            return @{ $array_ref }[
                sort { $compare->($idx[$a], $idx[$b]) }
                    0 .. scalar(@idx)-1
            ];
        }
        else{
            return @{ $array_ref }[
                sort { $idx[$a] cmp $idx[$b] }
                    0 .. scalar(@idx)-1
            ];
        }
    };
}


sub generate_sort_in_place_by {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my ( $instance, $block, $compare ) = @_;

        if(@_ < 1 or @_ > 3) {
            $self->argument_error('sort_by', 1, 3, scalar @_);
        }

        my $array_ref = $reader->($instance);
        my @idx;
        foreach (@{$array_ref}){
            push @idx, scalar $block->($_);
        }

        if($compare){
            @{ $array_ref } = @{ $array_ref }[
                sort { $compare->($idx[$a], $idx[$b]) }
                    0 .. scalar(@idx)-1
            ];
        }
        else{
            @{ $array_ref } = @{ $array_ref }[
                sort { $idx[$a] cmp $idx[$b] }
                    0 .. scalar(@idx)-1
            ];
        }
        return $instance;
    };
}


sub generate_shuffle {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance ) = @_;

        if(@_ != 1) {
            $self->argument_error('shuffle', 1, 1, scalar @_);
        }

        return List::Util::shuffle @{ $reader->($instance) };
    };
}

sub generate_grep {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $block ) = @_;

        if(@_ != 2) {
            $self->argument_error('grep', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::CodeRef($block)
            or $instance->meta->throw_error(
                "The argument passed to grep must be a code reference");

        return grep { $block->() } @{ $reader->($instance) };
    };
}

sub generate_uniq {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance ) = @_;

        if(@_ != 1) {
            $self->argument_error('uniq', 1, 1, scalar @_);
        }

        my %seen;
        my $seen_undef;
        return  grep{
            ( defined($_)
                ? ++$seen{$_}
                : ++$seen_undef
            ) == 1
        } @{ $reader->($instance) };
    };
}

sub generate_elements {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ($instance) = @_;

        if(@_ != 1) {
            $self->argument_error('elements', 1, 1, scalar @_);
        }

        return @{ $reader->($instance) };
    };
}

sub generate_join {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        my ( $instance, $separator ) = @_;

        if(@_ != 2) {
            $self->argument_error('join', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::Str($separator)
            or $instance->meta->throw_error(
                "The argument passed to join must be a string");

        return join $separator, @{ $reader->($instance) };
    };
}

sub generate_push {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, @values) = @_;

        my @new_values = @{ $reader->($instance) };
        push @new_values, @values;
        $writer->($instance, \@new_values); # commit
        return scalar @new_values;
    };
}

sub generate_pop {
    my($self) = @_;
    my $reader = $self->reader;
    return sub {
        if(@_ != 1) {
            $self->argument_error('pop', 1, 1, scalar @_);
        }
        return pop @{ $reader->( $_[0] ) };
    };
}

sub generate_unshift {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, @values) = @_;

        my @new_values = @{ $reader->($instance) };
        unshift @new_values, @values;
        $writer->($instance, \@new_values); # commit
        return scalar @new_values;
    };
}

sub generate_shift {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        if(@_ != 1) {
            $self->argument_error('shift', 1, 1, scalar @_);
        }

        return shift @{ $reader->( $_[0] ) };
    };
}

__PACKAGE__->meta->add_method(generate_get => \&generate_fetch); # alias
sub generate_fetch {
    my($self, $handle_name) = @_;
    my $reader = $self->reader;

    return sub {
        my($instance, $idx) = @_;

        if(@_ != 2) {
            $self->argument_error('get', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::Int($idx)
            or $instance->meta->throw_error(
                "The index passed to get must be an integer");

        return $reader->( $instance )->[ $idx ];
    };
}

__PACKAGE__->meta->add_method(generate_set => \&generate_store); # alias
sub generate_store {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, $idx, $value) = @_;
 
        if(@_ != 3) {
            $self->argument_error('set', 3, 3, scalar @_);
        }

        Mouse::Util::TypeConstraints::Int($idx)
            or $instance->meta->throw_error(
                "The index argument passed to set must be an integer");

        my @new_values = @{ $reader->($instance) };
        $new_values[$idx] = $value;
        $writer->($instance, \@new_values); # commit
        return $value;
    };
}

sub generate_accessor {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, $idx, $value) = @_;


        if ( @_ == 2 ) {    # reader
            Mouse::Util::TypeConstraints::Int($idx)
                or $instance->meta->throw_error(
                    "The index argument passed to accessor must be an integer");

            return $reader->($instance)->[ $idx ];
        }
        elsif ( @_ == 3) {    # writer
            Mouse::Util::TypeConstraints::Int($idx)
                or $instance->meta->throw_error(
                    "The index argument passed to accessor must be an integer");

            my @new_values = @{ $reader->($instance) };
            $new_values[$idx] = $value;
            $writer->($instance, \@new_values); # commit
            return $value;
        }
        else {
            $self->argument_error('accessor', 2, 3, scalar @_);
        }
    };
}

sub generate_clear {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my($instance) = @_;
 
        if(@_ != 1) {
            $self->argument_error('clear', 1, 1, scalar @_);
        }

        @{ $reader->( $instance ) } = ();
        return $instance;
    };
}

__PACKAGE__->meta->add_method(generate_delete => \&generate_remove); # alias
sub generate_remove {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my($instance, $idx) = @_;

        if(@_ != 2) {
            $self->argument_error('delete', 2, 2, scalar @_);
        }

        Mouse::Util::TypeConstraints::Int($idx)
            or $instance->meta->throw_error(
                "The index argument passed to delete must be an integer");

        return splice @{ $reader->( $instance ) }, $idx, 1;
    };
}

sub generate_insert {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my($instance, $idx, $value) = @_;

        if(@_ != 3) {
            $self->argument_error('insert', 3, 3, scalar @_);
        }

        Mouse::Util::TypeConstraints::Int($idx)
            or $instance->meta->throw_error(
                "The index argument passed to insert must be an integer");

        my @new_values = @{ $reader->($instance) };
        splice @new_values, $idx, 0, $value;
        $writer->($instance, \@new_values); # commit
        return $instance;
    };
}

sub generate_splice {
    my($self) = @_;
    my $reader     = $self->reader;
    my $writer     = $self->writer;

    return sub {
        my ( $instance, $idx, $len, @elems ) = @_;

        if(@_ < 2) {
            $self->argument_error('splice', 2, undef, scalar @_);
        }

        Mouse::Util::TypeConstraints::Int($idx)
            or $instance->meta->throw_error(
                "The index argument passed to splice must be an integer");

        if(defined $len) {
            Mouse::Util::TypeConstraints::Int($len)
                or $instance->meta->throw_error(
                    "The length argument passed to splice must be an integer");
        }

        my @new_values = @{ $reader->($instance) };
        my @ret_values = defined($len)
            ? splice @new_values, $idx, $len, @elems
            : splice @new_values, $idx;
        $writer->($instance, \@new_values); # commit
        return wantarray ? @ret_values : $ret_values[-1];
    };
}

sub generate_for_each {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my ( $instance, $block ) = @_;

        foreach my $element(@{ $reader->instance($instance) }){
            $block->($element);
        }
        return $instance;
    };
}

sub generate_for_each_pair {
    my($self) = @_;
    my $reader = $self->reader;

    return sub {
        my ( $instance, $block ) = @_;

        my $array_ref = $reader->($instance);
        for(my $i = 0; $i < @{$array_ref}; $i += 2){
            $block->($array_ref->[$i], $array_ref->[$i + 1]);
        }
        return $instance;
    };
}

no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

MouseX::NativeTraits::MethodProvider::ArrayRef - Provides methods for ArrayRef

=head1 DESCRIPTION

This class provides method generators for the C<Array> trait.
See L<Mouse::Meta::Attribute::Custom::Trait::Array> for details.

=head1 METHOD GENERATORS

=over 4

=item generate_count

=item generate_is_empty

=item generate_first

=item generate_any

=item generate_apply

=item generate_map

=item generate_reduce

=item generate_sort

=item generate_sort_in_place

=item generate_sort_by

=item generate_sort_in_place_by

=item generate_shuffle

=item generate_grep

=item generate_uniq

=item generate_elements

=item generate_join

=item generate_push

=item generate_pop

=item generate_unshift

=item generate_shift

=item generate_fetch

=item generate_get

The same as C<generate_fetch>

=item generate_store

=item generate_set

The same as C<generate_store>

=item generate_accessor

=item generate_clear

=item generate_remove

=item generate_delete

The same as C<generate_remove>. Note that it is different from C<CORE::delete>.

=item generate_insert

=item generate_splice

=item generate_for_each

=item generate_for_each_pair

=back

=head1 SEE ALSO

L<MouseX::NativeTraits>

=cut
