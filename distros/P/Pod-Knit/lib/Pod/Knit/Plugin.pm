package Pod::Knit::Plugin;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: base class for Pod::Knit transforming modules
$Pod::Knit::Plugin::VERSION = '0.0.1';

use strict;
use warnings;

use Log::Any '$log';

use Moose;

use experimental qw/ signatures /;


sub munge { return $_[1] }


has knit => (
    isa => 'Pod::Knit',
    is => 'ro',
    handles => {
    },
);


has stash => (
    is => 'ro',
    lazy => 1,
    default => sub { {} },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin - base class for Pod::Knit transforming modules

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use Pod::Knit::Document;
    use Pod::Knit::Plugin;
    
    my $doc = Pod::Knit::Document->new( file => 'Foo.pm' );
    
    my $new_doc = Pod::Knit::Plugin->new()->munge($doc);

=head1 DESCRIPTION

C<Pod::Knit::Plugin> is the base class for the transforming modules of the
L<Pod::Knit> system.

A plugin should override the C<munge> method, and may implement a
C<setup_podparser> method that is invoked when the C<podparser> of a
C<Pod::Knit::Document> is created. For example, if a plugin is to introduce
two new tags, C<method> and C<signature>, it should have

    sub setup_podparser ( $self, $parser ) {
    
        $parser->accept_directive_as_processed( qw/
            method signature
        /);
    
        $parser->commands->{method}    = { alias => 'head3' };
        $parser->commands->{signature} = { alias => 'verbatim' };
    }

Because munging XML with regular expressions and the like is no fun, you
most probably want your plugins to consume either one of the
L<Pod::Knit::DOM::WebQuery> or L<Pod::Knit::DOM::Mojo> roles, which augment
the doc passed to the plugin with yummilicious DOM manipulating methods.

=head1 attributes

=head3 knit

Orchestrating L<Pod::Knit> object. Optional.

=head3 stash

Hashref of variables typically passed by the C<knit> object.

=head1 methods

=head3 munge

    $new_doc = $self->munge( $doc )

Takes in a L<Pod::Knit::Document>, and returns a new one.

For the base C<Pod::Knit::Plugin> class, the method is a pass-through that
returns the exact same document.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

