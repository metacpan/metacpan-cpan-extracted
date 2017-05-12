package Validator;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;
    
    $self->plugin('FormValidator');
    
    my $profiles = {
        "/" => {
            required => [qw(username)],
            optional => [qw(email)],

            field_filters => {
                username => ['trim', 'lc'],
            },

            constraint_methods => {
                username => Data::FormValidator::Constraints::FV_length_between(4, 32),
                email => Data::FormValidator::Constraints::email(),
            },
        },
    };
    
    my $r = $self->routes;
    $r->get('/')->to('example#welcome')->over(dfv_verify => $profiles->{"/"});
    $r->get('/:from/:to')->to('example#welcome')->over(dfv_verify => $profiles->{"/"});
    $r->get('/unchecked')->to('example#unchecked');
}

1;
