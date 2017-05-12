package Farm::Cow;

use Moose;

with 'MooseX::Templated';

has 'spots'    => ( is => 'rw', default => 8 );
has 'hobbies'  => ( is => 'rw', default => sub { [ 'mooing', 'chewing' ] } );

sub moo { "Moooooooo" }

sub _template_summary { <<'_TT' }

This cow has [% self.spots %] spots. It mostly spends its time
[% self.hobbies.join(" and ") %]. When it is very happy
it exclaims, "[% self.moo %]!".

_TT

sub _template_html {
    my $self = shift;
    return "<h1>Cow</h1>".
           "<p>" . $self->_template_summary . "</p>";
}

1;
