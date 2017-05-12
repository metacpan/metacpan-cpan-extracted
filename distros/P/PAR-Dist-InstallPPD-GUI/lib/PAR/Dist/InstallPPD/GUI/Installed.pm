package PAR::Dist::InstallPPD::GUI::Installed;
use strict;
use warnings;

use ExtUtils::Installed;
use Tk::HList;
use Tk::Dialog;
use IO::Dir;
our $VERSION = '0.05';


sub _init_installed_tab {
    my $self = shift;
    my $fr = $self->{tabs}{installed}->Frame()->pack(qw/-side top -fill both -expand 1/);

    $self->{installed} = {};

    my $afr = $fr->Frame()->pack(qw/-side top -fill x/);
    my $remove_button = $afr->Button(
        -text => 'Uninstall Selected Module', -command => [$self, '_uninstall_module_gui'],
    )->pack(qw/-side left -padx 4/);
    $afr->Label(-text=>'Filter Display:')->pack(qw/-side left -padx 4/);
    $self->{installed}{module_display_filter} = $afr->Entry(
        qw/-width 10 -background white -validate key/,
        qw/-validatecommand/ => [$self, '_installed_modules_filter_hook'],
    )->pack(qw/-side left -padx 4/);

    $fr->Label(-text => 'Installed modules:')->pack(qw/-side top -fill x -pady 3/);

    my $modules = $self->{installed}{modules} = $fr->Scrolled(
        'HList', qw/-scrollbars osoe/,
        qw/-columns 2 -header 1 -height 9 -background white/,
        '-browsecmd' => [$self, '_display_installed_files']
    )->pack(qw/-side top -fill both -expand 1 -padx 4/);
    $modules->header('create', 0, -text => 'Module');
    $modules->header('create', 1, -text => 'Version');

    $fr->Label(-text => 'Files of selected module:')->pack(qw/-side top -fill x -pady 3/);

    my $files = $self->{installed}{files} = $fr->Scrolled(
        'HList', qw/-scrollbars osoe/,
        qw/-columns 1 -header 1 -height 7 -background white/,
    )->pack(qw/-side top -fill both -expand 1 -padx 4/);
    $files->header('create', 0, -text => 'Path');

}

sub _installed_modules_filter_hook {
    my $self = shift;
    my $regex = shift;
    my $change = shift;

    # Don't refresh if invalid.
    my $r;
    eval {$r = qr/$regex/;};
    return 1 if $@ or not defined $r;

    $self->_populate_installed_modules_list(defined($regex) ? $regex : '');

    return 1;
}

sub _raise_installed {
    my $self = shift;
    $self->_status('Searching for installed modules...');
    my $inst = $self->{installed}{extutils_installed} = ExtUtils::Installed->new();

    $self->_populate_installed_modules_list();

    $self->_status('');
    return 1;
}

sub _populate_installed_modules_list {
    my $self = shift;
    my $filter_re = shift;

    $self->_status('Populating list of installed modules...');

    $self->{installed}{module_display_filter}->configure(qw/-state readonly/);

    my $inst = $self->{installed}{extutils_installed} ||= ExtUtils::Installed->new();

    my $hlist = $self->{installed}{modules};
    $hlist->delete('all');
    $self->{installed}{files}->delete('all');
    $self->{installed}{current_module} = undef;

    $filter_re = $self->{installed}{module_display_filter}->get() if not defined $filter_re;
    $filter_re = '.' if not defined $filter_re or $filter_re eq '';
    eval {$filter_re = qr/$filter_re/;};
    if ($@) {
        $filter_re = qr/./;
    }

    my $i = 0;
    foreach my $module (
        map {$_->[1]}
        sort {$a->[0] cmp $b->[0]}
        map {[uc($_), $_]}
        grep {$_ =~ $filter_re}
        $inst->modules())
    {
        $self->{mw}->update();
        next if $module =~ /^Perl/;
        my $version = $inst->version($module) || '?';
        $hlist->add($i);
        $hlist->itemCreate($i, 0, -text => $module);
        $hlist->itemCreate($i, 1, -text => $version);
        $self->{mw}->update();
        $i++;
    }

    $self->{installed}{module_display_filter}->configure(qw/-state normal/);
    $self->_status('');
    return 1;
}


sub _display_installed_files {
    my $self = shift;

    my $modules = $self->{installed}{modules};
    my $files   = $self->{installed}{files};
    my @list = $modules->info('selection');
    my $mod_no = shift @list;

    my $modulename = $modules->itemCget($mod_no, 0, '-text');

    my $current_module = $self->{installed}{current_module};
    return if defined $current_module and $current_module eq $modulename;

    $self->_status('Populating files list');
    my $instl = $self->{installed}{extutils_installed}
                || ExtUtils::Installed->new();
    my @files = $instl->files($modulename);

    $files->delete('all');
    my $i = 0;
    foreach my $file (
        map {$_->[1]}
        sort {$a->[0] cmp $b->[0]}
        map {[uc($_), $_]}
        @files)
    {
        $files->add($i);
        $files->itemCreate($i, 0, -text => $file);
        $i++;
    }

    $self->{installed}{current_module} = $modulename;
    $self->_status('');
}

sub _uninstall_module_gui {
    my $self = shift;
    my $module = $self->{installed}{current_module};
    if (not defined $module or $module eq '') {
        return;
    }

    my $confirm = $self->{mw}->Dialog(
        -title => 'Really uninstall?',
        -text  => "Please confirm that you really wish to uninstall the '$module' module.",
        -default_button => 'Cancel',
        -buttons => ['Uninstall', 'Cancel'],
    );
    my $answer = $confirm->Show();
    
    if ($answer eq 'Uninstall') {
        $self->_uninstall_module($module);
        $self->_raise_installed();
    }
}

sub _uninstall_module {
    my $self = shift;
    my $module = shift;

    $self->_status("Uninstalling $module from the system...");

    my $instl = $self->{installed}{extutils_installed}
                || ExtUtils::Installed->new();
    my @files = $instl->files($module);

    # Remove all the files
    foreach my $file (@files) {
       unlink($file);
    }
    my $pf = $instl->packlist($module)->packlist_file();
    unlink($pf);
    foreach my $dir (sort($instl->directory_tree($module))) {
       if ($self->_is_empty_dir($dir)) {
          rmdir($dir);
       }
    }

    undef $instl;

    $self->_status('');

    return 1;
}

sub _is_empty_dir {
    my $self = shift;
    my $dir = shift;
    my $dh = IO::Dir->new($dir) || return(0);
    my @count = $dh->read();
    $dh->close();
    return(@count == 2 ? 1 : 0);
}

1;

__END__

=head1 NAME

PAR::Dist::InstallPPD::GUI::Installed - Implements the Installed tab

=head1 SYNOPSIS

  use PAR::Dist::InstallPPD::GUI;
  my $gui = PAR::Dist::InstallPPD::GUI->new();
  $gui->run();

=head1 DESCRIPTION

This module is B<for internal use only>.

=head1 SEE ALSO

L<PAR::Dist::InstallPPD::GUI>

PAR has a mailing list, <par@perl.org>, that you can write to; send an empty mail to <par-subscribe@perl.org> to join the list and participate in the discussion.

Please send bug reports to <bug-par-dist-installppd-gui@rt.cpan.org>.

The official PAR website may be of help, too: http://par.perl.org

For details on the I<Perl Package Manager>, please refer to ActiveState's
website at L<http://activestate.com>.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

