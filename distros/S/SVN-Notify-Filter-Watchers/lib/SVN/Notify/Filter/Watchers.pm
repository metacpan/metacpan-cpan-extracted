package SVN::Notify::Filter::Watchers;

use warnings;
use strict;
use SVN::Notify;

=begin comment

Fake out Test::Pod::Coverage.

=head3 post_prepare

=head3 _walk_up

=head3 _parent

=head3 _has_watcher_property

=head3 _get_watchers

=end comment

=head1 NAME

SVN::Notify::Filter::Watchers - Subscribe to SVN::Notify commits with a Subversion property.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Use F<svnnotify> in F<post-commit>:

  svnnotify --p "$1" --r "$2" --to you@example.com --handler HTML \
  --filter Watchers

Use the class in a custom script:

  use SVN::Notify;

  my $notifier = SVN::Notify->new(
      repos_path => $path,
      revision   => $rev,
      to         => 'you@example.com',
      handler    => 'HTML::ColorDiff',
      filters    => [ 'Watchers' ],
  );
  $notifier->prepare;
  $notifier->execute;


=head1 DESCRIPTION

This L<SVN::Notify::Filter|SVN::Notify::Filter> will allow you to add
additional recipients to an email by checking a Subversion property
(default of C<svnx:watchers>, and can be overridden with
C<watcher_property> (or C<--watcher-property> option for
C<svnnotify>). The value of the watcher property is a new line and/or
space separated list of email addresses.

This filter will walk up the path to root for each path entry that has
changed and add recipients if the watcher property has been set. This
way you can in effect set the property on C</trunk> and get ALL
commits that happen below C</trunk>. When an path has been deleted it
will check the previous revision for the watcher property. You can
also set C<skip_walking_up> (C<--skip-walking-up>) to stop this
behavior.

By default the filter will then walk down the path of a deleted path
and check for recipients to add. This behavior can be changed by adding
setting C<skip_deleted_paths> (or C<--skip-deleted-paths>).

Since this is just a filter, there are certain behaviors we can't control, such
as not requiring at least on C<--to> address. Unless you have some addresses
that should get all commits, regardless of the watcher property, you may want to
set the C<--to> to some address that goes to C</dev/null> or does not bounce.
However, if you set C<trim_original_to> (C<--trim-original-to>), it will remove
the C<--to> addresses before it finds all the watcher properties.

=cut

SVN::Notify->register_attributes( watcher_property   => 'watcher-property=s',
				  skip_deleted_paths => 'skip-deleted-paths',
				  skip_walking_up    => 'skip-walking-up',
				  trim_original_to   => 'trim-original-to',
 );

my %seen;
my $defaultsvnproperty = "svnx:watchers";

sub post_prepare {
    my ($self, $to) = @_;
    if($self->trim_original_to) {
        @{$self->{to}} = ("");
    }
    my $files_ref = $self->{files};
    my $svnproperty = $self->watcher_property || $defaultsvnproperty;
    foreach my $key (keys(%$files_ref)) {
        foreach my $file(@{$files_ref->{$key}}) {
	    my $revision = $self->{revision};
	    # For Deleted items, check the version before.
	    $revision -=1 if($key eq "D");
	    if(_has_watcher_property($self, $file, $revision)) {
		$seen{$file} = 1;
		push(@$to, _get_watchers($self, $file, $revision));
	    }
	    if(!$self->skip_walking_up) {
		push(@$to, _walk_up($self, _parent($file)));
	    }
	    if($key eq "D") {
		if(!$self->skip_deleted_paths) {
		    my $fh = $self->_pipe(
			$self->{svn_encoding},
			'-|', $self->{svnlook},
			'tree',
			$self->{repos_path},
			'--full-paths',
			'-r', $revision,
			$file
			);
		    while(my $entry = <$fh>) {
			chomp($entry);
			next if ($entry eq $file);
			if(_has_watcher_property($self, $entry, $revision)) {
			    push(@$to, _get_watchers($self, $entry, $revision));
			}
		    }
		}
	    }
	}
    }

    my %hash   = map { $_, 1 } @$to;
    push(@{$self->{to}}, keys(%hash));
}

sub _walk_up {
    my $self = shift;
    my $file = shift;
    my $revision = $self->{revision};
    my @watchers;
    if(!$seen{$file}) {
	if(_has_watcher_property($self, $file, $revision)) {
	    $seen{$file} = 1;
	    push(@watchers, _get_watchers($self, $file, $revision));
	}
    }
    if($file ne _parent($file)) {
        push(@watchers, _walk_up($self, _parent($file)));
    }
    return @watchers;
}

sub _parent {
    my $file = shift;
    $file =~ m/^(.*)\//;
    if (defined($1) && length($1)) {
	return $1;
    } else {
	return '/';
    }
}

sub _has_watcher_property {
    my $self = shift;
    my $file = shift;
    my $revision = shift;
    my $svnproperty = $self->watcher_property || $defaultsvnproperty;
    my $fh = $self->_pipe(
	$self->{svn_encoding},
	'-|', $self->{svnlook},
	'proplist',
	$self->{repos_path},
	'-r', $revision,
	$file
	);
    my $rc = 0;
    while(my $line = <$fh>) {
	chomp($line);
	if ($line =~ m/$svnproperty/) {
	    $rc = 1;
	}
    }
    return $rc;
}

sub _get_watchers {
    my $self = shift;
    my $file = shift;
    my $revision = shift;
    my $svnproperty = $self->watcher_property || $defaultsvnproperty;
    my $fh = $self->_pipe(
	$self->{svn_encoding},
	'-|', $self->{svnlook},
	'propget',
	$self->{repos_path},
	'-r', $revision,
	$svnproperty,
	$file
	);
    my @watchers;
    while(my $line = <$fh>) {
	chomp($line);
	$line =~ s/^\s*(.+?)\s*/$1/;
	my @entries = split(/\s+/, $line);
	push(@watchers, @entries);
    }
    return @watchers;
}


=head1 AUTHOR

Larry Shatzer, Jr., C<< <larrysh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svn-notify-filter-watchers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Notify-Filter-Watchers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Notify::Filter::Watchers


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Notify-Filter-Watchers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Notify-Filter-Watchers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Notify-Filter-Watchers>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Notify-Filter-Watchers>

=back


=head1 ACKNOWLEDGEMENTS

David Wheeler for L<SVN::Notify|SVN::Notify>.

=head1 SEE ALSO

=over

=item L<SVN::Notify|SVN::Notify>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Larry Shatzer, Jr., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SVN::Notify::Filter::Watchers
