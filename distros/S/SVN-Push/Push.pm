#!/usr/bin/perl
use SVN::Core;

package SVN::Push::MirrorEditor;

@ISA = ('SVN::Delta::Editor');

use strict;
use Data::Dumper ;

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
    print "U  $path\n" ;
    return $self->SUPER::open_directory ($path, $pb,
					 $self->{mirror}{target_headrev}, $pool);
}

sub open_file {
    my ($self,$path,$pb,undef,$pool) = @_;
    print "U  $path\n" ;
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
    print "A  $path\n" ;
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
    print "A  $path\n" ;

    $self->SUPER::add_file($path, $pb, @_);
}

sub delete_entry {
    my ($self, $path, $rev, $pb, $pool) = @_;
    print "D  $path\n" ;
    $self->SUPER::delete_entry ($path, $rev, $pb, $pool);
}

sub close_edit {
    my ($self) = @_;
    return unless $self->{root};
    $self->SUPER::close_directory ($self->{root});
    $self->SUPER::close_edit (@_);
}


package SVN::Push::MyCallbacks;

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

package SVN::Push ;

our $VERSION = '0.02';
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use SVN::Delta;
use SVN::Ra;
use SVN::Client ();
use Data::Dumper ;
use strict;

=head1 NAME

SVN::Push - Push Repository to Remote Subversion Repository

=head1 SYNOPSIS

my $m = SVN::Push->new   (source => $sourceurl,
			  target => $desturl',
			  startrev => 100,
			  endrev   => 'HEAD',
			  logmsg   => 'push msg'
			  );

$m->init

$m->run

=head1 DESCRIPTION

see perldoc bin/svnpush for more documentation

=cut

use File::Spec;
use URI::Escape;



sub is_mirrored {
    my ($repos, $path) = @_;

    my $m = SVN::Push->new(target_path => $path,
			     repos => $repos,
			     pool => SVN::Pool->new,
			     get_source => 1) or die $@;
    eval { $m->init };
    return if $@;
    return $m;
}

# ------------------------------------------------------------------------


sub committed {
    my ($self, $date, $sourcerev, $rev, undef, undef, $pool) = @_;
    my $cpool = SVN::Pool->new_default ($pool);

    #$self->{rarepos}->change_rev_prop($rev, 'svn:date', $date);
    #$self->{rarepos}->change_rev_prop($rev, "svm:target_headrev$self->{source}",
    #				 "$sourcerev",);
    #$self->{rarepos}->change_rev_prop($rev, "svm:vsnroot:$self->{source}",
    #				 "$self->{VSN}") if $self->{VSN};

    $self->{target_headrev} = $rev;
    $self->{target_source_rev} = $sourcerev ;
    $self->{commit_num}++ ;

    print "Committed revision $rev from revision $sourcerev.\n";
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
    
    my $editor = SVN::Push::MirrorEditor->new
	($tra->get_commit_editor(
	  ($msg?"$msg\n":'') . ":$rev:$self->{source_uuid}:$date:",
	  sub { $self->committed($date, $rev, @_) }));

    $editor->{mirror} = $self;

    
    my $sra = $self->{source_update_ra} ||= SVN::Ra->new(url => $self->{source},
			  auth   => $self->{auth},
			  pool   => $self->{pool},
			  config => $self->{config},
			  );

    #$ra->{callback}{mirror} = $self;
    #$ra->{callback}{editor} = $editor;


    my $reporter =
    	$sra->do_update ($rev, '' , 1, $editor);

    my $start = $self->{target_source_rev} || $rev ;
    $reporter->set_path ('', $start, $self->{target_source_rev}?0:1);
    $reporter->finish_report ();
    }

# ------------------------------------------------------------------------


sub get_merge_back_editor {
    my ($self, $msg, $committed) = @_;
    # get ra commit editor for $self->{source}
    my $ra = SVN::Ra->new(url => $self->{source},
			  auth => $self->{auth},
			  pool => $self->{pool},
			  config => $self->{config},
			  callback => 'SVN::Push::MyCallbacks');
    my $youngest_rev = $ra->get_latest_revnum;

    return ($youngest_rev,
	    SVN::Delta::Editor->new ($ra->get_commit_editor ($msg, $committed)));
}

# ------------------------------------------------------------------------

sub mergeback {
    my ($self, $fromrev, $path, $rev) = @_;

    # verify $path is copied from $self->{target_path}

    # concat batch merge?
    my $msg = $self->{fs}->revision_prop ($rev, 'svn:log');
    $msg .= "\n\nmerged from rev $rev of repository ".$self->{fs}->get_uuid;

    my $editor = $self->get_merge_back_editor ($msg,
					       sub {warn "committed via RA"});

    # dir_delta ($path, $fromrev, $rev) for commit_editor
    SVN::Repos::dir_delta($self->{fs}->revision_root ($fromrev), $path,
			  $SVN::Core::VERSION ge '0.36.0' ? '' : undef,
			  $self->{fs}->revision_root ($rev), $path,
			  $editor, undef,
			  1, 1, 0, 1
			 );
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
			  #callback => 'SVN::Push::MyCallbacks'
			  );
    $self->{source_headrev} = $self->{source_ra}->get_latest_revnum;
    $self->{source_root}    = $self -> {source_ra} -> get_repos_root ;
    $self->{source_path}    = substr ($self -> {source}, length ($self->{source_root})) || '/' ;
    $self->{source_uuid}    = $self -> {source_ra}->get_uuid ();

    if ($self->{source_path} ne '/')
	{
        my $result = $self->{source_ra} -> get_file ('', -1, undef) ;
        $self->{source_lastrev} = $result ->[1]{'svn:entry:committed-rev'} ; 
	}
    else
        {
        $self->{source_lastrev} = $self->{source_headrev} ; 
        }

    print "Source: $self->{source}\n" ;
    print "  Revision: $self->{source_headrev}\n" ; 
    print "  Root:     $self->{source_root}\n" ;
    print "  Path:     $self->{source_path} (rev: $self->{source_lastrev})\n" ; 

    $self->{target_ra} = SVN::Ra->new(url => $self->{target},
			  auth   => $self->{auth},
			  pool   => $self->{pool},
			  config => $self->{config},
			  );
    
    
    $self->{target_headrev} = $self->{target_ra}->get_latest_revnum;
    $self->{target_root}    = $self -> {target_ra} -> get_repos_root ;
    
    $self->{target_path}    = substr ($self -> {target}, length ($self->{target_root})) ||'/' ;
    
    print "Target: $self->{target}\n" ;
    print "  Revision: $self->{target_headrev}\n" ; 
    print "  Root:     $self->{target_root}\n" ;
    print "  Path:     $self->{target_path}\n" ; 
    
    eval {
        $self -> {target_ra}->get_log ([$self->{target_path}], 
                                    $self->{target_headrev}, 
                                    0, 
				    0, 1,
		  sub {
		      my ($paths, $rev, $author, $date, $msg, $pool) = @_;
                      return if ($self -> {target_source_rev} || !$msg) ;
		      $msg =~ /:(\d+):(.+?):.*?:$/s ;
                      $self -> {target_source_rev} = $1 || 0 ;
                      $self -> {target_source_uuid} = $2 || '' ;
                      #print "$msg\n" ;
		  });
        } ;
    if ($@)
        {
        print $@ ;
        if ($@ =~ /Path Not Found/)
            {
            return -3 ;
            }
        else
            {
            return -4 ;
            }
        }        
  
    $self->{target_source_rev} = 0 if (!$self->{target_source_rev} || $self->{target_source_rev} < 0) ;
        
    my $ret ;
    if (!$self -> {target_source_uuid})
        {
        print "Target is not initialized\n" ;
        $ret = -1 ;
        }
    elsif ($self->{source_uuid} ne $self -> {target_source_uuid})
        {
        print "Target is from different source\n" ;
        $ret = -2 ;
        }
    else
        {
        if ($self->{target_source_rev} == $self->{source_headrev})
            {
            print "Target is up to date\n" ;
            $ret = 0 ;
            }
        else
            {
            print "Target is up to source revision $self->{target_source_rev}\n" ;
            $ret = 1 ;
            }    
        }

    
    return $ret ;
    }

# ------------------------------------------------------------------------
    
sub init 
    {
    my $self = shift;
    my $create = shift ;
    
    my $rc = $self -> do_init ;
    if ($rc == -1 && $self -> {target_path} eq '/' && $create)
        {
        return 1 ;
        }
        
    if ($rc == -3 && $create)
        {
        $self -> create_target ;
        $rc = $self -> do_init ;
        }
    
    return $rc ;
    }    

# ------------------------------------------------------------------------

sub create_target 
    {
    my ($self) = @_ ;
   
    
    my $ra = SVN::Ra->new(url => $self -> {source},
 			  auth => $self -> {auth},
 			  config => $self -> {config});
    
    my $uuid = $ra->get_uuid ();
    #print "source: $source\ntarget: $target\nuuid:   $uuid\n" ;
    my $ctx = SVN::Client -> new (
 			  auth => $self -> {auth},
 			  config => $self -> {config},
            log_msg => sub { ${$_[0]} = ":0:$uuid:-:" }) ;
    
    $ctx -> mkdir ([$self -> {target}]) ;
    print "$self->{target} successfully created\n" ;
    }

# ------------------------------------------------------------------------

sub walk 
    {
    my ($source, $target, $pattern, $repositories, $create, $logmsg) = @_ ;
   
    my $self = SVN::Push -> new ;
    $source =~ s#/$## ;
    $target =~ s#/$## ;

    $repositories ||= [''] ;
    my $ctx = SVN::Client -> new (  auth    => $self -> {auth}, 
                                    config  => $self -> {config}) ;
    
    foreach my $repository (@$repositories)
        {
        my $repos = $repository?"/$repository":'' ;
        my $files = $ctx -> ls ("$source$repos", 'HEAD', 0) ;
        if ($pattern)
            {
            foreach my $file (sort keys %$files)
                {
                next if ($file !~ /$pattern/) ;
                print "*** Process $source$repos/$file\n" ;
                eval {
                    my $push = $self -> new (source => "$source$repos/$file", 
                                             target => "$target$repos/$file",
                                             logmsg => $logmsg) ;
                    if ($push -> init ($create) > 0)
                        {
                        $push -> run ;
                        }
                    } ;                
                print $@ if ($@) ;
                }
            }
        else
            {
            print "*** Process $source$repos\n" ;
            eval {
                my $push = $self -> new (source => "$source$repos", 
                                         target => "$target$repos",
                                         logmsg => $logmsg) ;
                if ($push -> init ($create) > 0)
                    {
                    $push -> run ;
                    }
                } ;                
            print $@ if ($@) ;
            }       
        }    
    }

# ------------------------------------------------------------------------

sub run {
    my $self   = shift;

    my $endrev = $self->{endrev} || $self -> {source_headrev} ;
    $endrev = $self -> {source_headrev} if ($self->{endrev} && $self->{endrev} eq 'HEAD') ;
    $endrev = $self -> {source_headrev} if ($endrev > $self -> {source_headrev}) ;
    $self->{endrev} = $endrev ;
    
    my $startrev = $self->{startrev} || 0 ;
    $startrev = $self -> {source_lastrev} if ($self->{startrev} && $self->{startrev} eq 'HEAD') ;
    $startrev = $self -> {target_source_rev} + 1 if ($self -> {target_source_rev} + 1 > $startrev) ;
    $self->{startrev} = $startrev ;
    
    return unless $endrev == -1 || $startrev <= $endrev;

    print "Retrieving log information from $startrev to $endrev\n";

    $self -> {source_ra} -> get_log ([''], $startrev, $endrev, 0, 1,
		  sub {
		      my ($paths, $rev, $author, $date, $msg, $pool) = @_;

		      eval {
		      $self->mirror($paths, $rev, $author,
				    $date, $msg, $pool); } ;
		      if ($@)
		          {
		          my $e = $@ ;
		          $e =~ s/ at .+$// ;
		          print $e ; 
		          }
		  });
}


=head1 AUTHORS

Gerald Richter E<lt>richter@dev.ecos.deE<gt>

=head1 CREDITS

A lot of ideas and code is taken from SVN::Mirror by
Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Gerald Richter E<lt>richter@dev.ecos.deE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
