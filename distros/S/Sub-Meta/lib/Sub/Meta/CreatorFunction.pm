package Sub::Meta::CreatorFunction;
use 5.010;
use strict;
use warnings;

use Class::Load ();

use Sub::Meta::Library;
use Sub::Meta::Creator;

our @FINDER_CLASSES = (
    'Sub::Meta::Finder::FunctionParameters',
    'Sub::Meta::Finder::SubWrapInType',
    'Sub::Meta::Finder::Default',
);

sub find_submeta {
    my $sub = shift;

    if (my $submeta = Sub::Meta::Library->get($sub)) {
        return $submeta;
    }

    state $creator = Sub::Meta::Creator->new(finders => finders());
    if (my $submeta = $creator->create($sub)) {
        return $submeta;
    }
    return;
}

sub finders {
    my @finders;
    for my $finder_class (@FINDER_CLASSES) {
        if (Class::Load::try_load_class($finder_class)) {
            push @finders => $finder_class->can('find_materials');
        }
    }
    return \@finders;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::CreatorFunction - utilities to create Sub::Meta

=head1 SYNOPSIS

    use Sub::Meta::CreatorFunction;

    sub hello { }
    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello);

=head1 DESCRIPTION

This module tries to create Sub::Meta from a subroutine
in the way it is under Sub::Meta::Finder, or from Sub::Meta::Library.

=head1 FUNCTIONS

=head2 find_submeta($sub)

    find_submeta(CodeRef $sub) => Maybe[Sub::Meta]

Return submeta of subroutine.

=head2 finders

    finders() => ArrayRef[CodeRef]

Return arrayref of C<Sub::Meta::Finder::*::find_materials>.

=head1 CUSTOMIZE

=head2 @FINDER_CLASSES

You can change @FINDER_CLASSES:

    local @Sub::Meta::CreatorFunction::FINDER_CLASSES = qw(MySubMeta::Finder);
    my $meta = Sub::Meta::CreatorFunction::find_submeta(\&hello); # find by MySubMeta::Finder

Note that once find_submeta is called, the finders will be fixed by C<state>.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
