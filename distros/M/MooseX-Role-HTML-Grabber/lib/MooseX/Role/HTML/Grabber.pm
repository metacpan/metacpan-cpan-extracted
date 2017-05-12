use strict;
use warnings;
# ABSTRACT: proved the needed bits to be a HTML-Grabber
package MooseX::Role::HTML::Grabber;

use MooseX::Role::Parameterized;

use MooseX::AttributeShortcuts;
use MooseX::Types::Moose       qw{ Str Bool };

use namespace::clean -except => 'meta';

use HTML::Grabber;

our $VERSION = '0.002'; # VERSION

parameter name => (is => 'ro', isa => Str, default => 'html_grabber' );
parameter method => (is => 'ro', isa => Str, default => 'content' );

# traits, if any, for our attributes
parameter traits => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => { all_traits => 'elements' },
);

role {
    use Data::Dumper;
    local $Data::Dumper::Indent = 1;
    my $p = shift @_;

    my $name = $p->name;

    my $traits = [ Shortcuts, $p->all_traits ];
    my @defaults = (traits => $traits, is => 'rw', lazy_build => 1);

    ## generate our attribute & builder names... nicely sequential tho :)
    my $a = sub {             $name . '_' . shift @_ };
    my $b = sub { '_build_' . $name . '_' . shift @_ };

    has $a->('grabber') => (@defaults, isa => 'HTML::Grabber');

    # create the HTML::Grabber for this named role.
    method $b->('grabber') => sub {
        my $self = shift @_;
        my $method = $p->method;
        my $grabber = HTML::Grabber->new( html => $self->$method );
        return $grabber;
    }
};

1;

__END__
=pod

=head1 NAME

MooseX::Role::HTML::Grabber - proved the needed bits to be a HTML-Grabber

=head1 VERSION

version 0.002

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Role-HTML-Grabber>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/trcjr/moosex-role-html-grabber>

  git clone git://github.com/trcjr/moosex-role-html-grabber.git

=head1 AUTHOR

Theodore Robert Campbell Jr <trcjr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Theodore Robert Campbell Jr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

