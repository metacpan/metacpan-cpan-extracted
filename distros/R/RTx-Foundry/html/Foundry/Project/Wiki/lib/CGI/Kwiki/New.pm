package CGI::Kwiki::New;
$VERSION = '0.18';
use strict;
use Config;
use File::Path;
use CGI::Kwiki qw(attribute);
use base 'CGI::Kwiki::Privacy';

attribute 'driver';
attribute 'options';

sub new {
    my ($class, @args) = @_;
    my $self;
    my ($subclass) = map { s/.*=// } grep { /^--type=/ } @args;
    if (defined $subclass) {
        my $full_subclass = "CGI::Kwiki::New::$subclass";
        eval qq{ require $full_subclass }; die $@ if $@;
        $self = $full_subclass->new(@args);
    }
    else {
        $self = bless {options => {}}, $class;
        for (@args) {
            next unless s/^--//;
            if (/^(.*?)=(.*)$/) {
                $self->options->{$1} = $2;
            }
            else {
                $self->options->{$_} = 1;
            }
        }
    }
    return $self;
}

sub help {
    print <<END;
usage: kwiki-install [options]

feature options:
  --privacy    - Turn on Public/Protected/Private page security.
  
upgrade options:
  --upgrade      - Upgrade everything. Merge config.
  --reinstall    - Upgrade everything including config file.
  --config       - Upgrade config file. You will lose local settings!
  --config_merge - Merge in new config file settings.
  --scripts      - Upgrade cgi scripts.
  --pages        - Upgrade default kwiki pages unless changed by a user.
  --template     - Upgrade templates.
  --javascript   - Upgrade javascript.
  --style        - Upgrade css stylesheets.

END
}

sub apply_options {
    my ($self) = @_;
    for my $option (sort keys %{$self->options}) {
        if ($self->can($option) and
            $option !~ /^(apply_options|install|create)$/
           ) {
            print "Applying $option\n";
            $self->$option;
        }
        else {
            warn "Invalid option '--$option' specified\n";
        }
    }
}

sub install {
    my ($self) = @_;
    $CGI::Kwiki::ADMIN = 1;
    $self->driver(CGI::Kwiki::load_driver());
    $CGI::Kwiki::user_name = 'kwiki-install';
    if ($self->options->{help}) {
        $self->help;
    }
    elsif (glob '*') {
        if (keys %{$self->options}) {
            $self->apply_options;
        }
        else {
            $self->install_error;
        }
    }
    else {
        $self->create;
    }
}

sub create {
    my ($self) = @_;
    $self->config;
    $self->basics;
    print "Kwiki software installed! Point your browser at this location.\n";
}

sub upgrade {
    my ($self) = @_;
    $self->config_merge && do {
        $self = __PACKAGE__->new(@ARGV);
        local $^W;
        $self->driver(CGI::Kwiki::load_driver());
    };
    $self->basics;
    print "Kwiki software upgraded!\n";
}

sub basics {
    my ($self) = @_;
    $self->locks;
    $self->scripts;
    $self->template;
    $self->javascript;
    $self->style;
    $self->pages;
}
    
sub reinstall {
    my ($self) = @_;
    $self->create;
}

sub locks {
    my ($self) = @_;
    $self->mkdir('metabase');
    $self->mkdir('metabase/lock');
}

sub scripts {
    my ($self) = @_;
    $self->driver->load_class('scripts');
    $self->driver->scripts->create_files;
}

sub config {
    my ($self) = @_;
    my $driver = $self->driver;
    $driver->load_class('config_yaml');
    $driver->load_class('template');
    $driver->config_yaml->driver($driver);
    $driver->config_yaml->create_files;
}

sub config_merge {
    my ($self) = @_;
    my $driver = $self->driver;
    $driver->load_class('config_yaml');
    $driver->load_class('template');
    $driver->config_yaml->driver($driver);
    $driver->config_yaml->merge_config;
}

sub pages {
    my ($self) = @_;
    $self->driver->load_class('metadata');
    $self->mkdir('metabase');
    $self->mkdir('metabase/metadata');
    $self->driver->load_class('pages');
    $self->driver->pages->create_files;
    foreach my $class ($self->driver->pages->subclasses) {
	my $page = $class->new($self->driver);
	$page->create_files;
    }
}

sub template {
    my ($self) = @_;
    $self->driver->load_class('template');
    $self->driver->template->create_files;
}

sub javascript {
    my ($self) = @_;
    $self->driver->load_class('javascript');
    $self->driver->javascript->create_files;
}

sub style {
    my ($self) = @_;
    $self->driver->load_class('style');
    $self->driver->style->create_files;
}

sub privacy {
    my ($self) = @_;
    $self->mkdir('metabase/public');
    $self->mkdir('metabase/private');
    $self->mkdir('metabase/protected');
    $self->mkdir('metabase/blog');
    opendir DATABASE, "database" or die $!;
    while (my $page_id = $self->unescape(scalar readdir(DATABASE))) {
        next if $page_id =~ /^\./;
        if ((not $self->is_public($page_id)) &&
            (not $self->is_protected($page_id)) &&
            (not $self->is_private($page_id))
           ) {
            $self->set_privacy('public', $page_id);
        }
    }
}

sub mkdir {
    my ($self, $dir) = @_;
    unless (-d $dir) {
        umask 0000;
        mkdir($dir, 0777);
    }
}

sub install_error {
    print <<END;
Can't install new kwiki in non-empty directory. If you are upgrading, try: 

    kwiki-install --upgrade

For more options try:

    kwiki-install --help

END
}

1;

__END__

=head1 NAME 

CGI::Kwiki::New - Default New Wiki Generator for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
