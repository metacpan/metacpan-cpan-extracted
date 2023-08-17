use strict;
use warnings;
package Dist::Zilla::Role::File::ChangeNotification;
# ABSTRACT: Receive notification when something changes a file's contents
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.006';

use Moose::Role;
use Digest::MD5 'md5_hex';
use Encode 'encode_utf8';
use namespace::autoclean;

has _content_checksum => ( is => 'rw', isa => 'Str' );

has on_changed => (
    isa => 'ArrayRef[CodeRef]',
    traits => ['Array'],
    handles => {
        _add_on_changed => 'push',
        _on_changed_subs => 'elements',
    },
    lazy => 1,
    default => sub { [] },
);

sub on_changed
{
    my ($self, $watch_sub) = @_;
    $self->_add_on_changed($watch_sub || sub {
        my ($file, $new_content) = @_;
        die 'content of ', $file->name, ' has changed!';
    });
}

sub watch_file
{
    my $self = shift;

    $self->on_changed if not $self->_on_changed_subs;
    return if $self->_content_checksum;

    # Storing a checksum initiates the "watch" process
    $self->_content_checksum($self->__calculate_checksum);
    return;
}

sub __calculate_checksum
{
    my $self = shift;
    # this may not be the correct encoding, but things should work out okay
    # anyway - all we care about is deterministically getting bytes back
    md5_hex(encode_utf8($self->content))
}

around content => sub {
    my $orig = shift;
    my $self = shift;

    # pass through if getter
    return $self->$orig if @_ < 1;

    # store the new content
    # XXX possible TODO: do not set the new content until after the callback
    # is invoked. Talk to me if you care about this in either direction!
    my $content = shift;
    $self->$orig($content);

    my $old_checksum = $self->_content_checksum;

    # do nothing extra if we haven't got a checksum yet
    return $content if not $old_checksum;

    # ...or if the content hasn't actually changed
    my $new_checksum = $self->__calculate_checksum;
    return $content if $old_checksum eq $new_checksum;

    # update the checksum to reflect the new content
    $self->_content_checksum($new_checksum);

    # invoke the callback
    $self->_has_changed($content);

    return $self->content;
};

sub _has_changed
{
    my ($self, @args) = @_;

    $self->$_(@args) for $self->_on_changed_subs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::File::ChangeNotification - Receive notification when something changes a file's contents

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::MyPlugin;
    sub some_phase
    {
        my $self = shift;

        my ($source_file) = grep { $_->name eq 'some_name' } @{$self->zilla->files};
        # ... do something with this file ...

        Dist::Zilla::Role::File::ChangeNotification->meta->apply($source_file);
        my $plugin = $self;
        $file->on_changed(sub {
            $plugin->log_fatal('someone tried to munge ', shift->name,
                ' after we read from it. You need to adjust the load order of your plugins.');
        });
        $file->watch_file;
    }

=head1 DESCRIPTION

This is a role for L<Dist::Zilla::Role::File> objects which gives you a
mechanism for detecting and acting on files changing their content. This is
useful if your plugin performs an action based on a file's content (perhaps
copying that content to another file), and then later in the build process,
that source file's content is later modified.

=head1 METHODS

=head2 C<on_changed($subref)>

Provide a method to be invoked against the file when the file's
content has changed.  The new file content is passed as an argument.  If you
need to do something in your plugin at this point, define the sub as a closure
over your plugin object, as demonstrated in the L</SYNOPSIS>.

B<Be careful> of infinite loops, which can result if your sub changes the same
file's content again! Add a mechanism to return without altering content if
particular conditions are met (say that the needed content is already present,
or even the value of a particular suitably-scoped variable.

=head1 METHODS

=head2 C<watch_file>

Once this method is called, every subsequent change to
the file's content will result in your C<on_changed> sub being invoked against
the file.  The new content is passed as the argument to the sub; the return
value is ignored.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-FileWatcher>
(or L<bug-Dist-Zilla-Role-FileWatcher@rt.cpan.org|mailto:bug-Dist-Zilla-Role-FileWatcher@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Role::FileWatcher> - in this distribution, for providing an interface for a plugin to watch a file

=item *

L<Dist::Zilla::File::OnDisk>

=item *

L<Dist::Zilla::File::InMemory>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
