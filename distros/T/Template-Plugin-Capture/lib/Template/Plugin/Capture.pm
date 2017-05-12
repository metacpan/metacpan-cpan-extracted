package Template::Plugin::Capture;
use strict;
use warnings;
use base qw(Template::Plugin);

our $VERSION = '0.01';

our $FILTER_NAME = 'capture';

sub new {
    my ($class, $context, @args) = @_;
    my $self = bless {}, $class;
    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, $self->_filter, 1);
    $self;
}

sub _filter {
    my $self = shift;
    return sub {
        my ($context, $name) = @_;
        $self->throw('no name specified') unless defined $name;
        return sub {
            my $text = shift;
            $context->{STASH}->set($name, $text);
            return '';
        }
    };
}

sub throw {
    my $self = shift;
    die(Template::Exception->new('Capture', join('', @_)));
}

1;
__END__

=head1 NAME

Template::Plugin::Capture - TT Plugin to capture FILTER block

=head1 SYNOPSIS

    [% USE Capture %]
    [% FILTER capture('block1') %]
    blah, blah, blah
    [% END %] # nothings output
    [% block1 %]
    # output "blah, blah, blah"


=head1 DESCRIPTION

Template::Plugin::Capture is a plugin for TT, which allows you to
capture FILTER block in templates.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut
