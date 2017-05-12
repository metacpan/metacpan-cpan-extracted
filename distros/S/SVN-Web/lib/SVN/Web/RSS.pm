package SVN::Web::RSS;
use strict;
use warnings;

use base 'SVN::Web::Log';

our $VERSION = 0.54;

=head1 NAME

SVN::Web::RSS - SVN::Web action to generate an RSS feed

=head1 SYNOPSIS

In F<config.yaml>

  actions:
    ...
    rss:
      class: SVN::Web::RSS
      action_menu:
        show:
          - file
          - directory
        link_text: (rss)
        head_only: 1
        icon: /css/trac/feed-icon-16x16.png
      opts:
        publisher: address@domain
    ...

=head1 DESCRIPTION

Generates an RSS feed of commits to a file or path in the Subversion
repository.

=head1 CONFIGURATION

The following options may be specified in F<config.yaml>.

=over

=item publisher

The e-mail address of the feed's publisher.  This is placed in to the
C<< <dc:publisher> >> element in the RSS output.

There is no default.  If not specified then no C<< <dc:publisher> >>
element is included.

=back

B<Note:> RSS dates have a specific format.  Accordingly, the C<timezone>
and C<timedate_format> configuration options are ignored by this action.

=head1 OPTIONS

See L<SVN::Web::Log>.

=head1 TEMPLATE VARIABLES

See L<SVN::Web::Log>.

=head1 EXCEPTIONS

See L<SVN::Web::Log>.

=cut

my %default_opts = ( publisher => '' );

# <dc:date> elements have a specific format that we must use, overriding
# the user's choice
sub format_svn_timestamp {
    my $self    = shift;
    my $cstring = shift;

    my $time = SVN::Core::time_from_cstring($cstring) / 1_000_000;

    return POSIX::strftime( '%Y-%m-%dT%H:%M:%S', gmtime($time) );
}

sub run {
    my $self = shift;

    my $data = $self->SUPER::run(@_)->{data};

    $self->{opts} = { %default_opts, %{ $self->{opts} } };

    return {
        template => 'rss',
        mimetype => 'text/xml',
        data     => { %{$data}, publisher => $self->{opts}{publisher}, }
    };
}

1;

=head1 COPYRIGHT

Copyright 2003-2004 by Chia-liang Kao C<< <clkao@clkao.org> >>.

Copyright 2005-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

Copyright 2012 by Dean Hamstead C<< <dean@fragfest.com.au> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
