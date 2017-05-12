package TestWrapper;
use Any::Moose;

extends 'MouseX::Types::Wrapper';
#use Class::C3;
#use base 'MouseX::Types::Wrapper';

override type_export_generator => sub {
    my $code = super();
    return sub { $code->(@_) };
};

#sub type_export_generator {
#    my $class = shift;
#    my ($type, $full) = @_;
#    my $code = $class->next::method(@_);
#    return sub { $code->(@_) };
#}

override check_export_generator => sub {
    my $code = super();
    return sub {
        return $code unless @_;
        return $code->(@_);
    };
};

#sub check_export_generator {
#    my $class = shift;
#    my ($type, $full, $undef_msg) = @_;
#    my $code = $class->next::method(@_);
#    return sub {
#        return $code unless @_;
#        return $code->(@_);
#    };
#}

override coercion_export_generator => sub {
    my $code = super();
    return sub {
        my $value = $code->(@_);
        die "coercion returned undef\n" unless defined $value;
        return $value;
    };
};

#sub coercion_export_generator {
#    my $class = shift;
#    my ($type, $full, $undef_msg) = @_;
#    my $code = $class->next::method(@_);
#    return sub {
#        my $val = $code->(@_);
#        die "coercion returned undef\n" unless defined $val;
#        return $val;
#    };
#}

1;
