package Plugin::Test::OurPlugin;

#use base qw( Template::Plugin );
#use Template::Plugin;

# see perldoc Template::Plugin on why new is like this
sub new {
    my ($class, $context, @params) = @_;
    bless {
        _CONTEXT => $context,
    }, $class;
}

sub return_foo {
    return 'foo';
}

sub substitute_with_raz {
    my ($self) = shift;
    my $word   = shift;
    $word =~ s!$word!raz!;
    return $word;
}

sub substitute_arg1_with_arg2 {
    my ($self) = shift;
    my $arg1   = shift;
    my $arg2   = shift;

    my $arg = $arg1;
    $arg =~ s!$arg1!$arg2!;
    return $arg;
}


sub substitute_arg1_with_arg2_repeat_N_times {
    my ($self) = shift;
    my $arg1   = shift;
    my $arg2   = shift;
    my $arg3   = shift;

    my $arg = $arg1;
    $arg =~ s!$arg1!$arg2!;
    return ($arg x $arg3);
}

1;

