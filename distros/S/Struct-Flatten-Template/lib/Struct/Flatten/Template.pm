package Struct::Flatten::Template;

use 5.008;

use Moose;

use version 0.77; our $VERSION = version->declare('v0.1.2');

=head1 NAME

Struct::Flatten::Template - flatten data structures using a template

=head1 SYNOPSIS

  use Struct::Flatten::Template;

  my $tpl = {
    docs => [
      {
         key => \ { column => 0 },
         sum => {
            value => \ { column => 1 },
      }
    ],
  };

  my @data = ( );

  my $hnd = sub {
    my ($obj, $val, $args) = @_;

    my $idx = $args->{_index};
    my $col = $args->{column};

    $data[$idx] ||= [ ];
    $data[$idx]->[$col] = $val;
  };

  my $data = {
    docs => [
      { key => 'A', sum => { value => 10 } },
      { key => 'B', sum => { value =>  4 } },
      { key => 'C', sum => { value => 18 } },
    ],
  };

  my $p = Struct::Flatten::Template->new(
    template => $tpl,
    handler  => $hnd,
  );

=head1 DESCRIPTION

This module is used for "flattening" complex, deeply-nested data
structures, such as those returned by an ElasticSearch aggregation
query.

It is configured with a L</template> that mirrors the data structure,
where some parts of the template contain information how to process
the corresponding parts of the data structure.

=for readme stop

=head1 ATTRIBUTES

=head2 C<template>

This is a template of the data structure.

This is basically a copy of the data structure, with the hash
reference keys and values that you care to extract information from,
using the L</handler>.

To obtain a value, set it to a reference to a hash reference, e.g.

  key => \ { ... }

The keys in the hash reference can be whatever youre application
needs, so long as they are not prefixed with an underscore.

The following special keys are used:

=over

=item C<_index>

This is either the array index of hash key or array item that the
value is associated with.

Note that this is deprecated, and may be removed in future
versions. Use L</_path> instead.

=item C<_sort>

If set, this is a method used to sort hash keys, when the template
refers to a list of hash keys, e.g.

  key => \ {
             _sort => sub { $_[0] cmp $_[1] },
             ...
           }

=item C<_next>

If your template is for hash keys instead of values, then this refers
to the value of that hash key in the template.

It is useful if you want to have your handler fill-in intermediate
values (e.g. gaps in a list of dates) by calling the L</process>
method.

=item C<_path>

This contains an array reference of where in the data structure the
handler is being called.

The array is of the form

  $key1 => $type1, $key2 => $type2, ...

where the keys refer to hash keys or array indices, and the types are
either C<HASH> or C<ARRAY>.

=back

Note: to trigger a callback on hash keys instead of values, use
L<Tie::RefHash>.

Also note that templates for array references assume the first element
applies to all elements of the data structure being processed.

=cut

has 'template' => (
    is       => 'ro',
    isa      => 'Ref',
    required => 1,
);

=head2 C<is_testing>

This is true if the template is being processed using L</test>.

This is useful to extract meta-information from your template,
e.g. field titles.

It is intended to be used from within the L</handler>.

=cut

has 'is_testing' => (
    is       => 'ro',
    isa      => 'Bool',
    traits   => [qw/ Bool /],
    default  => 0,
    init_arg => undef,
    handles  => {
        '_set_is_testing' => 'set',
        '_set_is_live'    => 'unset',
    },
);

=head2 C<ignore_missing>

If true, missing substructures will be ignored and the template will
be processed.  This is useful for setting default values for missing
parts of the structure.

This is true by default.

=cut

has 'ignore_missing' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

=head2 C<handler>

The handler is a reference to a function, e.g.

  sub {
    my ($obj, $value, $args) = @_;

    if ($obj->is_testing) {
      ...
    } else {
      ...
    }
  }

where C<$obj> is the C<Struct::Flatten::Template> object, C<$value> is
the value from the data structure being processed, and C<$args> is a
hash reference from the template.

Note that C<$args> may have additional keys added to it. See L</template>.

Your handler will need to use the information in C<$args> to determine
what to do with the data, e.g., where in a spreadsheet or what column
in a database to it.

=cut

has 'handler' => (
    is     => 'ro',
    isa    => 'Maybe[CodeRef]',
    reader => '_get_handler',
    writer => '_set_handler',
);

around '_get_handler' => sub {
    my ( $orig, $self, $template ) = @_;

    my $type = ref $template;
    return unless $type;

    if ( ( $type eq 'REF' ) && ( ref( ${$template} ) eq 'HASH' ) ) {
        return $self->$orig;
    } else {
        return;
    }
};

=head1 METHODS

=head2 C<run>

  $obj->run( $struct );

Process C<$struct> using the L</template>.

=cut

sub run {
    my ( $self, $struct ) = @_;
    $self->_set_is_live;
    $self->process($struct);
}

=head2 C<test>

  $obj->test();

Test the template. Essentially, it processes the L</template> against
itself.

=cut

sub test {
    my ( $self, $struct ) = @_;
    $self->_set_is_testing;
    $self->process( $self->template );
}

=head2 C<process>

=head2 C<process_HASH>

=head2 C<process_ARRAY>

  $obj->process($struct, $template, $index);

These are low-level methods for processing the template. In general,
you don't need to worry about them unless you are subclassing this.

If you are inserting intermediate values from within your handler,
you should be calling the C<process> method.

=cut

sub process {
    my ( $self, @args ) = @_;

    no warnings 'recursion';

    my $struct   = $args[0];
    my $template = $#args ? $args[1] : $self->template;
    my $index    = $args[2];
    my @path     = @{ $args[3] || [ ] };

    if ( my $type = ref($template) ) {

        if ( my $fn = $self->_get_handler($template) ) {

            my %args = %{ ${$template} };
            $args{_index} = $index if defined $index;
	    $args{_path}  = \@path;

            $fn->( $self, $struct, \%args );

        } else {

            return
                if ( !$self->ignore_missing
                && ( defined $struct )
                && ( $type ne ref($struct) ) );

            my $method = "process_${type}";
            $method =~ s/::/_/g;
            if ( my $fn = $self->can($method) ) {
                $self->$fn( $struct, $template, \@path );
            }
        }
    }
}

sub process_HASH {
    my ( $self, $struct, $template, $path ) = @_;
    foreach my $key ( keys %{$template} ) {

        if ( my $fn = $self->_get_handler($key) ) {

            my %args = %{ ${$key} };
            $args{_index} = 0;
            $args{_next}  = $template->{$key};    # allow gap filling

            my $sort
                = ( !$self->is_testing && $args{_sort} )
                ? $args{_sort}
                : sub {0};

	    my @path = ( @{$path}, undef => 'HASH' );
	    $args{_path} = \@path;

            foreach my $skey ( sort { $sort->( $a, $b ) } keys %{$struct} ) {
                $fn->( $self, $skey, \%args );
		$path[-2] = $skey;
                $self->process( $struct->{$skey}, $template->{$key}, $skey, \@path );
                $args{_index}++;
            }

            last;

        } else {

	    my @path = ( @{$path}, $key => 'HASH' );

            $self->process( $struct->{$key}, $template->{$key}, $key, \@path )
                if $self->ignore_missing || ( exists $struct->{$key} );

        }
    }
}

sub process_ARRAY {
    my ( $self, $struct, $template, $path ) = @_;
    my @path = ( @{$path}, 0 => 'ARRAY' );
    foreach my $s (@{$struct}) {
	$self->process( $s, $template->[0], $path[-2], \@path );
	$path[-2]++;
    }

}

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

=for readme continue

=head1 SEE ALSO

The following alternative modules can be used to flatten hashes:

=over

=item L<Data::Hash::Flatten>

=item L<Hash::Flatten>

=back

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=over

=item Foxtons, Ltd.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut
