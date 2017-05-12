#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Config;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Config - Configuration file manager.

=head1 SYNOPSIS
    
    # get the app config object
    $config = $self->app->config;
    
    # get a new config object
    $config = $self->app->config->new;
    
    # keep sort order when reading and writing the xml file data. default is off.
    #$config->keep_order(1);

    # load config file from the configuration folder, file extension is xml.
    $config->load("config");

    # load and append another configuration file
    $config->add_file("admins");
    
    # get config variables
    say $config->get("admin/user");
    say $config->get("admin/password");
        
    # get config variable, if not found return the optional provided default value.
    $var = $config->get($name, $default);

    # automatic getter support
    say $config->email; # same as $config->get('email');

    # get a group of config variables.
    @list = $config->list(@names);

    # delete config variables from memory, changes will apply when saving file.
    $config->delete(@names);

    # set config variables.
    $config->set("admin", 'username');
    $config->set(%vars);

    # automatic setter support
    $config->email('ahmed@mewsoft.com'); # same as $config->set('email', 'ahmed@mewsoft.com');
    
    # save changes to file.
    $config->save();

    # write to another output file.
    $config->save($file);

=head1 DESCRIPTION

Nile::Config - Configuration file manager.

Configuration files are xml files stored in the application config folder. You can load and manage any number
of configuration files.

This class extends L<Nile::XML> class, therefore all methods from L<Nile::XML> is accessable to this object.

=cut

use Nile::Base;
extends 'Nile::XML';
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
around 'load' => sub {
    my ($orig, $self, $file) = @_;
    return $self->$orig($self->app->file->catfile($self->app->var->get("config_dir"), $file));
};
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
