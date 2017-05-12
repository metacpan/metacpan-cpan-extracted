package t::Object::Methods;

use Object::LocalVars;

give_methods our $self;

sub what_am_i : Method {
    return "I am a " . ref ($self);
};

sub greeting : Method {
    my $friend = shift;
    return "Hello, $friend";
}

sub report_caller : Method {
    return ( caller );
}
1;
