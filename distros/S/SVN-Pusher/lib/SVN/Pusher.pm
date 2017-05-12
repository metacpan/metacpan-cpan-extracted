package SVN::Pusher::MirrorEditor;

use strict;
use warnings;

use 5.008;

use SVN::Core;
use vars qw(@ISA);

@ISA = ('SVN::Delta::Editor');

use Data::Dumper;

use constant VSNURL => 'svn:wc:ra_dav:version-url';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub set_target_revision {
    return;
}

sub open_root {
    my ($self, $remoterev, $pool) =@_;
    $self->{root} = $self->SUPER::open_root($self->{mirror}{target_headrev}, $pool);
}

sub open_directory {
    my ($self,$path,$pb,undef,$pool) = @_;
    $self->obj->report_file($path, 'M');
    return $self->SUPER::open_directory ($path, $pb,
                     $self->{mirror}{target_headrev}, $pool);
}

sub open_file {
    my ($self,$path,$pb,undef,$pool) = @_;
    $self->obj->report_file($path, 'M');
    $self->{opening} = $path;
    return $self->SUPER::open_file ($path, $pb,
                    $self->{mirror}{target_headrev}, $pool);
}

sub change_dir_prop {
    my $self = shift;
    my $baton = shift;
    # filter wc specified stuff
    return unless $baton;
    return $self->SUPER::change_dir_prop ($baton, @_)
    unless $_[0] =~ /^svn:(entry|wc):/;
}

sub change_file_prop {
    my $self = shift;
    # filter wc specified stuff
    return unless $_[0];
    return $self->SUPER::change_file_prop (@_)
    unless $_[1] =~ /^svn:(entry|wc):/;
}

sub add_directory {
    my $self = shift;
    my $path = shift;
    my $pb = shift;
    my ($cp_path,$cp_rev,$pool) = @_;
    $self->obj->report_file($path, 'A');
    $self->SUPER::add_directory($path, $pb, @_);
}

sub apply_textdelta {
    my $self = shift;
    return undef unless $_[0];

    $self->SUPER::apply_textdelta (@_);
}

sub close_directory {
    my $self = shift;
    my $baton = shift;
    return unless $baton;
    $self->{mirror}{VSN} = $self->{NEWVSN}
    if $baton == $self->{root} && $self->{NEWVSN};
    $self->SUPER::close_directory ($baton);
}

sub close_file {
    my $self = shift;
    return unless $_[0];
    $self->SUPER::close_file(@_);
}

sub add_file {
    my $self = shift;
    my $path = shift;
    my $pb = shift;
    $self->obj->report_file($path, 'A');
    $self->SUPER::add_file($path, $pb, @_);
}

sub delete_entry {
    my ($self, $path, $rev, $pb, $pool) = @_;
    $self->obj->report_file($path, 'D');
    $self->SUPER::delete_entry ($path, $rev, $pb, $pool);
}

sub obj
{
    my $self = shift;

    return $self->{mirror};
}

#sub close_edit {
#    my ($self) = @_;
#    return unless $self->{root};
#    $self->SUPER::close_directory ($self->{root});
#    $self->SUPER::close_edit (@_);
#}


package SVN::Pusher::MyCallbacks;

use SVN::Ra;
our @ISA = ('SVN::Ra::Callbacks');

sub get_wc_prop {
    my ($self, $relpath, $name, $pool) = @_;
    return undef unless $self->{editor}{opening};
    return undef unless $name eq 'svn:wc:ra_dav:version-url';
    return join('/', $self->{mirror}{VSN}, $relpath)
    if $self->{mirror}{VSN} &&
        $self->{editor}{opening} eq $relpath; # skip add_file

    return undef;
}

# ------------------------------------------------------------------------

package SVN::Pusher ;

our $VERSION = '0.09';
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use SVN::Delta;
use SVN::Ra;
use SVN::Client ();
use Data::Dumper ;
use strict;

=head1 NAME

SVN::Pusher - Propagate changesets between two different svn repositories.

=head1 SYNOPSIS

    my $m =
        SVN::Pusher->new(
            source => $sourceurl,
            target => $desturl',
            startrev => 100,
            endrev   => 'HEAD',
            logmsg   => 'push msg'
            );

    $m->init();

    $m->run();

=head1 DESCRIPTION

See perldoc bin/svn-pusher for more documentation.

=cut

use File::Spec;
use URI::Escape;

# ------------------------------------------------------------------------

sub report
{
    # Do nothing by default
}

sub report_msg
{
    my $self = shift;
    my $msg = shift;
    return $self->report({'op' => 'msg', 'msg' => $msg });
}

sub report_file {
    my ($self, $path, $op) = @_;
    if ($self->{verbose}) {
	$self->report({'op' => "file", 'file_op' => $op, 'path' => $path});
    }
}

sub committed {
    my ($self, $date, $sourcerev, $rev, undef, undef, $pool) = @_;
    my $cpool = SVN::Pool->new_default ($pool);

    if ($self->{savedate})
    {
        $self->{target_update_ra}->change_rev_prop($rev, 'svn:date', $date)
    }
    #$self->{rarepos}->change_rev_prop($rev, 'svn:date', $date);
    #$self->{rarepos}->change_rev_prop($rev, "svm:target_headrev$self->{source}",
    #                 "$sourcerev",);
    #$self->{rarepos}->change_rev_prop($rev, "svm:vsnroot:$self->{source}",
    #                 "$self->{VSN}") if $self->{VSN};

    $self->{target_headrev} = $rev;
    $self->{target_source_rev} = $sourcerev ;
    $self->{commit_num}++ ;

    $self->report_msg("Committed revision $rev from revision $sourcerev.");
}
# ------------------------------------------------------------------------

sub mirror
    {
    my ($self, $paths, $rev, $author, $date, $msg, $ppool) = @_;


    my $pool = SVN::Pool->new_default ($ppool);

    my $tra = $self->{target_update_ra} ||= SVN::Ra->new(url => $self->{target},
              auth   => $self->{auth},
              pool   => $self->{pool},
              config => $self->{config},
              );


    $msg = $self -> {logmsg} eq '-'?'':$self -> {logmsg} if ($self -> {logmsg}) ;
    my $def_msg =
        defined($msg)
            ?  ( $msg . ($self->{verbatim} ? "" : "\n") )
            : '';

    my $full_msg = $def_msg
        . ($self->{verbatim} ? "" : ":$rev:$self->{source_uuid}:$date:");

    my $editor = SVN::Pusher::MirrorEditor->new
    ($tra->get_commit_editor(
        $full_msg
        ,
      sub { $self->committed($date, $rev, @_) },
        undef, 0));

    $editor->{mirror} = $self;


    my $sra = $self->{source_update_ra} ||= SVN::Ra->new(url => $self->{source},
              auth   => $self->{auth},
              pool   => $self->{pool},
              config => $self->{config},
              );

    my $reporter =
        $sra->do_update ($rev+1, '' , 1, $editor);

    $reporter->set_path ('', $rev,
        # $self->{target_source_rev}?0:1,
        0,
        undef);
    $reporter->finish_report ();
    }

# ------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $self = ref $class?bless {@_}, ref $class:bless {@_}, $class;

    $self->{pool}   ||= SVN::Pool->new_default (undef);
    $self->{config} ||= SVN::Core::config_get_config(undef, $self->{pool});
    $self->{auth}   ||= SVN::Core::auth_open ([SVN::Client::get_simple_provider,
                  SVN::Client::get_ssl_server_trust_file_provider,
                  SVN::Client::get_ssl_client_cert_file_provider,
                  SVN::Client::get_ssl_client_cert_pw_file_provider,
                  SVN::Client::get_username_provider]);

    return $self;
}

# ------------------------------------------------------------------------

sub do_init
    {
    my $self = shift;

    $self->{source_ra} = SVN::Ra->new(url => $self->{source},
              auth   => $self->{auth},
              pool   => $self->{pool},
              config => $self->{config},
              #callback => 'SVN::Pusher::MyCallbacks'
              );
    $self->{source_headrev} = $self->{source_ra}->get_latest_revnum;
    $self->{source_root}    = $self -> {source_ra} -> get_repos_root ;
    $self->{source_path}    = substr ($self -> {source}, length ($self->{source_root})) || '/' ;
    $self->{source_uuid}    = $self -> {source_ra}->get_uuid ();

    $self->report_msg("Source: $self->{source}");
    $self->report_msg("  Revision: $self->{source_headrev}");
    $self->report_msg("  Root:     $self->{source_root}");
    $self->report_msg("  Path:     $self->{source_path}");

    $self->{target_ra} = SVN::Ra->new(url => $self->{target},
              auth   => $self->{auth},
              pool   => $self->{pool},
              config => $self->{config},
              );


    $self->{target_headrev} = $self->{target_ra}->get_latest_revnum;
    $self->{target_root}    = $self -> {target_ra} -> get_repos_root ;

    $self->{target_path}    = substr ($self -> {target}, length ($self->{target_root})) ||'/' ;

    $self->report_msg( "Target: $self->{target}") ;
    $self->report_msg("  Revision: $self->{target_headrev}") ;
    $self->report_msg("  Root:     $self->{target_root}") ;
    $self->report_msg("  Path:     $self->{target_path}") ;

    return 1 ;
    }

# ------------------------------------------------------------------------

# This method is essentialy do_init(). In the original SVN::Push there were
# both init() and do_init() which were different from a reason. Here, they
# are essentially the same.
sub init
{
    my $self = shift;

    return $self -> do_init ;
}

# ------------------------------------------------------------------------

sub run {
    my $self   = shift;

    my $endrev = $self->{endrev} || $self -> {source_headrev} ;
    if ($self->{endrev} && $self->{endrev} eq 'HEAD')
    {
        $endrev = $self->{source_headrev};
    }
    if ($endrev > $self -> {source_headrev})
    {
        $endrev = $self->{source_headrev};
    }
    $self->{endrev} = $endrev ;

    my $startrev = $self->{startrev} || 0 ;
    if (defined($self->{target_source_rev}) &&
        ($self->{target_source_rev} + 1 > $startrev))
    {
        $startrev = $self->{target_source_rev} + 1;
    }
    $self->{startrev} = $startrev ;

    return unless $endrev == -1 || $startrev <= $endrev;

    $self->report_msg("Retrieving log information from $startrev to $endrev");

    $self -> {source_ra} -> get_log (
        # paths
        [''],
        # start_rev
        $startrev,
        # end_rev
        $endrev-1,
        # limit
        0,
        # discover_changed_paths
        1,
        # strict_node_history
        1,
        # receiver + receiver_baton
          sub {
              my ($paths, $rev, $author, $date, $msg, $pool) = @_;

              eval {
              $self->mirror($paths, $rev, $author,
                    $date, $msg, $pool); } ;
              if ($@)
                  {
                  my $e = $@ ;
                  $e =~ s/ at .+$// ;
                  $self->report_msg($e) ;
                  }
          });
}

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Pusher>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Pusher

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN::Pusher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN::Pusher>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN::Pusher>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN::Pusher/>

=back

=head1 SOURCE AVAILABILITY

The latest source of SVN::Pusher is available from its
BerliOS Subversion repository:

L<http://svn.berlios.de/svnroot/repos/web-cpan/SVN-Pusher/>

=head1 AUTHORS

Shlomi Fish ( L<http://www.shlomifish.org/> ).

(based on SVN::Push by Gerald Richter E<lt>richter@dev.ecos.deE<gt>)

=head1 CREDITS

Original SVN::Push module by Gerald Richter. Modified into SVN::Pusher
by Shlomi Fish.

A lot of ideas and code were taken from the SVN::Mirror module which is by
Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Gerald Richter E<lt>richter@dev.ecos.deE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
