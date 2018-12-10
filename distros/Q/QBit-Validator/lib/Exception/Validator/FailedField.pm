package Exception::Validator::FailedField;
$Exception::Validator::FailedField::VERSION = '0.012';
use base qw(Exception::Validator);

use Scalar::Util qw(blessed);

sub import {
    FF->export_to_level(1);
}

sub new {
    my ($this, $text, %data) = @_;

    my $class = ref($this) || $this;

    $text = '' if !defined $text;

    my $self = {
        %data,
        (
            blessed($text) && $text->isa('Exception')
            ? (text => $text->{'text'}, parent => $text)
            : (text => $text)
        ),
    };

    return bless $self, $class;
}

sub as_string {
    my ($self) = @_;

    return ref($self) . ": $self->{'text'}\n" . ($self->{'parent'} ? "\n$self->{'parent'}\n" : '');
}

package FF;
$FF::VERSION = '0.012';
use base qw(Exception::Validator::FailedField Exporter);

1;
