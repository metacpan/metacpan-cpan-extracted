package Muster::Hook::Toggle;
$Muster::Hook::Toggle::VERSION = '0.92';
use Mojo::Base 'Muster::Hook';
use Muster::LeafFile;
use Muster::Hooks;
use Encode;

use Carp 'croak';

=head1 NAME

Muster::Hook::Toggle - Muster toggle directive.

=head1 VERSION

version 0.92

=head1 DESCRIPTION

L<Muster::Hook::Toggle> toggle display of sections on and off.

=head1 METHODS

L<Muster::Hook::Toggle> inherits all methods from L<Muster::Hook::Directives>.

=head2 register_filter

Do some intialization.

=cut
sub register_filter {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    $hookmaster->add_filter('toggle' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register_filter

=head2 process

Process toggling -- expects HTML input.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $c = $args{controller};
    my $html = $args{html};

    # Only do toggle processing if there's at least one toggle
    if ($html =~ /<!--toggle/)
    {
        $html =~ s/<!--toggle-(start|end)\s+id=(\w+)\s*-->/$self->set_a_toggle($1,$2)/eg;

        my $css = <<EOT1;
<style>
input.toggle[type="checkbox"] {
    display: none;
}
label.toggle {
    position: relative;
    display: block;
    width: 38px;
    height: 38px;
    cursor: pointer;
    background: blue;
    border-radius: 100%;
    color: white;
}
label.toggle:after {
    content: '+';
    position: absolute;
    top: 2px;
    left: 11px;
    font-size: 30px;
    line-height: 1em;
    font-family: sans-serif;
}
.hide-show {
    display: none;
    padding: 10px;
    border: 2px solid #999999;
}

input.toggle[type="checkbox"]:checked ~ label {
    background: green;
}
input.toggle[type="checkbox"]:checked ~ label:after {
    content: '-';
    left: 15px;
}
input.toggle[type="checkbox"]:checked ~ .hide-show {
    display: block;
}
</style>
EOT1

        # This is going into the controller stash
        $c->stash('head_append' => $css);
    }

    return $html;
} # process

=head2 set_a_toggle

Set one toggle (start or end)

    $text = set_a_toggle($begin_or_end,$id);

=cut
sub set_a_toggle {
    my $self = shift;
    my $begin_or_end = shift;
    my $id = shift;

    my $out = '';
    if ($begin_or_end =~ /start/i)
    {
        $out = <<EOT2;
<div>
<input class="toggle" type="checkbox" id="$id" />
<label class="toggle" for="$id"></label>
<div class="hide-show">
EOT2
    }
    else
    {
        # put in the closing </div>s
        $out = "\n</div></div>\n";
    }

    return $out;
} # set_a_toggle

1;
