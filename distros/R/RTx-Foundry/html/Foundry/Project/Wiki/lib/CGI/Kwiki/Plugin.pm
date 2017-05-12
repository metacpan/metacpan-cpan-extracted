package CGI::Kwiki::Plugin;
use strict;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';
use CGI::Kwiki;
use Cwd 'abs_path';

attribute 'can_do';

sub new {
    my ($class, $driver) = @_;
    my $self = $class->SUPER::new($driver);
    $self->can_do({map { ($_, 1) } $self->methods});
    return $self;
}

sub load {
    my ($self, $plugin) = @_;
    my $plugin_module = -f "./plugins/$plugin.pm"
      ? "'" . abs_path . "/plugins/$plugin.pm'"
      : "CGI::Kwiki::Plugin::$plugin";
    my $class_name = "CGI::Kwiki::Plugin::$plugin";
    eval qq{ require $plugin_module };
    die "Can't find a plugin class for '$plugin':\n$@" if $@;
    $class_name->new($self->driver);
}

sub call {
    my ($self, $plugin, $method, @args) = @_;
    my $plugin_obj = $self->load($plugin);

    die "Can't call method '$method' for plugin '$plugin'"
      unless defined $plugin_obj->can_do->{$method};

    $plugin_obj->$method(@args);
}

sub call_packed {
    my ($self, $packed1, $packed2) = @_;
    my ($plugin, $method) = split /\./, $packed1;
    my @args = split /\s+/, $packed2;
    $self->call($plugin, $method, @args);
}

sub methods {
    ();
}

sub process {
    my ($self) = @_;
    my $class = ref $self;
    die "No method 'process' defined for '$class'"
      unless $class eq __PACKAGE__;
    my $plugin_name = $self->cgi->plugin_name;
    $self->load($plugin_name)->process;
}

1;

__END__

=head1 NAME 

CGI::Kwiki::Plugin - Plugin Base Class for CGI::Kwiki

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
