package PDF::Template::TextObject;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::Template::Base);

    use PDF::Template::Base;

UNI_YES    use Unicode::String;
}

# This is a helper object. It is not instantiated by the user,
# nor does it represent an XML object. Rather, certain elements,
# such as <textbox>, can use this object to do text with variable
# substitutions.

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{STACK} = [] unless UNIVERSAL::isa($self->{STACK}, 'ARRAY');

    return $self;
}

sub resolve
{
    my $self = shift;
    my ($context) = @_;

UNI_YES    my $t = Unicode::String::utf8('');
UNI_NO     my $t = '';

    for my $tok (@{$self->{STACK}})
    {
        my $val = $tok;
        $val = $val->resolve($context)
            if PDF::Template::Factory::isa($val, 'VAR');

UNI_YES        $t .= Unicode::String::utf8("$val");
UNI_NO         $t .= $val;
    }

    return $t;
}

1;
__END__
