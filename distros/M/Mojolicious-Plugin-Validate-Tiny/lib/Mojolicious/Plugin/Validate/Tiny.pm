package Mojolicious::Plugin::Validate::Tiny;
use Mojo::Base 'Mojolicious::Plugin';

use v5.10;
use strict;
use warnings;
use Carp qw/croak/;
use Validate::Tiny;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our $VERSION = '0.17';

sub register {
    my ( $self, $app, $conf ) = @_;
    my $log = $app->log;

    # Processing config
    $conf = {
        explicit   => 0,
        autofields => 1,
        exclude    => [],
        %{ $conf || {} } };

    # Helper do_validation
    $app->helper(
        do_validation => sub {
            my ( $c, $rules, $params ) = @_;
            croak "ValidateTiny: Wrong validatation rules"
                unless ref($rules) ~~ [ 'ARRAY', 'HASH' ];

            $c->stash('validate_tiny.was_called', 1);

            $rules = { checks => $rules } if ref $rules eq 'ARRAY';
            $rules->{fields} ||= [];

            # Validate GET+POST parameters by default
            $params ||= $c->req->params->to_hash();

            # Validate Uploaded files by default
            $params->{ $_->name } ||= $_ for (@{ $c->req->uploads });

            #Latest mojolicious has an issue in that it doesn't include route supplied parameters so we need to hack that in.
            $params = { %{$params},  %{$c->stash->{'mojo.captures'}} };

            # Autofill fields
            if ( $conf->{autofields} ) {
                push @{$rules->{fields}}, keys %$params;
                for ( my $i = 0; $i< @{$rules->{checks}}; $i += 2 ){
                    my $field = $rules->{checks}[$i];
                    next if ref $field eq 'Regexp';
                    push @{$rules->{fields}}, $field;
                }
            }

            # Remove fields duplications
            my %h;
            @{$rules->{fields}} = grep { !$h{$_}++ } @{$rules->{fields}};

            # Check that there is an individual rule for every field
            if ( $conf->{explicit} ) {
                my %h = @{ $rules->{checks} };
                my @fields_wo_rules;

                foreach my $f ( @{ $rules->{fields} } ) {
                    next if $f ~~ $conf->{exclude};
                    push @fields_wo_rules, $f unless exists $h{$f};
                }

                if (@fields_wo_rules) {
                    my $err_msg = 'ValidateTiny: No validation rules for '
                        . join( ', ', map { qq'"$_"' } @fields_wo_rules );

                    my $errors = {};
                    foreach my $f (@fields_wo_rules) {
                        $errors->{$f} = "No validation rules for field \"$f\"";
                    }
                    $c->stash( 'validate_tiny.errors' => $errors);
                    $log->debug($err_msg);
                    return 0;
                }
            }

            # Do validation, Validate::Tiny made a breaking change and we need to support old and new users
            my $result; 
            if(Validate::Tiny->can('check')) {
                $result = Validate::Tiny->check( $params, $rules );
            }
            else { # Fall back for old Validate::Tiny version
                $result = Validate::Tiny->new( $params, $rules );
            }
            
            $c->stash( 'validate_tiny.result' => $result );

            if ( $result->success ) {
                $log->debug('ValidateTiny: Successful');
                return $result->data;
            } else {
                $log->debug( 'ValidateTiny: Failed: ' . join( ', ', keys %{ $result->error } ) );
                $c->stash( 'validate_tiny.errors' => $result->error );
                return;
            }
        } );

    # Helper validator_has_errors
    $app->helper(
        validator_has_errors => sub {
            my $c      = shift;
            my $errors = $c->stash('validate_tiny.errors');

            return 0 if !$errors || !keys %$errors;
            return 1;
        } );

    # Helper validator_error
    $app->helper(
        validator_error => sub {
            my ( $c, $name ) = @_;
            my $errors = $c->stash('validate_tiny.errors');

            return $errors unless defined $name;

            if ( $errors && defined $errors->{$name} ) {
                return $errors->{$name};
            }
        } );

    # Helper validator_error_string
    $app->helper(
        validator_error_string => sub {
            my ( $c, $params ) = @_;
            return '' unless $c->validator_has_errors();
            $params //= {};

		    return $c->stash('validate_tiny.result')->error_string(%$params);
        } );

    # Helper validator_any_error
    $app->helper(
        validator_any_error => sub {
            my ( $c ) = @_;
            my $errors = $c->stash('validate_tiny.errors');

            if ( $errors ) {
                return ( ( values %$errors )[0] );
            }

            return;
        } );


    # Print info about actions without validation
    $app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            my $stash = $c->stash;
            return 1 if $stash->{'validate_tiny.was_called'};

            if ( $stash->{controller} && $stash->{action} ) {
                $log->debug("ValidateTiny: No validation in [$stash->{controller}#$stash->{action}]");
                return 0;
            }

            return 1;
    } );

}

1;


=head1 NAME

Mojolicious::Plugin::Validate::Tiny - Lightweight validator for Mojolicious

=head1 SEE

This plugin is a copy of L<https://github.com/koorchik/Mojolicious-Plugin-ValidateTiny>, with the intent to have a plugin that it's maintained

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Validate::Tiny');
    
    # Mojolicious::Lite
    plugin 'Validate::Tiny';
    
    sub action { 
        my $self = shift;
        my $validate_rules = [
            # All of these are required
            [qw/name email pass pass2/] => is_required(),

            # pass2 must be equal to pass
            pass2 => is_equal('pass'),

            # custom sub validates an email address
            email => sub {
                my ( $value, $params ) = @_;
                Email::Valid->address($value) ? undef : 'Invalid email';
            }
        ];
        return unless $self->do_validation($validate_rules);
        
        ... Do something ...
    }
        
        
    sub action2 {
        my $self = shift;

        my $validate_rules = { 
            checks  => [...],
            fields  => [...],
            filters => [...]
        };
        if ( my $filtered_params =  $self->do_validation($validate_rules) ) {
            # all $params are validated and filters are applyed
            ... do your action ...

         
        } else {
            my $errors     = $self->validator_error;             # hash with errors
            my $pass_error = $self->validator_error('password'); # password error text
            my $any_error  = $self->validator_any_error;         # any error text
            
            $self->render( status => '403', text => $any_error );  
        }
        
    }
    
    __DATA__
  
    @@ user.html.ep
    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }
    %= form_for 'user' => begin
        <label for="username">Username</label><br />
        <%= input_tag 'username' %><br />
        <%= validator_error 'username' %><br />
  
        <%= submit_button %>
    % end

  
=head1 DESCRIPTION

L<Mojolicious::Plugin::Validate::Tiny> is a L<Validate::Tiny> support for L<Mojolicious>.

=head1 OPTIONS

=head2 C<explicit> (default 0)

If "explicit" is true then for every field must be provided check rule

=head2 C<autofields> (default 1)

If "autofields" then validator will automatically create fields list based on passed checks.
So, you can pass: 
    [
        user => is_required(),
        pass => is_required(),
    ]

instead of 

    {
        fields => ['user', 'pass'],
        checks => [
            user => is_required(),
            pass => is_required(),
        ]
    }

=head2 C<exclude> (default [])

Is an arrayref with a list of fields that will be never checked.

For example, if you use "Mojolicious::Plugin::CSRFProtect" then you should add "csrftoken" to exclude list.

=head1 HELPERS

=head2 C<do_validation>

Validates parameters with provided rules and automatically set errors.

$VALIDATE_RULES - Validate::Tiny rules in next form

    {
        checks  => $CHECKS, # Required
        fields  => [],      # Optional (will check all GET+POST parameters)
        filters => [],      # Optional
    }

You can pass only "checks" arrayref to "do_validation". 
In this case validator will take all GET+POST parameters as "fields"

returns false if validation failed
returns true  if validation succeded

    $self->do_validation($VALIDATE_RULES)
    $self->do_validation($CHECKS);


=head2 C<validator_has_errors>

Check if there are any errors.

    if ($self->validator_has_errors) {
        $self->render_text( $self->validator_any_error );
    }

    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }

=head2 C<validator_error>

Returns the appropriate error.

    my $errors_hash = $self->validator_error();
    my $username_error = $self->validator_error('username');

    <%= validator_error 'username' %>

=head2 C<validator_error_string>

Returns a string with all errors (an empty string in case of no errors).
Helper maps directly to Validate::Tiny::error_string method ( see L<Validate::Tiny/"error_string"> )

    my $error_str = $self->validator_error_string();

    <%= validator_error_string %>
    
=head2 C<validator_any_error>
    
Returns any of the existing errors. This method is usefull if you want return only one error.

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>
and this copy is maintained by Adrian Crisan <adrian.crisan88@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/crlcu/Mojolicious-Plugin-Validate-Tiny>

=head1 SEE ALSO

L<Validate::Tiny>, L<Mojolicious>, L<Mojolicious::Plugin::Validator>, L<Mojolicious::Plugin::ValidateTiny> 

=cut
