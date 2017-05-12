package SVN::Web::Browse;

use strict;
use warnings;

use base 'SVN::Web::action';

use Encode ();
use SVN::Ra;
use SVN::Client;
use SVN::Web::X;

our $VERSION = 0.63;

=head1 NAME

SVN::Web::Browse - SVN::Web action to browse a Subversion repository

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    browse:
      class: SVN::Web::Browse
      action_menu:
        show:
          - directory
        link_text: (browse directory)
    ...

=head1 DESCRIPTION

Returns a file/directory listing for the given repository path.

=head1 OPTIONS

=over 4

=item rev

The repository revision to show.  Defaults to the repository's youngest
revision.

=back

=head1 TEMPLATE VARIABLES

=over 4

=item at_head

A boolean value, indicating whether or not the user is currently
browsing the HEAD of the repository.

=item context

Always C<directory>.

=item entries

A list of hash refs, one for each file and directory entry in the browsed
path.  The list is ordered with directories first, then files, sorted
alphabetically.

Each hash ref has the following keys.

=over 8

=item name

The entry's name.

=item path

The entry's full path.

=item rev

The entry's most recent interesting revision.

=item size

The entry's size, in bytes.  The empty string C<''> for directories.

=item type

The entry's C<svn:mime-type> property.  Not set for directories.

=item author

The userid that committed the most recent interesting revision for this
entry.

=item date

The date of the entry's most recent interesting revision, formatted
according to L<SVN::Web/"Time and date formatting">.

=item msg

The log message for the entry's most recent interesting revision.

=back

=item rev

The repository revision that is being browsed.  Will be the same as the
C<rev> parameter given to the action, unless that parameter was not set,
in which case it will be the repository's youngest revision.

=item youngest_rev

The repository's youngest revision.

=back

=head1 EXCEPTIONS

=over 4

=item (path %1 does not exist in revision %2)

The given path is not present in the repository at the given revision.

=item (path %1 is not a directory in revision %2)

The given path exists in the repository at the given revision, but is
not a directory.  This action is only used to browse directories.

=back

=cut

sub cache_key {
    my $self = shift;
    my $path = $self->{path};

    my ( undef, undef, $act_rev, $at_head ) = $self->get_revs();

    return "$act_rev:$at_head:$path";
}

sub run {
    my $self = shift;
    my $uri = $self->{repos}{uri};
    $uri .= '/'.$self->rpath if $self->rpath;

    my ( $exp_rev, $yng_rev, $act_rev, $at_head ) = $self->get_revs();

    my $rev = $act_rev;

    my $node_kind = $self->svn_get_node_kind($uri, $rev, $rev);

    if ( $node_kind == $SVN::Node::none ) {
        SVN::Web::X->throw(
            error => '(path %1 does not exist in revision %2)',
            vars  => [ $self->rpath, $rev ]
        );
    }

    if ( $node_kind != $SVN::Node::dir ) {
        SVN::Web::X->throw(
            error => '(path %1 is not a directory in revision %2)',
            vars  => [ $self->rpath, $rev ],
        );
    }

    my $dirents = $self->ctx_ls( $uri, $rev, 0 );

    my $entries = [];
    my $current_time = time();

    my $base_path = $self->rpath;
    while ( my ( $svn_name, $dirent ) = each %{$dirents} ) {
        my $name = Encode::decode('utf8',$svn_name);
        my $node_kind = $dirent->kind();

        my @log_result = $self->recent_interesting_rev( "$base_path/$name", $rev );

        push @{$entries},
          {
            name      => $name,
            rev       => $log_result[1],
            kind      => $node_kind,
            isdir     => ( $node_kind == $SVN::Node::dir ),
            size      => ( $node_kind == $SVN::Node::dir ? '' : $dirent->size() ),
            author    => $dirent->last_author(),
            has_props => $dirent->has_props(),
            time      => $dirent->time() / 1_000_000,
            age       => $current_time - ( $dirent->time() / 1_000_000 ),
            msg       => Encode::decode('utf8',$log_result[4]),
          };
    }

    # TODO: custom sorting
    @$entries =
      sort { ( $b->{isdir} <=> $a->{isdir} ) || ( $a->{name} cmp $b->{name} ) }
      @$entries;

    my @props = ();
    foreach my $prop_name (qw(svn:externals)) {
        my $prop_value = ( $self->ctx_revprop_get( $prop_name, $uri, $rev ) )[0];
        if ( defined $prop_value ) {
            $prop_value =~ s/\s*\n$//ms;
            push @props, { name => $prop_name, value => $prop_value };
        }
    }

    return {
        template => 'browse',
        data     => {
            context      => 'directory',
            entries      => $entries,
            rev          => $act_rev,
            youngest_rev => $yng_rev,
            at_head      => $at_head,
            props        => \@props,
        }
    };
}

1;

=head1 COPYRIGHT

Copyright 2003-2004 by Chia-liang Kao C<< <clkao@clkao.org> >>.

Copyright 2005-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
