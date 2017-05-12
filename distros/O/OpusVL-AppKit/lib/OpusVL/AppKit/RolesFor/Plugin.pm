package OpusVL::AppKit::RolesFor::Plugin;

use Moose::Role;
use Carp;
use File::ShareDir qw/module_dir/;
use Try::Tiny;
use experimental 'smartmatch';

# this method is provided for compatibility reassons
# you should switch to using add_paths instead since it does this
# and sets up all the other paths too.
sub add_form_path
{
    my $self = shift;
    my $module = shift;

    carp "Please change the module $module to use add_paths instead of add_form_path.";
    my $module_dir = module_dir($module);
    $self->_add_form_path($module_dir);
}

sub add_paths
{
    my $self = shift;
    my $module = shift;

    # FIXME: should I do a rel2abs here?
    my $module_dir = try
    {
        module_dir($module);
    };
    if($module_dir)
    {
        $self->_add_form_path($module_dir);
        $self->_add_static_path($module_dir);
        $self->_add_template_path($module_dir);
    }
}

sub _add_form_path
{
    my $self = shift;
    my $module_dir = shift;

    $self->config->{'Controller::HTML::FormFu'} = { constructor => { config_file_path => [] }} if !$self->config->{'Controller::HTML::FormFu'};
    $self->config->{'Controller::HTML::FormFu'}->{constructor} = { config_file_path => [] } if !$self->config->{'Controller::HTML::FormFu'}->{constructor};
    $self->config->{'Controller::HTML::FormFu'}->{constructor}->{config_file_path} = [] if !$self->config->{'Controller::HTML::FormFu'}->{constructor}->{config_file_path};
    push @{$self->config->{'Controller::HTML::FormFu'}->{constructor}->{config_file_path}}, 
            $module_dir .  '/root/forms';
    # FIXME: by this point the various controller may be built.
}

sub _add_template_path
{
    my $self = shift;
    my $module_dir = shift;

    my $tt_view       = $self->config->{default_view} || 'TT';
    my $template_path = $module_dir . '/root/templates';

    if($self->view('Excel'))
    {
        unless ($self->view('Excel')->{etp_config}->{INCLUDE_PATH} ~~ $template_path) {
            push @{$self->view('Excel')->{etp_config}->{INCLUDE_PATH}}, $template_path;
        }
        $self->view('Excel')->{etp_config}->{AUTO_FILTER} = 'html';
        $self->view('Excel')->{etp_engine} = 'TTAutoFilter';
        unless ($self->view($tt_view)->include_path ~~ $template_path) {
            push @{$self->view($tt_view)->include_path}, $template_path;
        }
    }
    else
    {
        my $excel_config = $self->config->{'View::Excel'};
        unless ($excel_config->{etp_config}->{INCLUDE_PATH} ~~ $template_path) {
            push @{$excel_config->{etp_config}->{INCLUDE_PATH}}, $template_path;
        }
        $excel_config->{etp_config}->{AUTO_FILTER} = 'html';
        $excel_config->{etp_engine} = 'TTAutoFilter';
        my $inc_path = $self->config->{'View::AppKitTT'}->{'INCLUDE_PATH'};
        push(@$inc_path, $template_path );
    }

}

sub _add_static_path
{
    my $self = shift;
    my $module_dir = shift;

    # .. add static dir into the config for Static::Simple..
    my $static_dirs = $self->config->{'Plugin::Static::Simple'}->{include_path};
    unshift(@$static_dirs, File::Spec->rel2abs($module_dir . '/root' ));
    $self->config->{'Plugin::Static::Simple'}->{include_path} = $static_dirs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::RolesFor::Plugin

=head1 VERSION

version 2.29

=head1 SYNOPSIS

    with 'OpusVL::AppKit::RolesFor::Plugin';


    after 'setup_components' => sub {
        my $class = shift;

        $class->add_paths(__PACKAGE__);

=head1 DESCRIPTION

This role helps integrate your module into a catalyst app by adding to the paths setup so that the
auto directory contents are included in your app.  This includes, TT templates, HTML::FormFu forms,
static content and Excel::Template::Plus templates.

=head1 NAME

OpusVL::AppKit::RolesFor::Plugin

=head1 METHODS

=head2 add_paths

This sets up the paths for the TT templates and the L<Excel::Template::Plus> view.  Both views
are setup to point to the same directory, named C<templates>.  It also sets up the static content path
to point to the static directory.

It sets up the HTML::FormFu include directory so that it will pick up your forms.  The AppKitForm attribute
also has some logic to pull forms from the current module but that doesn't allow you to do includes on other forms,
either within your own module, or across modules.  

=head2 add_form_path

This sets up the HTML::FormFu include directory so that it will pick up your forms.  The AppKitForm attribute
also has some logic to pull forms from the current module but that doesn't allow you to do includes on other forms,
either within your own module, or across modules.  

This is called by the add_paths method.  The primary reason this method is exposed is that this was originaly 
the only method on this role.  Now I've added the add_paths method you should change any existing modules calling 
this method to use the add_paths call instead.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
