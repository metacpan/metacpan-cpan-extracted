package Params::Profile;

use strict;
use warnings;
use Params::Profile::Data_FormValidator;
use Params::Profile::Params_Check;

use base qw/Class::Data::Inheritable/;

our $VERSION = '0.12';

use constant NO_ARGS => {};
use constant NO_PROFILE => undef;

my %Cache;
my $Mod_DV   = __PACKAGE__ . '::Data_FormValidator';
my $Mod_PC   = __PACKAGE__ . '::Params_Check';

__PACKAGE__->mk_classdata(qw/Profiles/);

__PACKAGE__->Profiles({});

=head1 NAME

Params::Profile - module for registering Parameter profiles

=head1 SYNOPSIS

    package Foo::Bar;

    use Params::Profile;

    ### Single profile
    Params::Profile->register_profile(
                    'method'    => 'subroto',
                    'profile'   => {
                                testkey1 => { required => 1 },
                                testkey2 => {
                                        required => 1,
                                        allow => qr/^\d+$/,
                                    },
                                testkey3 => {
                                        allow => qr/^\w+$/,
                                    },
                                },
                );

    sub subroto {
        my (%params) = @_;

        return unlesss Params::Profile->validate('params' => \%params);
        ### DO SOME STUFF HERE ...
    }

    my $profile = Params::Profile->get_profile('method' => 'subroto');

    ### Multiple Profile
    Params::Profile->register_profile(
                    'method'    => 'subalso',
                    'profile'   => [
                                    'subroto',
                                    {
                                    testkey4 => { required => 1 },
                                    testkey5 => {
                                            required => 1,
                                            allow => qr/^\d+$/,
                                        },
                                    testkey6 => {
                                            allow => qr/^\w+$/,
                                        },
                                    },
                                ],
                );


    sub subalso {
        my (%params) = @_;

        ### Checks parameters agains profile of subroto and above registered
        ### profile
        return unlesss Params::Profile->validate('params' => \%params);

        ### DO SOME STUFF HERE ...
    }


=head1 DESCRIPTION

Params::Profile provides a mechanism for a centralised Params::Check or a
Data::FormValidater profile. You can bind a profile to a class::subroutine,
then, when you are in a subroutine you can simply call
Params::Profile->check($params) of Params::Profile->validate($params) to
validate against this profile. Validate will return true or false on
successfull or failed validation. Check will return what C<Data::FormValidator>
or C<Params::Check> would return. (For C<Params::Check> this is simply a hash
with the validated parameters , for C<Data::FormValidator>, this is a
C<Data::FormValidator::Results> object)

=head1 Object Methods

=head2 Params::Profile->register_profile('method' => $method, 'profile' =>
$profile [, caller => $callerclass )

Register a new profile for method for the called-from caller class. Instead of
a profile, you could give a STRING containing the method from which you want to
use the profile...or simpler saying: make an alias to a profile. You can also
give an ARRAYREF containing both strings (defining the aliases) and HASHREFS,
defining profiles which then will be combined (See second example in SYNOPSYS).
When you provide the optional caller option, you define the class where the
given method is defined.

=cut

sub register_profile {
    my ($class, %args) = @_;
    my ($method, $new_profiles, $caller, @profiles, $type);

    my $tpl = {
            method  => {
                            required    => 1,
                            store       => \$method,
                    },
            profile => {
                            required    => 1,
                            ### Allow hashref or plain text defining alias,
                            allow       => sub {
                                            UNIVERSAL::isa($_[0], 'HASH') ||
                                            UNIVERSAL::isa($_[0], 'ARRAY') ||
                                            !ref($_[0]) || $_[0] eq NO_ARGS
                                            || $_[0] eq NO_PROFILE
                                        },
                            store       => \$new_profiles,
                    },
            'caller' => {
                            required    => 0,
                            allow       => qr/^[\w0-9:-]+$/,
                            default     => $class->_get_caller_class,
                            store       => \$caller,
                    },
        };

    Params::Check::check($tpl, \%args) or (
            $class->_raise_warning('Failed validating input parameters'),
            return
        );

    my $subname = $class->_full_method_name( $method, $caller );

    ### Create an array of profiles for easyer checking
    @profiles = UNIVERSAL::isa($new_profiles, 'ARRAY') ? @$new_profiles : ($new_profiles);

    ### Check given profiles
    for (my $i=0; $i<@profiles; $i++) {
        ### Check if alias exists
        if (!ref($profiles[$i]) && !__PACKAGE__->Profiles->{
                $class->_full_method_name( $profiles[$i], $caller )
            }
        ) {
            $class->_raise_warning (
                    'Cannot alias (' . $subname . ') to missing profile: '
                    . $class->_full_method_name( $profiles[$i], $caller ));
            return;
        }

        ### Check if profiles match the chosen validator system (DV or PC)
        if (ref($profiles[$i])) {
            if (
                UNIVERSAL::isa($profiles[$i]->{required},'ARRAY') ||
                UNIVERSAL::isa($profiles[$i]->{optional},'ARRAY')
            ) {
                (
                    $class->_raise_warning (
                        'Profile type clash for: '
                        . $method
                    ),
                    return
                ) if ($type && $type ne 'dv');
                $type = 'dv';
            } else {
                (
                    $class->_raise_warning (
                        'Profile type clash for: '
                        . $class->_full_method_name($profiles[$i], $caller)
                    ),
                    return
                ) if ($type && $type ne 'pc');
                $type = 'pc';
            }
        }

        ### Set full name on aliases
        $profiles[$i] = $class->_full_method_name(
                                $profiles[$i],
                                $class->_get_caller_class
                            ) if !ref($profiles[$i]);
    }

    ### Joy, all went fine, let's register this profile
    __PACKAGE__->Profiles->{$subname} = {   type => $type,
                                            profiles => \@profiles,
                                        };

    return 1;

}

sub _full_method_name {
    my $class   = shift;
    my $method  = shift;
    my $caller  = shift || $class->_get_caller_class;

    $method = $method =~ /::/
                ? $method
                : join( '::', $caller, $method );

    return $method;
}

=head2 Params::Profile->get_profile( method => $method [, caller => $caller ]);

Returns the profile registered for $method, or when no $method is given,
returns the profile for caller.

=cut

sub get_profile {
    my ($class, %args)  = @_;
    my ($method, $caller);

    my $tpl = {
            method  => {
                            required    => 1,
                            store       => \$method,
                    },
            'caller' => {
                            required    => 0,
                            allow       => qr/^[\w0-9:-]+$/,
                            default     => $class->_get_caller_class,
                            store       => \$caller,
                    },
        };

    Params::Check::check($tpl, \%args) or ($class->_raise_warning('Failed validating input parameters'), return);
    return $class->_get_profile(
            $class->_full_method_name( $method, $caller )
        );
}

=head2 Params::Profile->verify_profiles( \@methods );

Verifies for each method in list, if the profile exists. Returns undef
when it doesn't. Also checks for aliases which point to no existing
profiles.

=cut

sub verify_profiles {
    my $class   = shift;
    my @methods = @_ ? @_ : keys %{ __PACKAGE__->Profiles };

    my $fail;
    for my $method ( @methods ) {
        my $profile = $class->get_profile( method => $method );

        $fail++ unless $profile;

        ### XXX validate the profile?
    }

    return if $fail;
    return 1;
}

sub _get_profile {
    my ($class, $method) = @_;
    my (%profile,@profiles);

    ### No profile exists
    unless ( exists __PACKAGE__->Profiles->{ $method } ) {
        $class->_raise_warning( "No profile for '$method'" );
        return;
    }

    ### Alias of another profile
    if ( !__PACKAGE__->Profiles->{$method}->{type} ) {
        ### return profile of alias
        return $class->_get_profile(
                __PACKAGE__->Profiles->{$method}->{profiles}->[0]
            );
    } else {
        ### Create array of profiles for easyer handling
        push(@profiles, !ref($_) ?
                    $class->_get_profile(
                        $_
                    ) : $_
        ) for (@{ __PACKAGE__->Profiles->{$method}->{'profiles'} });

        ### No alias, return profile
        if (__PACKAGE__->Profiles->{$method}->{type} eq 'dv') {
            return $Mod_DV->get_profile(
                        $method,
                        @profiles,
                    );
        } else {
            return $Mod_PC->get_profile(
                        $method,
                        @profiles,
                    );
        }
    }
    return;
}

=head2 Params::Profile->clear_profiles();

Clear the loaded profiles.

=cut

sub clear_profiles { __PACKAGE__->Profiles({}); return 1; }

=head2 Params::Profile->get_profiles()

Just return a hash containing all the registered profiles, it is in the form:
method => [ \%profile ]

=cut

sub get_profiles { return __PACKAGE__->Profiles; }

=head2 Params::Profile->validate( params => %params [, method => $method ] )

When given an hash of key->value pairs, this sub will check the values against
the loaded profile. Returns true when it validates, otherwise returns false.
It will check against the loaded profile for the given method, or when method
doesn't exist, against the caller

=cut

sub validate {
    my ($class, %args) = @_;
    my ($params, $method);

    my $tpl = {
            'params'  => {
                            required    => 1,
                            store       => \$params,
                    },
            'method' => {
                            required    => 0,
                            allow       => qr/^[\w0-9:-]+$/,
                            default     =>
                                $class->_full_method_name(
                                                $class->_get_caller_method
                                            ),
                            store       => \$method,
                    },
        };

    Params::Check::check($tpl, \%args) or (
            $class->_raise_warning('Failed validating input parameters'),
            return
        );

    my $profile = $class->_get_profile($method) or return;

    ### Data::FormValidator or Params::Check template
    my ($ok, $vclass);
    if (
            UNIVERSAL::isa($profile->{required},'ARRAY') ||
            UNIVERSAL::isa($profile->{optional},'ARRAY')
    ) {
        ### Data::FormValidator
        $ok = $Mod_DV->check($params, %{ $profile })->success;
    } else {
        $ok = Params::Check::check($profile, $params) ? 1 : 0;
    }
    return $ok;
}

=head2 Params::Profile->check( params => %params [, method => $method ] )

When given an hash of key->value pairs, this sub will check the values against
the loaded profile. It will check against the loaded profile for the given
method, or when method doesn't exist, against the caller.

Depending on the used profile, it will return %hash with values for a
Params::Check profile. Or an object Data::FormValidator::Results when the
laoded profile is a Data::FormValidator profile.

=cut

sub check {
    my ($class, %args) = @_;
    my ($params, $method);

    my $tpl = {
            'params'  => {
                            required    => 1,
                            store       => \$params,
                    },
            'method' => {
                            required    => 0,
                            allow       => qr/^[\w0-9:-]+$/,
                            default     =>
                                $class->_full_method_name(
                                                $class->_get_caller_method,
                                            ),
                            store       => \$method,
                    },
        };

    Params::Check::check($tpl, \%args) or (
            $class->_raise_warning('Failed validating input parameters'),
            return
        );

    my $profile = $class->_get_profile($method) or return;

    ### Data::FormValidator or Params::Check template
    my ($ok, $vclass);
    if (
            UNIVERSAL::isa($profile->{required},'ARRAY') ||
            UNIVERSAL::isa($profile->{optional},'ARRAY')
    ) {
        ### Data::FormValidator
        return $Mod_DV->check($params, %{ $profile })
        #return Data::FormValidator->check($params, $profile);
    } else {
        ### Params::Check
        return $Mod_PC->check($params, %{ $profile });
    }
}

sub _raise_warning {
    my ($self, $warning) = @_;
    warn($warning);
}

sub _get_caller_class {  return [caller(1)]->[0]; }

sub _get_caller_method { return caller(2) ? [caller(2)]->[3] : ''; }

1;

=head1 AUTHOR

This module by

Michiel Ootjers E<lt>michiel@cpan.orgE<gt>.

and

Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 ACKNOWLEDGEMENTS

Thanks to Jos Boumans for C<Params::Check>, and the authors of
C<Data::FormValidator>

=head1 COPYRIGHT

This module is
copyright (c) 2002 Michiel Ootjers E<lt>michiel@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut
