package QBit::WebInterface::Controller::Template::Provider;
$QBit::WebInterface::Controller::Template::Provider::VERSION = '0.029';
use qbit;

use base qw(Template::Provider);

sub _minimize {
    my ($self, $template) = @_;

    # Remove TT2 comments
    $template =~ s/\s*\[%#[^#]+#%\]\s*/ /go;

    # Remove tail space
    $template =~ s{\s+$}{}o;
    $template =~ s{^\s+}{}o;

    my @parts = split(/\s+/o, $template);
    $template = $parts[0];
    my $r = $parts[0];

    for (my $i = 1; $i < scalar(@parts); $i++) {
        unless (
               ($template =~ /&#32;$/o)
            || ($parts[$i] =~ /^&#32;/o)
            ||    # Space already placed here
            (($template =~ /<[^<>]+$/o) && ($parts[$i] =~ /^>/o))
            ||    # Tag closure
            (($template =~ /%\]$/o) && ($parts[$i] =~ /^\[%/o))
            ||    # Between TT2 instructions
            ($template  =~ />$/o) ||    # After tag
            ($parts[$i] =~ /^</o) ||    # Before tag
            (($template =~ /%\]$/o) && ($template =~ />[^<]+$/o))
            ||                          # After TT2 instruction outer of tags
            (($parts[$i] =~ /^\[%/o) && ($template =~ />[^<]+$/o))
            ||                          # Before TT2 instruction outer of tags
            (      ($template =~ /<[^<>]+"$/o)
                && (($parts[$i] =~ /^[^<>]*>/o) || ($parts[$i] !~ />/o)))    # In a tag, space after "
               )
        {
            $parts[$i] = ' ' . $parts[$i];
        }
        $template = substr $template, -100;
        $template .= $parts[$i];
        $r        .= $parts[$i];
    }
    return $r;
}

sub _load {
    my $self = shift;

    my ($data, $error) = $self->SUPER::_load(@_);

    return ($data, $error) unless defined($data);

    unless (utf8::is_utf8($data->{'text'})) {
        utf8::decode($data->{'text'});
    }

    $data->{'text'} = $self->_minimize($data->{'text'})
      if $self->{'PARAMS'}{'MINIMIZE'};

    return ($data, $error);
}

TRUE;
