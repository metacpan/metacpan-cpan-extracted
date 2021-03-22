package MooX::Params::CompiledValidators;
use Moo::Role;

our $VERSION = '0.02';

use Hash::Util 'lock_hash';
use Params::ValidationCompiler 'validation_for';
use Types::Standard qw( StrMatch Enum HashRef ArrayRef );

requires 'ValidationTemplates';

# local cache for compiled-validators (including our own)
my $_validators = {
    _parameter => validation_for(
        params => [
            {
                type     => StrMatch[ qr{^ \w+ $}x ],
                optional => 0
            },
            {
                type     => Enum [qw( 0 1 )],
                optional => 1,
                default  => 1
            },
            {
                type     => HashRef,
                optional => 1,
                default  => sub { {} }
            },
        ],
        name => 'parameter',
    ),
    _validate_positional_parameters => validation_for(
        params => [
            { type => ArrayRef, optional => 0 },
            { type => ArrayRef, optional => 0 },
        ],
        name => 'validate_positional_parameters',
    ),
    _validate_parameters => validation_for(
        params => [
            { type => HashRef, optional => 0 },
            { type => HashRef, optional => 0 },
        ],
        name => 'validate_parameters',
    ),
};

=head1 NAME

MooX::Params::CompiledValidators - A L<Moo::Role> for using L<Params::ValidationCompiler>.

=head1 SYNOPSIS

    use Moo;
    use Types::Standard qw( Str );
    with 'MooX::Params::CompiledValidators';

    sub any_sub {
        my $self = shift;
        my $arguments = $self->validate_parameters(
            {
                $self->parameter(customer => $self->Required),
            },
            $_[0]
        );
        ...
    }

    # Implement a local version of the ValidationTemplates
    sub ValidationTemplates {
        return {
            customer => { type => Str },
        };
    }

=head1 DESCRIPTION

This role uses L<Params::ValidationCompiler> to create parameter validators on a
per method basis that can be used in the methods of your L<Moo> or L<Moose>
projects.

The objective is to create a single set of validation criteria -
ideally in a seperate role that can be used along side of this role - that can be used
to consistently validate parameters throughout your application.

The validators created by L<Params::ValidationCompiler> are cached after they
are created first time, so they will only be created once.

=head2 Validation-Templates

The validation templates are roughly based on the templates described for
L<Params::ValidationCompiler::validation_for()>.

=head3 Taken from L<Params::ValidationCompiler>

=over

=item I<type> => $type

This argument is passed -as is- to C<validation_for()>.

It can be overridden from the C<extra> parameter in the C<parameter()> method.

=item I<default> => $default

This argument is passed -as is- to C<validation_for()>.

It can be overridden from the C<extra> parameter in the C<parameter()> method.

=back

=head3 Extra feature added

There is support for an extra key (that will not be passed to C<validation_for()>):

=over

=item I<store> => $ref_to_scalar

    my $args = $self->validate_parameters(
        {
            $self->parameter( customer_id => $sef->Required, {store => \my $customer_id} ),
        },
        {@_}
    );
    # $customer_id is a usable value and $args->{customer_id} has the same value

The value should be a reference to a scalar, so we can store the value in that
scalar.

One could argue that using (lexical) variables -instead of addressing keys of a
locked hash- triggers the error caused by a typo at I<compile-time> rather than
at I<run-time>.

B<NOTE>: In order to keep the scope of the variable, where the value is stored,
limited, the C<store> attribute should only be used from the per method override
option C<extra> for C<< $self->parameter() >>.

=back

=head2 $instance->Required

C<validation_for()> uses the attribute C<optional> so this returns C<0>

=head2 $instance->Optional

C<validation_for()> uses the attribute C<optional> so this returns C<1>

=cut

sub Required { 0 }
sub Optional { 1 }

=head2 $instance->validate_parameters(@parameters)

Returns a (locked) hashref with validated parameters or C<die()>s trying...

    my $self = shift;
    my $args = $self->validate_parameters(
        {
            customer_id => { type => Int, optional => 0 },
        },
        { @_ }
    );
    # we can now use $args->{customer_id}

B<NOTE>: C<validate_parameters()> supports the C<store> attribute for
te validation template.

=head3 Parameters

Positional:

=over

=item 1. $validation_templates

A hashref with the parameter-names as keys and the L<validation templates> as values.


=item 2. $values

A hashref with the actual parameter-name/value pairs that need to be validated.

=back

=head3 Responses

=over

=item B<Success> (scalar context, recommended)

A locked hashref.

=item B<Success> (list context, only if you need to manipulate the result)

A list that can be coerced into a hash.

=item B<Error>

Anything L<Params::ValidationCompiler> will throw for invalid values.

=back

=cut

sub validate_parameters {
    my $self = shift;
    my $validate_us = $_validators->{_validate_parameters};
    my ($templates, $values) = $validate_us->(@_);

    # remember where to store values in (scoped) variables
    # should we die() if that value is not a SCALAR-Ref?
    my %store_params = map {
        (exists($templates->{$_}{store}) and ref($templates->{$_}{store}) eq 'SCALAR')
            ? ($_ => delete($templates->{$_}{store}))
            : ()
    } keys %$templates;

    my $called_from = (caller(1))[3];
    my $this_validator = "validation_for>$called_from";

    if (not exists($_validators->{ $this_validator })) {
        $_validators->{$this_validator} = validation_for(
            params => $templates,
            name   => $this_validator,
        );
    }
    my $validator = $_validators->{ $this_validator };

    my %validated = eval { $validator->(%$values) };
    if (my $error = $@) {
        die "Parameter validation error: $error";
    }

    # store values in the their (scoped) variables
    for my $to_store (keys %store_params) {
        ${ $store_params{$to_store} } = $validated{$to_store};
    }

    return wantarray ? (%validated) : lock_hash(%validated);
}

=head2 $instance->validate_positional_parameters(@parameters)

Like C<< $instance->validate_parameters() >>, but now the pairs of I<name>,
I<validation_template> are passed in an arrayref, that is split into lists of
the names and templates. The parameters passed -as an array- will be validated
against the templates-list, and the validated results are combined back into
a hash with name/value pairs. This makes the programming interface almost the
same for both named-parameters and positional-parameters.

Returns a (locked) hashref with validated parameters or C<die()>s trying...

    my $self = shift;
    my $args = $self->validate_positional_parameters(
        [
            customer_id => { type => Int, optional => 0 },
        ],
        [ @_ ]
    );
    # we can now use $args->{customer_id}

B<NOTE>: C<validate_positional_parameters()> supports the C<store> attribute for
te validation template.

=head3 Parameters

Positional:

=over

=item 1. $validation_templates

A arrayref with pairs of parameter-names and L<validation templates>.


=item 2. $values

A arrayref with the actual values that need to be validated.

=back

=head3 Responses

=over

=item B<Success> (list context)

A list that can be coerced into a hash.

=item B<Success> (scalar context)

A locked hashref.

=item B<Error>

Anything L<Params::ValidationCompiler> will throw for invalid values.

=back

=cut

sub validate_positional_parameters {
    my $self = shift;
    my $validate_us = $_validators->{_validate_positional_parameters};
    my ($templates, $data) = $validate_us->(@_);

    my ($positional_templates, $positional_names);
    my @names_and_templates = @$templates;
    while (@names_and_templates) {
        my ($pname, $ptemplate) = splice(@names_and_templates, 0, 2);
        push @$positional_templates, $ptemplate;
        push @$positional_names, $pname;
    }

    # remember where to store values in (scoped) variables
    # should we die() if that value is not a SCALAR-Ref?
    my %store_params;
    for my $i (0 .. $#{$positional_templates}) {
        if (    exists($positional_templates->[$i]{store})
            and ref($positional_templates->[$i]{store}) eq 'SCALAR')
        {
            $store_params{ $positional_names->[$i] } = delete(
                $positional_templates->[$i]{store}
            );
        }
    }

    my $called_from = (caller(1))[3];
    my $this_validator = "validation_for>$called_from";

    if (not exists($_validators->{ $this_validator })) {
        $_validators->{$this_validator} = validation_for(
            params => $positional_templates,
            name   => $this_validator,
        );
    }
    my $validator = $_validators->{ $this_validator };

    my @validated_values = eval { $validator->(@$data) };
    if (my $error = $@) {
        die "Parameter validation error: $error";
    }

    my %validated;
    @validated{ @$positional_names } = @validated_values if @$positional_names;

    # store values in the their (scoped) variables
    for my $to_store (keys %store_params) {
        ${ $store_params{$to_store} } = $validated{$to_store};
    }

    return wantarray ? (%validated) : lock_hash(%validated);
}

=head2 $instance->parameter($name, $required, $extra)

Returns a C<parameter_name>, C<validation_template> pair that can be used in the
C<parameters> argument hashref for
C<Params::ValidationCompiler::validadion_for()>

=head3 Parameters

Positional:

=over

=item 1. $name (Required)

The name of this parameter (it must be a kind of identifier: C<< m{^\w+$} >>)

=item 2. $required (Optional)

One of C<< $class->Required >> or C<< $class->Optional >> but will default to
C<< $class->Required >>.

=item 3. $extra (Optional)

This optional HashRef can contain the fields supported by the C<params>
parameter of C<validation_for()>, even overriding the ones set by the C<<
$class->ValidationTemplates() >> for this C<$name> - although C<optional> is set
by the previous parameter in this sub.

This parameter is mostly used for the extra feature to pass a lexically scoped
variable to store the value in:

    $self->param(
        this_param => $self->Required,
        { store => \my $this_param },
    )

=back

=head3 Responses

=over

=item B<Success>

A list of C<$parameter_name> and C<$validation_template>.

    (this_parm => { optional => 0, store => \my $this_param })

=back

=cut

sub parameter {
    my $self = shift;
    my $validate_us = $_validators->{_parameter};
    my ($name, $optional, $extra) = $validate_us->(@_);

    my $template = exists($self->ValidationTemplates->{$name})
        ? $self->ValidationTemplates->{$name}
        : { };

    my $final_template = {
        %$template,
        ($extra ? %$extra : ()),
        optional => $optional,
    };
    return ($name => $final_template);
}

use namespace::autoclean;
1;

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

(c) MMXXI - Abe Timmerman <abeltje@cpan.org>

=cut
