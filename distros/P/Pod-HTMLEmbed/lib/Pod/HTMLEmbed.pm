package Pod::HTMLEmbed;
use Any::Moose;

our $VERSION = '0.04';

use Carp::Clan '^(Mo[ou]se::|Pod::HTMLEmbed(::)?)';
use Pod::Simple::Search;
use Pod::HTMLEmbed::Entry;

has search_dir => (
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => 'has_search_dir',
);

has url_prefix => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_url_prefix',
);

no Any::Moose;

sub load {
    my ($self, $file) = @_;
    Pod::HTMLEmbed::Entry->new( file => $file, _context => $self );
}

sub find {
    my ($self, $name) = @_;

    my $file;
    my $finder = Pod::Simple::Search->new;

    if ($self->has_search_dir) {
        $finder->inc(0);
        $file = $finder->find( $name, @{ $self->search_dir } );
    }
    else {
        $file = $finder->find( $name );
    }

    unless ($file) {
        my $dirs = join ':', $self->has_search_dir ?
            (@{ $self->search_dir }) : (@INC);

        croak qq[No pod found by name "$name" in $dirs];
    }

    $self->load($file);
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords Str HTMLEmbed html pod2html url

=head1 NAME

Pod::HTMLEmbed - Make clean html snippets from POD

=head1 SYNOPSIS

Get L<Pod::HTMLEmbed::Entry> object from File:

    my $p   = Pod::HTMLEmbed->new;
    my $pod = $p->load('/path/to/pod.pod');

Or search by name in @INC

    my $p   = Pod::HTMLEmbed->new;
    my $pod = $p->find('Moose');

Or search by name in specified directory

    my $p   = Pod::HTMLEmbed->new( search_dir => ['/path/to/dir'] );
    my $pod = $p->find('Moose');

See L<Pod::HTMLEmbed::Entry> for methods for C<$pod>.

=head1 DESCRIPTION

This module generates small and clean HTML from POD file.

Unlike other pod2html modules, this module enables you to get section based html snippets.
For example, you can get an html for SYNOPSIS section by following code:

    my $html = $pod->section('SYNOPSIS');

Also you can get simple "Table of contents" html like:

    <ul>
    <li><a href="#NAME">NAME</a></li>
    <li><a href="#SYNOPSIS">SYNOPSIS</a></li>
    <li><a href="#METHODS">METHODS</a></li>
     :
    </ul>

by following code:

    my $toc_html = $pod->toc;

You can easily create custom pod viewer with this module. Enjoy!

=head1 METHODS

=head2 new(%options)

Create new L<Pod::HTMLEmbed> object. pod searcher/loader object.

Available options:

=over 4

=item search_dir => 'ArrayRef'

Pod search directory.

If this value is set, C<find> method use this directory as search target.
Otherwise search C<@INC>.

=item url_prefix => 'Str'

URL prefix for pod link url. Default is C<http://search.cpan.org/perldoc?>.

=back

=head2 find($pod_name)

Find pod by $pod_name and return L<Pod::HTMLEmbed::Entry> object if it exists.

=head2 load($pod_file)

Load pod file (C<$pod_file>) and return L<Pod::HTMLEmbed::Entry> object if it exists.

=head1 SEE ALSO

L<Pod::HTMLEmbed::Entry>.

=head1 AUTHOR

Daisuke Murase C<typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
