package PDF::FromHTML::Template::TextObject;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Base);

    use PDF::FromHTML::Template::Base;

    use Encode;
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

    my $t = '';

    for my $tok (@{$self->{STACK}})
    {
        my $val = $tok;
        $val = $val->resolve($context)
            if PDF::FromHTML::Template::Factory::isa($val, 'VAR');

        my $encoding = $context->get($self, 'PDF_ENCODING');
        if ($encoding) {
            if (Encode::is_utf8($val)) {
                $val = Encode::encode($encoding,$val);
            }
        }

        $t .= $val;
    }

    return $t;
}

1;
__END__
