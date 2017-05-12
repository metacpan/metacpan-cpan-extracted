package SVN::Web::action;

use strict;
use warnings;

our $VERSION = 0.63;

use Encode;
use File::Temp ();
use POSIX ();
use Time::Local qw(timegm_nocheck);
use Time::Zone ();

use SVN::Core;

=head1 NAME

SVN::Web::action - base class for SVN::Web::actions

=head1 DESCRIPTION

This is the base class for all SVN::Web actions.  It provides a
constructor and some useful utility methods that actions may find
useful.  It also contains documentation for anyone interested in
writing new SVN::Web actions.

=head1 OVERVIEW

SVN::Web actions are Perl modules loaded by SVN::Web.  They are
expected to retrieve some information from the Subversion repository,
and return that information ready for the user's browser, optionally
via formatting by a Template::Toolkit template.

Action names are listed in the SVN::Web configuration file,
F<config.yaml>, in the C<actions:> clause.  Each entry specifies the
class that implements the action, options that are set globally
for that action, and metadata that describes when and how the action
should appear in the action menu.

  actions:
    ...
    new_action:
      class: Class::That::Implements::Action
      action_menu:            # Optional
        show:
          - file              # Zero or more of this, ...
          - directory         # ... this ...
          - revision          # ... or this.
          - global            # Or possibly just this one
        link_text: (text)     # Mandatory
        head_only: 1          # Optional
        icon: /a/path         # Optional
      opts:
        option1: value1
        option2: value2
    ...

Each action is a class that must implement a C<run()> method.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = @_;

    return $self;
}

=head1 SUBCLASSING

Actions should derive from L<SVN::Web::action>.  This gives them a
default constructor that generates a hash based object.

  use base 'SVN::Web::action';

=head1 METHODS

=head2 run()

The C<run> method is where the action carries out its work.

=head3 Parameters

The method is passed a single parameter, the standard C<$self> hash
ref.  This contains numerous useful keys.

=over 4

=item $self->{opts}

The options for this action from F<config.yaml>.  Using the example from the
L<OVERVIEW>, this would lead to:

  $self->{opts} = { 'option1' => 'value1',
                    'option2' => 'value2',
                  };

=item $self->{cgi}

An instance of a CGI compatible object corresponding to the current request.  This is normally an object from either the L<CGI> or L<CGI::Fast> modules, although it is possible to specify another class with the C<cgi_class> directive in
F<config.yaml>. Since we now use Plack, this is a L<Plack::Request> object.

You can use this object to retrieve the values of any parameters passed to
your action.

For example, if your action takes a C<rev> parameter, indicating the
repository revision to work on;

  my $rev = $self->{cgi}->param('rev');

=item $self->{path}

The path in the repository that was passed to the action.

=item $self->{navpaths}

A reference to an array of path components, one for each directory
(and possible final file) in $self->{path}.  Equivalent to S<C<< [
split('/', $self->{path}) ] >>>

=item $self->{config}

The config hash, as read by L<YAML> from F<config.yaml>.  Directives
from the config file are second level hash keys.  For example, the
C<actions> configuration directive contains a list of valid actions.

  my @valid_actions = @{ $self->{config}->{actions} };

=item $self->{reposname}

The symbolic name of the repository being accessed.

=item $self->{repos}

A instance of the L<SVN::Repos> class, corresponding to the repository
being accessed.  This repository has already been opened.

For example, to find the youngest (i.e., most recent) revision of the
repository;

  my $yr = $self->{repos}->fs()->youngest_rev();

=item $self->{action}

The action that has been requested.  It's possible for multiple action
names to be mapped to a single class in the config file, and this lets
you differentiate between them.

=item $self->{script}

The URL for the currently running script.

=back

=head3 Return value

The return value from C<run()> determines how the data from the action is
displayed.

=head4 Using a template

If C<run()> wants a template to be displayed containing formatted data
from the method then the hash ref should contain two keys.

=over 4

=item template

This is the name of the template to return.  By convention the template and
the action share the same name.

=item data

This is a hash ref.  The hash keys become variables of the same name in the
template.

=back

The character set and MIME type can also be specified, in the
C<charset> and C<mimetype> keys.  If these values are not specified
then they default to C<UTF-8> and C<text/html> respectively.

E.g., for an action named C<my_action>, using a template called
C<my_action> that looks like this:

  <p>The youngest interesting revision of [% file %] is [% rev %].</p>

then this code would be appropriate.

  # $rev and $file set earlier in the method
  return { template => 'my_action',
           data     => { rev  => $rev,
                         file => $file,
                       },
         };

=head4 Returning data with optional charset and MIME type

If the action does not want to use a template and just wants to return
data, but retain control of the character set and MIME type, C<run()>
should return a hash ref.  This should contain a key called C<body>,
the value of which will be sent directly to the browser.

The character set and MIME type can also be specified, in the
C<charset> and C<mimetype> keys.  If these values are not specified
then they default to C<UTF-8> and C<text/html> respectively.

E.g., for an action that generates a PNG image from data in the
repository (perhaps using L<SVN::Churn>);

  # $png contains the PNG image, created earlier in the method
  return { mimetype => 'image/png',
           body     => $png
         };

=head4 Returning HTML with default charset and MIME type

If the action just wants to return HTML in UTF-8, it can return a single
scalar that contains the HTML to be sent to the browser.

  return "<p>hello, world</p>";

=head1 UTILITY METHODS

The following methods are intended to share common code among actions.

=head2 recent_interesting_rev($path, $rev)

Given a repository path, and a revision number, returns the most recent
interesting revision for the path that is the same as, or older (i.e.,
smaller) than the revision number.

If called in an array context it returns all the arguments normally passed
to a log message receiver.

=cut

sub recent_interesting_rev {
    my ($self, $path, $rev) = @_;

    my $ra = $self->{repos}{ra};

    my @log_result;

    $ra->get_log( [ Encode::encode('utf8',$self->rpath($path)) ], $rev, 1, 1, 0, 1, sub { @log_result = @_; } );

    return @log_result if wantarray();
    return $log_result[1];    # Revision number
}

=head2 get_revs()

Returns a list of 4 items.  In order, they are:

=over

=item Explicit rev

The value of any CGI C<rev> parameter passed to the action ($exp_rev).

=item Youngest rev

The repository's youngest revision ($yng_rev) for the current path.
This is not necessarily the same as the repositories youngest
revision.

=item Actual rev

The actual revision ($act_rev) that will be acted on.  This is the
explicit rev, if it's defined, otherwise it's the youngest rev.

=item Head

A boolean value indicating whether or not we can be considered to be
at the HEAD of the repository ($at_head).

=back

=cut

sub get_revs {
    my $self = shift;
    my $path = $self->{path};

    my $exp_rev = $self->{cgi}->param('rev');
    my $yng_rev = $self->{repos}{ra}->get_latest_revnum();
    my $act_rev =
      defined $exp_rev
      ? $self->recent_interesting_rev( $path, $exp_rev )
      : $self->recent_interesting_rev( $path, $yng_rev );

    my $at_head = 0;
    if ( !defined $exp_rev or $exp_rev eq '' ) {
        $at_head = 1;
    }
    else {
        if ( $exp_rev == $yng_rev ) {
            $at_head = 1;
        }
    }
    return ( $exp_rev, $yng_rev, $act_rev, $at_head );
}

=head2 format_svn_timestamp()

Given a cstring that represents a Subversion time, format the time using
POSIX::strftime() and the current settings of the C<timedate_format> and
C<timezone> configuration directives.

=cut

my $tz_offset = undef;    # Cache the timezone offset

sub format_svn_timestamp {
    my $self    = shift;
    my $cstring = shift;

    # Note: Buggy on Solaris
    # my $time = SVN::Core::time_from_cstring($cstring) / 1_000_000;
    my (@time) = $cstring =~ /^(....)-(..)-(..)T(..):(..):(..)/;

    my $time =
      timegm_nocheck( $time[5], $time[4], $time[3], $time[2], $time[1] - 1,
        $time[0] );

    if ( $self->{config}->{timezone} eq 'local' ) {
        return POSIX::strftime( $self->{config}->{timedate_format},
            localtime($time) );
    }

    if ( ( not defined $tz_offset ) and ( $self->{config}->{timezone} ne '' ) )
    {
        $tz_offset = Time::Zone::tz_offset( $self->{config}->{timezone} );
        $time += $tz_offset;
    }

    return POSIX::strftime( $self->{config}->{timedate_format}, gmtime($time) );
}

=head1 CACHING

If the output from the action can usefully be cached then consider
implementing a C<cache_key> method.

This method receives the same parameters as the C<run()> method, and
must use those parameters to generate a unique key for the content
generated by the C<run()> method.

For example, consider the standard C<Revision> action.  This action
only depends on a single parameter -- the repository revision number.
So that makes a good cache key.

  sub cache_key {
      my $self = shift;

      return $self->{cgi}->param('rev');
  }

Other actions may have more complicated keys.

=head1 ERRORS AND EXCEPTIONS

If your action needs to fail for some reason -- perhaps the parameters
passed to it are incorrect, or the user lacks the necessary permissions,
then throw an exception.

Exceptions, along with examples, are described in L<SVN::Web::X>.

=head1 COPYRIGHT

Copyright 2005-2007 by Nik Clayton C<< <nik@FreeBSD.org> >>.

Copyright 2012 by Dean Hamstead C<< <dean@fragfest.com.au> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

sub rpath {
    my ( $self, $p ) = @_;
    my $path = $p || $self->{path};
    $path =~ s{^/}{} if $path;
    return $path
}

sub svn_get_node_kind {
    my ($self, $uri, $peg_revision, $revision, $pool) = @_;

    my $node_kind;

    my @args = ($self->encode_svn_uri($uri), $peg_revision, $revision, sub { $node_kind = $_[1]->kind() }, 0);
    push @args, $pool if $pool;
    $self->{repos}{client}->info(@args);

    return $node_kind;
}

sub svn_get_diff {
    my ($self, $target1, $rev1, $target2, $rev2, $recursive, $pool) = @_;

    my ( $out_h, $out_fn ) = File::Temp::tempfile();
    my ( $err_h, $err_fn ) = File::Temp::tempfile();

    my @args = ([], $self->encode_svn_uri($target1), $rev1, $self->encode_svn_uri($target2), $rev2, $recursive, 1, 0, $out_h, $err_h);
    push @args, $pool if $pool;
    $self->{repos}{client}->diff(@args);

    my $out;
    local $/ = undef;
    seek($out_h, 0, 0);
    $out = <$out_h>;
    unlink( $out_fn ); unlink( $err_fn );
    close( $out_h ); close( $err_h );

    return $out;
}

sub ctx_ls {
    my ($self, $uri) = splice(@_, 0, 2);
    return $self->{repos}{client}->ls( $self->encode_svn_uri($uri), @_ );
}

sub ctx_revprop_get {
    my ($self, $prop_name, $uri, $rev) = splice(@_, 0, 4);
    return $self->{repos}{client}->revprop_get( $prop_name, $self->encode_svn_uri($uri), $rev, @_ );
}

sub ctx_propget {
    my ($self, $prop_name, $uri, $rev, $recursive) = splice(@_, 0, 5);
    return $self->{repos}{client}->propget( $prop_name, $self->encode_svn_uri($uri), $rev, $recursive, @_ );
}

sub ctx_cat {
    my ($self, $fh, $uri, $rev) = splice(@_, 0, 4);
    return $self->{repos}{client}->cat( $fh, $self->encode_svn_uri($uri), $rev, @_ );
}

sub ctx_blame {
    my ($self, $uri, $start_rev, $end_rev, $cb) = splice(@_, 0, 5);
    return $self->{repos}{client}->blame( $self->encode_svn_uri($uri), $start_rev, $end_rev, $cb, @_ );
}

sub encode_svn_uri {
    my $uri = Encode::encode('utf8', $_[1]);
    # same as in svn_path_uri_encode (see subversion/libsvn_subr/path.c)
    $uri =~ s#([^\-\!\$\&\'\(\)\*\+\,\.\/\:\=\@\~\_0-9A-Za-z])#sprintf("%%%02X",ord($1))#eg;
    return $uri;
}

sub decode_svn_uri {
    my ($self, $uri) = @_;
    $uri =~ s#%([0-9A-Fa-f]{2})#chr(hex($1))#eg;
    return Encode::decode('utf8', $uri);
}

1;
