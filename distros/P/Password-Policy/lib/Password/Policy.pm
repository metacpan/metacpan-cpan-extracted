package Password::Policy;
$Password::Policy::VERSION = '0.04';
# ABSTRACT: Make managing multiple password strength profiles easy

use strict;
use warnings;

use Class::Load;
use Clone qw/clone/;
use Config::Any;
use Try::Tiny;

use Password::Policy::Exception;
use Password::Policy::Exception::EmptyPassword;
use Password::Policy::Exception::InvalidAlgorithm;
use Password::Policy::Exception::InvalidProfile;
use Password::Policy::Exception::InvalidRule;
use Password::Policy::Exception::NoAlgorithm;
use Password::Policy::Exception::ReusedPassword;



sub new {
    my ($class, %args) = @_;

    my $config_file = $args{config};
    my $previous = $args{previous} || [];

    my $config = Config::Any->load_files({ files => [ $config_file ], use_ext => 1 });
    my $rules = {};

    $config = $config->[0]->{$config_file};
    my @profiles = keys(%{$config});

    my $self = bless {
        _config => $config,
        _rules => $rules,
        _previous => $previous,
        _profiles => \@profiles,
    } => $class;

    foreach my $key (@profiles) {
        $rules->{$key} = $self->_parse_rules($key);
    }

    $self->{_rules} = $rules;
    return $self;
}

sub _parse_rules {
    my ($self, $profile_name) = @_;
    my $rules;

    my $profile = clone $self->config->{$profile_name};
    if(my $parent = delete $profile->{inherit}) {
        $rules = $self->_parse_rules($parent);
    }
    foreach my $key (keys(%{$profile})) {
        if($key eq 'algorithm') {
            $rules->{algorithm} = $profile->{$key};
            next;
        }
        if($rules->{$key}) {
            $rules->{$key} = $profile->{$key} if($profile->{$key} > $rules->{$key});
        } else {
            $rules->{$key} = $profile->{$key};
        }
    }
    return $rules;
}

sub config {
    return (shift)->{_config};
}

sub profiles {
    return (shift)->{_profiles};
}

sub previous {
    return (shift)->{_previous};
}

sub rules {
    my $self = shift;
    my $profile = shift || 'default';
    my $rules = $self->{_rules};
    return $rules->{$profile} || Password::Policy::Exception::InvalidProfile->throw;
}


sub process {
    my ($self, $args) = @_;
    my $password = $args->{password} || Password::Policy::Exception::EmptyPassword->throw;

    my $rules = $self->rules($args->{profile});
    my $algorithm = $rules->{algorithm} || Password::Policy::Exception::NoAlgorithm->throw;
    my $algorithm_args = $rules->{algorithm_args} || {};
    foreach my $rule (sort keys(%{$rules})) {
        next if($rule eq 'algorithm');

        my $rule_class = 'Password::Policy::Rule::' . ucfirst($rule);
        try {
            Class::Load::load_class($rule_class);
        } catch {
            Password::Policy::Exception::InvalidRule->throw;
        };
        my $rule_obj = $rule_class->new($rules->{$rule});
        my $check = $rule_obj->check($password);
        unless($check) {
            # no idea what failed if we didn't get a more specific exception, so
            # throw a generic error
            Password::Policy::Exception->throw;
        }
    }

    my $enc_password = $self->encrypt({
        password => $password,
        algorithm => $algorithm,
        algorithm_args => $algorithm_args
    });

    # This is a post-encryption rule, so it's a special case.
    if($self->previous) {
        foreach my $previous_password (@{$self->previous}) {
            Password::Policy::Exception::ReusedPassword->throw if($enc_password eq $previous_password);
        }
    }
    return $enc_password;
}


sub encrypt {
    my ($self, $args) = @_;

    my $password = $args->{password} ||Password::Policy::Exception::EmptyPassword->throw;
    my $algorithm = $args->{algorithm} ||Password::Policy::Exception::NoAlgorithm->throw;
    my $algorithm_args = $args->{algorithm_args} || {};

    my $enc_class = 'Password::Policy::Encryption::' . $algorithm;
    try {
        Class::Load::load_class($enc_class);
    } catch {
        Password::Policy::Exception::InvalidAlgorithm->throw;
    };
    my $enc_obj = $enc_class->new($algorithm_args);
    my $new_password = $enc_obj->enc($password);
    return $new_password;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy - Make managing multiple password strength profiles easy

=head1 VERSION

version 0.04

=head1 UNICODE

This module strives to handle Unicode characters in a sane way. The exception are the
uppercase and lowercase rules, which obviously don't make sense in a Unicode setting.
If you find a case where Unicode characters don't behave correctly, please let me know.

=head1 EXCEPTIONS

This module tries to throw a well defined exception object when it encounters an
error. Wrapping it in something like L<Try::Tiny> is highly recommended, so that
you can handle errors intelligently.

=head1 EXTENDING

Password::Policy is a baseline - there's no conceivable way to plan for anything an
administrator would like to do. To add a rule, you need a package that looks like this:

    package Password::Policy::Rule::MyRule;

    use strict;
    use warnings;

    use parent 'Password::Policy::Rule';

    sub default_arg { return 42; }

    sub check {
        my $self = shift;
        my $password = $self->prepare(shift);

        ...your code goes here, and either throws an exception or doesn't...

        return 1;
    }

    1;

To add a new encryption type, you need a package that looks like this:

    package Password::Policy::Encryption::MyEncryption;

    use strict;
    use warnings;

    use parent 'Password::Policy::Encryption';

    sub enc {
        my $self = shift;
        my $password = $self->prepare(shift);

        ...your code goes here, and either throws an exception or doesn't...

        return $encrypted_password;
    }

    1;

=head1 SYNOPSIS

    use Password::Policy;

    my $pp = Password::Policy->new(config => '/path/to/config');
    $pp->process({ password => 'mypassword to check', profile => 'profile to check' });

=head1 DESCRIPTION

Password::Policy is an easy way to manage multiple password strength/encryption profiles.
The two most obvious use cases are:

 - You are running multiple sites with a similar/shared backend, and they have different
   policies for password strength

 - You have multiple types of users, and want different password strengths for each of them,
   It's ok for a regular user to have 'i like cheese' as a password, but an administrator's
   password should be made of stronger stuff.

The whole thing is driven by a configuration file, passed in on instantiation. It uses
L<Config::Any> internally, so the config file format can be whatever you would like. The
examples all use YAML, but anything Config::Any understands will work.

Assuming a configuration file looks like this:

    ---
    default:
        length: 4
        algorithm: "Plaintext"

    site_moderator:
        inherit: "default"
        length: 8
        uppercase: 1

    site_admin:
        inherit: "site_moderator"
        length: 10
        # will have uppercase: 1 from site_moderator
        numbers: 2
        algorithm: "ROT13"

The default profile will encrypt with plaintext (no encryption!), and make sure the
password is at least four characters long. If a site moderator is attempting to change
his password, it will extend that length check to 8, and require at least one of
those characters to be an uppercase ASCII character.

The site_admin profile will extend that length to 10, require two numbers, and
change the encryption method to ROT-13 (secure!). It also keeps the one uppercase
character requirement from site_moderator.

=head1 METHODS

=head2 new

Creates a new Password::Policy object. Takes at least one argument, config. Optionally
can take a second argument, previous, that contains encypted passwords (the idea being
that it's the user's old passwords, that can't be re-used).

=head2 process

Process a password. Takes a hashref as an argument, with at least one argument,
'password', that is the plaintext password. It also takes 'profile', which will
refer to a profile in the configuration file. Rules will be checked in alphabetical order.

    my $enc_passwd = $pp->process({ password => 'i like cheese', profile => 'site_admin' });

=head2 encrypt

Encrypt a password. Takes a hashref with the algorithm to use, the plain text password
to encrypt, and optionally any arguments you want to pass to the algorithm's module.

    my $enc_passwd = $pp->encrypt({ password => 'i like cheese', algorithm =>'ROT-13' });

=head1 ACKNOWLEDGEMENTS

The unit tests got a nice round of cleanup from StarLightPL. Thanks!

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
