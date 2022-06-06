package MooX::Params::CompiledValidators;
use Moo::Role;

our $VERSION = '0.05';

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
                $self->parameter(customer_id => $self->Required),
            },
            { @_ }
        );
        ...
    }

    # Implement a local version of the ValidationTemplates
    sub ValidationTemplates {
        return {
            customer_id => { type => Str },
        };
    }

=head1 DESCRIPTION

This role uses L<Params::ValidationCompiler> to create parameter validators on a
per method basis that can be used in the methods of your L<Moo> or L<Moose>
projects.

The objective is to create a single set of validation criteria - ideally in a
seperate role that can be used along side of this role - that can be used to
consistently validate parameters throughout your application.

The validators created by L<Params::ValidationCompiler> are cached after they
are created the first time, so they will only be created once.

=head2 Validation-Templates

A validation-template is a structure (HashRef) that
C<Params::ValidationCompiler::validation_for()> uses to validate the parameter
and basically contains three keys:

=over

=item B<type>

C<Params::ValidationCompiler> supports a number of type systems, see their documentation.

=item B<default>

Define a default value for this parameter, either a simple scalar or a code-ref
that returns a more complex value.

=item B<optional>

By default false, required parameters are preferred by C<Params::ValidationCompiler>

=back

=head2 The I<required> C<ValidationTemplates()> method

The objective of this module (Role) is to standardise parameter validation by
defining a single set of Validation Templates for all the parameters in a project.
This is why the C<MooX::Params::CompiledValidators> role B<< C<requires> >> a
C<ValidationTemplates> method in its consuming class. The C<ValidationTemplates>
method is needed for the C<parameter()> method that is also supplied by this
role.

This could be as simple as:

    package MyTemplates;
    use Moo::Role;

    use Types::Standard qw(Str);
    sub ValidationTemplates {
        return {
            customer_id => { type => Str },
            username    => { type => Str },
        };
    }

=head2 The C<Required()> method

C<validation_for()> uses the attribute C<optional> so this returns C<0>

=head2 The C<Optional> method

C<validation_for()> uses the attribute C<optional> so this returns C<1>

=cut

sub Required { 0 }
sub Optional { 1 }

=head2 The C<validate_parameters()> method

Returns a (locked) hashref with validated parameters or C<die()>s trying...

Given:

    use Moo;
    with 'MooX::Params::CompiledValidators';

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_parameters(
            {
                customer_id => { type => Str, optional => 0 },
                username    => { type => Str, optional => 0 },
            },
            { @_ }
        );
        return {
            customer => $args->{customer_id},
            username => $args->{username},
        };
    }

One would call this as:

    my $user_info = $instance->show_user_info(
        customer_id => 'Blah42',
        username    => 'blah42',
    );

=head3 Parameters

Positional:

=over

=item 1. C<$validation_templates>

A hashref with the parameter-names as keys and the L</Validation-Templates> as values.


=item 2. C<$values>

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
        _sniff_it($error);
    }

    # store values in the their (scoped) variables
    for my $to_store (keys %store_params) {
        ${ $store_params{$to_store} } = $validated{$to_store};
    }

    return wantarray ? (%validated) : lock_hash(%validated);
}

=head2 The C<validate_positional_parameters()> method

Like C<< $instance->validate_parameters() >>, but now the pairs of I<name>,
I<validation-template> are passed in an arrayref, that is split into lists of
the names and templates. The parameters passed -as an array- will be validated
against the templates-list, and the validated results are combined back into
a hash with name/value pairs. This makes the programming interface almost the
same for both named-parameters and positional-parameters.

Returns a (locked) hashref with validated parameters or C<die()>s trying...

Given:

    use Moo;
    with 'MooX::Params::CompiledValidators';

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_positional_parameters(
            [
                customer_id => { type => Str, optional => 0 },
                username    => { type => Str, optional => 0 },
            ],
            \@_
        );
        return {
            customer => $args->{customer_id},
            username => $args->{username},
        };
    }

One would call this as:

    my $user_info = $instance->show_user_info('Blah42', 'blah42');

=head3 Parameters

Positional:

=over

=item 1. C<$validation_templates>

A arrayref with pairs of parameter-names and L<validation templates>.


=item 2. C<$values>

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
        _sniff_it($error);
    }

    my %validated;
    @validated{ @$positional_names } = @validated_values if @$positional_names;

    # store values in the their (scoped) variables
    for my $to_store (keys %store_params) {
        ${ $store_params{$to_store} } = $validated{$to_store};
    }

    return wantarray ? (%validated) : lock_hash(%validated);
}

=head2 The C<parameter()> method

Returns a C<parameter_name>, C<validation_template> pair that can be used in the
C<parameters> argument hashref for
C<Params::ValidationCompiler::validadion_for()>

=head3 Parameters

Positional:

=over

=item 1. C<$name> (I<Required>)

The name of this parameter (it must be a kind of identifier: C<< m{^\w+$} >>)

=item 2. C<$required> (I<Optional>)

One of C<< $class->Required >> or C<< $class->Optional >> but will default to
C<< $class->Required >>.

=item 3. C<$extra> (I<Optional>)

This optional HashRef can contain the fields supported by the C<params>
parameter of C<validation_for()>, even overriding the ones set by the C<<
$class->ValidationTemplates() >> for this C<$name> - although C<optional> is set
by the previous parameter in this sub.

This parameter is mostly used for the extra feature to pass a lexically scoped
variable via L<store|/"the extra store attribute">.

=back

=head3 Responses

=over

=item B<Success>

A list of C<$parameter_name> and C<$validation_template>.


    (this_parm => { optional => 0, type => Str, store => \my $this_param })


=back

=head3 NOTE on "Unknown" parameters

Whenever C<< $self->parameter() >> is called with a parameter-name that doesn't
resolve to a template in the C<ValidationTemplates()> hash, a default "empty"
template is produced. This will mean that there will be no validation on that
value, although one could pass one as the third parameter:

    use Moo;
    use Types::Standard qw( StrMatch );
    with qw(
        MyTemplates
        MooX::Params::CompiledValidators
    );

    sub show_user_info {
        my $self = shift;
        my $args = $self->validate_parameters(
            {
                $self->parameter(customer_id => $self->Required),
                $self->parameter(
                    email => $self->Required,
                    { type => StrMatch[ qr{^ [-.\w]+ @ [-.\w]+ $}x ] },
                ),
            },
            { @_ }
        );
        return {
            customer => $args->{customer_id},
            email    => $args->{email},
        };
    }

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

=begin private

=head2 _sniff_it($message)

Tailor made exception handler.

=end private

=cut

sub _sniff_it {
    my ($message) = @_;
    my ($filename, $line) = (caller(1))[1, 2];
    my $subroutine = (caller(2))[3];

    die sprintf('Error in %s (%s:%u): %s', $subroutine, $filename, $line, $message);
}

use namespace::autoclean;
1;

=head2 The extra C<store> attribute

Both C<validate_parameters()> and C<validate_positional_parameters> support the
extra C<store> attribute in a validation template that should be a
scalar-reference where we store the value after successful validation.

One can pick and mix with validation templates:

    use Moo;
    use Types::Standard qw( StrMatch );
    with qw(
        MyTemplates
        MooX::Params::CompiledValidators
    );

    sub show_user_info {
        my $self = shift;
        $self->validate_parameters(
            {
                $self->parameter(customer_id => $self->Required, {store => \my $customer_id),
                email => {
                    type     => StrMatch[ qr{^ [-.\w]+ @ [-.\w]+ $}x ],
                    optional => 0,
                    store    => \my $email
                },
            },
            { @_ }
        );
        return {
            customer => $customer_id,
            email    => $email,
        };
    }

One would call this as:

    my $user_info = $instance->show_user_info(
        customer_id => 'Blah42',
        email       => 'blah42@some.tld',
    );

One could argue that using (lexical) variables -instead of addressing keys of a
locked hash- triggers the error caused by a typo at I<compile-time> rather than
at I<run-time>.

B<NOTE>: In order to keep the scope of the variable, where the value is stored,
limited, the C<store> attribute should only be used from the per method override
option C<extra> for C<< $self->parameter() >>.

=head1 AUTHOR

E<copy> MMXXI - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
