package MooseX::Has::Options;
{
  $MooseX::Has::Options::VERSION = '0.003';
}

# ABSTRACT: Succinct options for Moose

use strict;
use warnings;

use Class::Load;
use List::MoreUtils;
use String::RewritePrefix;
use Package::Stash;

sub import
{
    my $class   = shift;
    my $caller  = caller;
    my $keyword = 'has';

    $class->import_into($caller, $keyword, @_);
}

sub import_into
{
    my ($class, $into, $keyword, @handlers) = @_;

    # try to load the caller stash,
    # bail out if we can't find the requested keyword

    my $stash = Package::Stash->new($into);

    Carp::carp "Cannot add options for '$keyword', no subroutine of this name found in caller package"
        unless $stash->has_symbol("&$keyword");

    # expand import arguments to full class names
    my @handler_classes = String::RewritePrefix->rewrite(
        { '' => 'MooseX::Has::Options::Handler::', '+' => '' },
        List::MoreUtils::uniq('Accessors', @handlers)
    );

    my %handlers;

    foreach my $handler_class (@handler_classes)
    {
        # require each handler class
        Class::Load::load_class($handler_class);
        # add the shortcuts that it handles
        %handlers = (%handlers, $handler_class->handles);
    }

    # options processor sub that closes over %handlers
    my $shortcut_processor = sub
    {
        my (@shortcuts, @expanded);

        while ( defined $_[0] && $_[0] =~ /^:(\w+)$/ )
        {
            # get the name of the shortcut, sans the column
            push @shortcuts, $1;

            # make sure to remove that shortcut from @_
            shift;
        }

        foreach my $shortcut (@shortcuts)
        {
            my %expansion = exists $handlers{$shortcut}
                ? ( %{ $handlers{$shortcut} } )
                : ( $shortcut => 1 );

            push @expanded, %expansion;
        }

        return @expanded, @_;
    };

    my $orig = $stash->get_symbol("&$keyword");

    $stash->add_symbol(
        "&$keyword",
        sub { $orig->(shift, $shortcut_processor->(@_)) }
    );
}

1;


__END__
=pod

=for :stopwords Peter Shangov hashrefs

=head1 NAME

MooseX::Has::Options - Succinct options for Moose

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Moose;
    use MooseX::Has::Options;

    has 'some_attribute' => (
        qw(:ro :required),
        isa => 'Str',
        ...
    );

    has 'another_attribute' => (
        qw(:ro :lazy_build),
        isa => 'Str',
        ...
    );

=head1 DESCRIPTION

This module provides a succinct syntax for declaring options for L<Moose> attributes.

=head1 USAGE

=head2 Declaring options

C<MooseX::Has::Params> works by checking the arguments to C<has> for strings that look like options, i.e. alphanumeric strings preceded by a colon, and replaces them with a hash whose keys are the names of the options (sans the colon) and the values are C<1>'s. Thus,

    has 'some_attribute', ':required';

becomes:

    has 'some_attribute', required => 1;

Options must come in the beginning of the argument list. MooseX::Has::Options will stop searching for options after the first alphanumeric string that does not start with a colon.

The default behaviour can be customised per attribute. For example, here is how C<ro>, C<rw> and C<bare> work:

    has 'some_attribute', ':ro';

becomes:

    has 'some_attribute', is => 'ro';

See below for details.

=head2 Handlers

C<MooseX::Has::Options> allows you to expand specific 'shortcut' arguments to arbitrary values via the handler interface. A 'handler' is a module in the L<MooseX::Has::Options::Handler> namespace that provides a C<handler> function. The handler function should return a hash whose keys are shortcut names, and the values are hashrefs with the values that the respective shortcuts should be expanded to. In order to enable the shortcuts supplied by a given handler you need to add it in the import statement:

    use MooseX::Has::Options qw(NativeTypes);

    has 'some_attribute', qw(:ro :hash), default => sub {{ foo => bar }};

The following handlers ship with the default distribution:

=over 4

=item *

L<MooseX::Has::Options::Handler::Accessors> (included by default when you import this module)

=item *

L<MooseX::Has::Options::Handler::NativeTypes>

=item *

L<MooseX::Has::Options::Handler::NoInit>

=back

=head1 IMPLEMENTATION DETAILS

C<MooseX::Has::Options> hijacks the C<has> function imported by L<Moose> and replaces it with one that understands the options syntax described above. This is not an optimal solution, but the current implementation of C<Moose::Meta::Attribute> prevents this functionality from being provided as a meta trait.

=head1 DEPRECATED BEHAVIOUR

Previous versions of C<MooseX::Has::Params> allowed you to specify during import the name of the function too hook into, like so:

    use HTML::FormHandler::Moose;
    use MooseX::Has::Options qw(has_field);

    has_field 'name' => (
        qw(:required),
        type => 'Text',
    );

This behaviour is deprecated as of version 0.003 as this syntax is now used for specifying handlers. If you need to hook into a different function see the implementation of C<MooseX::Has::Options::import()> and C<MooseX::Has::Options::import_into()>.

=head1 SEE ALSO

=over 4

=item *

L<MooseX::Has::Sugar>

=back

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

