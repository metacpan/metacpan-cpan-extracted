package System::InitD::Template;

=head1 NAME

System::InitD::Template

=head1 DESCRIPTION

Simple template system just for internal usage in System::InitD

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

our $ANCHOR = ['\[%', '%\]'];

=over

=item B<render>

Returns rendered template. Accepts as parameters file or handle
and variables hashref(key=>value).

=back 

=cut

sub render {
    my (%params) = @_;

    if (!$params{file} && !$params{handle} && !$params{text}) {
        croak "Can't render nothing";
    }

    if ($params{render_params} && ref $params{render_params} ne 'HASH') {
        croak "render_params must be a hashref";
    }

    my $render_params = $params{render_params};
    
    $render_params->{PERL} = $^X;
    my @template;

    if ($params{file}) {
        @template = _tff($params{file});
    }
    elsif($params{handle}) {
        @template = _tfd($params{handle});
    }
    else {
        @template = split "\n", $params{text};
    }
    local *{System::InitD::Template::parse} = sub {
        my $string = shift;
        for my $key (keys %$render_params) {
            next unless $render_params->{$key};
            $string =~ s/$ANCHOR->[0]\s*?$key\s*?$ANCHOR->[1]/$render_params->{$key}/gs;
        }
        my $template = "$ANCHOR->[0].*?$ANCHOR->[1]";
        # print $template;
        $string =~ s/$template//gs;

        return $string;
    };

    @template = map {
        parse($_);    
    } @template;
    return join '', @template;
}


# template from file
sub _tff {
    my $file = shift;

    unless (-e $file) {
        croak "File $file does not exists.";
    }

    my $fh;

    open $fh, $file or croak "Can't open file $file: $!";
    return _tfd($fh);
}


#template from descriptor
sub _tfd {
    my $glob = shift;

    my @content = <$glob>;
    close $glob;
    return @content;
}


1;
